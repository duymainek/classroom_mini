const { supabase } = require('../services/supabaseClient');
const { validate } = require('../utils/validators');
const { 
  createQuizSchema, 
  updateQuizSchema,
  createQuestionSchema,
  updateQuestionSchema,
  createQuizSubmissionSchema,
  gradeQuizSubmissionSchema
} = require('../schemas/quizSchema');
const {
  calculateQuizSubmissionStatus,
  formatQuizResponse,
  formatQuestionResponse,
  formatQuizSubmissionResponse
} = require('../models/quiz');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');
require('../types/quiz.type');

class QuizController {
  /**
   * Create new quiz
   */
  createQuiz = catchAsync(async (req, res) => {
    const {
      title,
      description,
      courseId,
      startDate,
      dueDate,
      lateDueDate,
      allowLateSubmission,
      maxAttempts,
      timeLimit,
      shuffleQuestions,
      shuffleOptions,
      showCorrectAnswers,
      groupIds
    } = req.body;

    const instructorId = req.user.id;

    // Validate input
    const validation = validate(createQuizSchema, req.body);

    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if course exists and instructor has access
    const { data: course } = await supabase
      .from('courses')
      .select('id, code, name')
      .eq('id', courseId)
      .eq('is_active', true)
      .single();

    if (!course) {
      return res.status(404).json({
        success: false,
        message: 'Course not found or inactive',
        code: 'COURSE_NOT_FOUND'
      });
    }

    // Validate groups exist and belong to course
    if (groupIds && groupIds.length > 0) {
      const { data: groups } = await supabase
        .from('groups')
        .select('id')
        .in('id', groupIds)
        .eq('course_id', courseId)
        .eq('is_active', true);

      if (!groups || groups.length !== groupIds.length) {
        return res.status(400).json({
          success: false,
          message: 'One or more groups not found or inactive',
          code: 'INVALID_GROUPS'
        });
      }
    }

    // Create quiz
    const { data: newQuiz, error: quizError } = await supabase
      .from('quizzes')
      .insert({
        title: title.trim(),
        description: description?.trim(),
        course_id: courseId,
        instructor_id: instructorId,
        start_date: startDate,
        due_date: dueDate,
        late_due_date: lateDueDate,
        allow_late_submission: allowLateSubmission || false,
        max_attempts: maxAttempts || 1,
        time_limit: timeLimit,
        shuffle_questions: shuffleQuestions || false,
        shuffle_options: shuffleOptions || false,
        show_correct_answers: showCorrectAnswers || false
      })
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, time_limit, shuffle_questions, shuffle_options,
        show_correct_answers, is_active, created_at, updated_at,
        courses!inner(code, name)
      `)
      .single();

    if (quizError) {
      console.error('Quiz creation error:', quizError);
      throw new AppError('Failed to create quiz', 500, 'QUIZ_CREATION_FAILED');
    }

    // Create quiz-group relationships
    if (groupIds && groupIds.length > 0) {
      const quizGroups = groupIds.map(groupId => ({
        quiz_id: newQuiz.id,
        group_id: groupId
      }));

      const { error: groupsError } = await supabase
        .from('quiz_groups')
        .insert(quizGroups);

      if (groupsError) {
        console.error('Quiz groups creation error:', groupsError);
        // Rollback quiz creation
        await supabase
          .from('quizzes')
          .delete()
          .eq('id', newQuiz.id);
        
        throw new AppError('Failed to assign groups to quiz', 500, 'GROUP_QUIZ_FAILED');
      }
    }

    // If questions are provided in request, create them now
    const { questions } = req.body || {};
    if (Array.isArray(questions) && questions.length > 0) {
      try {
        let autoOrder = 1;
        for (const q of questions) {
          const incomingType = (q.question_type || q.questionType || '').toLowerCase();
          const normalizedType = incomingType === 'text' ? 'essay' : incomingType; // map client 'text' -> 'essay'

          const orderIndex = Number.isInteger(q.order_index) ? q.order_index : (Number.isInteger(q.orderIndex) ? q.orderIndex : autoOrder);

          const { data: createdQuestion, error: createQErr } = await supabase
            .from('quiz_questions')
            .insert({
              quiz_id: newQuiz.id,
              question_text: q.question_text ?? q.questionText,
              question_type: normalizedType,
              points: q.points ?? 1,
              order_index: orderIndex > 0 ? orderIndex : autoOrder,
              is_required: q.is_required ?? q.isRequired ?? true
            })
            .select('id')
            .single();

          if (createQErr) {
            throw createQErr;
          }

          autoOrder = Math.max(autoOrder + 1, (orderIndex || autoOrder) + 1);

          // For multiple choice / true_false, create options if provided
          const rawOptions = q.options;
          if ((normalizedType === 'multiple_choice' || normalizedType === 'true_false') && Array.isArray(rawOptions) && rawOptions.length > 0) {
            // default order_index for options
            let optOrder = 1;
            const optionRows = rawOptions.map(opt => ({
              question_id: createdQuestion.id,
              option_text: opt.option_text ?? opt.optionText,
              is_correct: opt.is_correct ?? opt.isCorrect ?? false,
              order_index: Number.isInteger(opt.order_index) ? opt.order_index : (Number.isInteger(opt.orderIndex) ? opt.orderIndex : optOrder++)
            }));

            const { error: optErr } = await supabase
              .from('quiz_question_options')
              .insert(optionRows);

            if (optErr) {
              throw optErr;
            }
          }
        }
      } catch (e) {
        console.error('Quiz questions creation error:', e);
        // Best-effort rollback: delete created quiz (cascade will remove groups/questions/options)
        await supabase
          .from('quizzes')
          .delete()
          .eq('id', newQuiz.id);
        throw new AppError('Failed to create quiz questions', 500, 'QUIZ_QUESTIONS_CREATION_FAILED');
      }
    }

    // Get quiz with groups for response
    const { data: quizWithGroups } = await supabase
      .from('quizzes')
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, time_limit, shuffle_questions, shuffle_options,
        show_correct_answers, is_active, created_at, updated_at,
        courses!inner(code, name),
        quiz_groups(
          groups!inner(id, name)
        ),
        quiz_questions(
          id, quiz_id, question_text, question_type, points, order_index, is_required,
          quiz_question_options(id, question_id, option_text, is_correct, order_index)
        )
      `)
      .eq('id', newQuiz.id)
      .single();

    res.status(201).json(
      buildResponse(true, 'Quiz created successfully', { quiz: quizWithGroups })
    );
  });

  /**
   * Get quizzes with pagination, search, and filters
   */
  getQuizzes = catchAsync(async (req, res) => {
    const {
      page = 1,
      limit = 20,
      search = '',
      courseId = '',
      semesterId = '',
      status = 'all', // all, active, inactive, upcoming, past
      sortBy = 'created_at',
      sortOrder = 'desc'
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const userId = req.user.id;
    const userRole = req.user.role;

    // Build query based on user role
    let query = supabase
      .from('quizzes')
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, time_limit, shuffle_questions, shuffle_options,
        show_correct_answers, is_active, created_at, updated_at,
        courses!inner(code, name, semester_id),
        users!quizzes_instructor_id_fkey(full_name),
        quiz_groups(
          groups!inner(id, name)
        ),
        quiz_questions(id)
      `, { count: 'exact' });

    // Apply role-based filtering
    if (userRole === 'student') {
      // Students can only see quizzes assigned to their groups
      query = query
        .select(`
          id, title, description, course_id, instructor_id,
          start_date, due_date, late_due_date, allow_late_submission,
          max_attempts, time_limit, shuffle_questions, shuffle_options,
          show_correct_answers, is_active, created_at, updated_at,
          courses!inner(code, name),
          users!quizzes_instructor_id_fkey(full_name),
          quiz_groups!inner(
            groups!inner(
              student_enrollments!inner(student_id)
            )
          ),
          quiz_questions(id)
        `)
        .eq('quiz_groups.groups.student_enrollments.student_id', userId);
    } else {
      // Instructors can see all quizzes
      query = query.eq('instructor_id', userId);
    }

    // Apply search filter
    if (search.trim()) {
      query = query.or(`
        title.ilike.%${search}%,
        description.ilike.%${search}%,
        courses.code.ilike.%${search}%,
        courses.name.ilike.%${search}%
      `);
    }

    // Apply course filter
    if (courseId) {
      query = query.eq('course_id', courseId);
    }

    // Apply semester filter
    if (semesterId) {
      query = query.eq('courses.semester_id', semesterId);
    }

    // Apply status filter
    const now = new Date().toISOString();
    if (status === 'active') {
      query = query.eq('is_active', true);
    } else if (status === 'inactive') {
      query = query.eq('is_active', false);
    } else if (status === 'upcoming') {
      query = query.gte('start_date', now);
    } else if (status === 'past') {
      query = query.lt('due_date', now);
    }

    // Apply sorting
    query = query.order(sortBy, { ascending: sortOrder === 'asc' });

    // Apply pagination
    query = query.range(offset, offset + parseInt(limit) - 1);

    const { data: quizzes, error, count } = await query;

    if (error) {
      console.error('Get quizzes error:', error);
      throw new AppError('Failed to fetch quizzes', 500, 'GET_QUIZZES_FAILED');
    }

    // Attach question_count and remove quiz_questions to keep payload lean
    const quizzesWithCounts = (quizzes || []).map(q => {
      const questionCount = Array.isArray(q.quiz_questions) ? q.quiz_questions.length : 0;
      const { quiz_questions, ...rest } = q;
      return { ...rest, question_count: questionCount };
    });

    res.json(
      buildResponse(true, undefined, {
        quizzes: quizzesWithCounts,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count || 0,
          pages: Math.ceil((count || 0) / parseInt(limit))
        }
      })
    );
  });

  /**
   * Get quiz by ID with full details
   */
  getQuizById = catchAsync(async (req, res) => {
    const { quizId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Build query with role-based access
    let query = supabase
      .from('quizzes')
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, time_limit, shuffle_questions, shuffle_options,
        show_correct_answers, is_active, created_at, updated_at,
        courses!inner(code, name),
        users!quizzes_instructor_id_fkey(full_name),
        quiz_groups(
          groups!inner(id, name)
        ),
        quiz_questions(
          id, question_text, question_type, points, order_index, is_required,
          quiz_question_options(
            id, option_text, is_correct, order_index
          )
        )
      `)
      .eq('id', quizId);

    // Apply role-based filtering
    if (userRole === 'student') {
      query = query
        .select(`
          id, title, description, course_id, instructor_id,
          start_date, due_date, late_due_date, allow_late_submission,
          max_attempts, time_limit, shuffle_questions, shuffle_options,
          show_correct_answers, is_active, created_at, updated_at,
          courses!inner(code, name),
          users!quizzes_instructor_id_fkey(full_name),
          quiz_groups!inner(
            groups!inner(
              student_enrollments!inner(student_id)
            )
          ),
          quiz_questions(
            id, question_text, question_type, points, order_index, is_required,
            quiz_question_options(
              id, option_text, is_correct, order_index
            )
          )
        `)
        .eq('quiz_groups.groups.student_enrollments.student_id', userId);
    } else {
      query = query.eq('instructor_id', userId);
    }

    const { data: quiz, error } = await query.single();

    if (error || !quiz) {
      throw new AppError('Quiz not found', 404, 'QUIZ_NOT_FOUND');
    }

    res.json(buildResponse(true, undefined, { quiz }));
  });

  /**
   * Update quiz
   */
  updateQuiz = catchAsync(async (req, res) => {
    const { quizId } = req.params;
    const instructorId = req.user.id;
    const updateData = req.body;

    // Validate input
    const validation = validate(updateQuizSchema, updateData);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if quiz exists and belongs to instructor
    const { data: existingQuiz } = await supabase
      .from('quizzes')
      .select('id, instructor_id')
      .eq('id', quizId)
      .eq('instructor_id', instructorId)
      .single();

    if (!existingQuiz) {
      throw new AppError('Quiz not found or access denied', 404, 'QUIZ_NOT_FOUND');
    }

    // Update quiz core fields (map camelCase -> snake_case, exclude questions)
    const updatePayload = {};
    if (Object.prototype.hasOwnProperty.call(updateData, 'title')) updatePayload.title = updateData.title;
    if (Object.prototype.hasOwnProperty.call(updateData, 'description')) updatePayload.description = updateData.description;
    if (Object.prototype.hasOwnProperty.call(updateData, 'startDate')) updatePayload.start_date = updateData.startDate;
    if (Object.prototype.hasOwnProperty.call(updateData, 'dueDate')) updatePayload.due_date = updateData.dueDate;
    if (Object.prototype.hasOwnProperty.call(updateData, 'lateDueDate')) updatePayload.late_due_date = updateData.lateDueDate;
    if (Object.prototype.hasOwnProperty.call(updateData, 'allowLateSubmission')) updatePayload.allow_late_submission = updateData.allowLateSubmission;
    if (Object.prototype.hasOwnProperty.call(updateData, 'maxAttempts')) updatePayload.max_attempts = updateData.maxAttempts;
    if (Object.prototype.hasOwnProperty.call(updateData, 'timeLimit')) updatePayload.time_limit = updateData.timeLimit;
    if (Object.prototype.hasOwnProperty.call(updateData, 'shuffleQuestions')) updatePayload.shuffle_questions = updateData.shuffleQuestions;
    if (Object.prototype.hasOwnProperty.call(updateData, 'shuffleOptions')) updatePayload.shuffle_options = updateData.shuffleOptions;
    if (Object.prototype.hasOwnProperty.call(updateData, 'showCorrectAnswers')) updatePayload.show_correct_answers = updateData.showCorrectAnswers;
    if (Object.prototype.hasOwnProperty.call(updateData, 'isActive')) updatePayload.is_active = updateData.isActive;

    updatePayload.updated_at = new Date().toISOString();

    const { data: updatedQuiz, error } = await supabase
      .from('quizzes')
      .update(updatePayload)
      .eq('id', quizId)
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, time_limit, shuffle_questions, shuffle_options,
        show_correct_answers, is_active, created_at, updated_at,
        courses!inner(code, name)
      `)
      .single();

    if (error) {
      console.error('Update quiz error:', error);
      throw new AppError('Failed to update quiz', 500, 'UPDATE_QUIZ_FAILED');
    }

    // If questions array is provided, perform sync (create/update/delete)
    const { questions } = updateData || {};
    if (Array.isArray(questions)) {
      try {
        // 1) Load existing question ids
        const { data: existingQs, error: loadQsErr } = await supabase
          .from('quiz_questions')
          .select('id')
          .eq('quiz_id', quizId);
        if (loadQsErr) throw loadQsErr;

        const existingIds = new Set((existingQs || []).map(q => q.id));
        const incomingIds = new Set(
          questions
            .map(q => q.id)
            .filter(Boolean)
        );

        // 2) Delete questions not present anymore
        const idsToDelete = [...existingIds].filter(id => !incomingIds.has(id));
        if (idsToDelete.length > 0) {
          const { error: delErr } = await supabase
            .from('quiz_questions')
            .delete()
            .in('id', idsToDelete);
          if (delErr) throw delErr;
        }

        // 3) Upsert incoming questions
        let autoOrder = 1;
        for (const q of questions) {
          const incomingType = (q.question_type || q.questionType || '').toLowerCase();
          const normalizedType = incomingType === 'text' ? 'essay' : incomingType;
          const orderIndex = Number.isInteger(q.order_index)
            ? q.order_index
            : (Number.isInteger(q.orderIndex) ? q.orderIndex : autoOrder);

          let targetQuestionId = q.id;
          if (targetQuestionId && existingIds.has(targetQuestionId)) {
            // Update
            const { error: upErr } = await supabase
              .from('quiz_questions')
              .update({
                question_text: q.question_text ?? q.questionText,
                question_type: normalizedType,
                points: q.points ?? 1,
                order_index: orderIndex > 0 ? orderIndex : autoOrder,
                is_required: q.is_required ?? q.isRequired ?? true,
                updated_at: new Date().toISOString()
              })
              .eq('id', targetQuestionId);
            if (upErr) throw upErr;
          } else {
            // Create
            const { data: createdQ, error: crtErr } = await supabase
              .from('quiz_questions')
              .insert({
                quiz_id: quizId,
                question_text: q.question_text ?? q.questionText,
                question_type: normalizedType,
                points: q.points ?? 1,
                order_index: orderIndex > 0 ? orderIndex : autoOrder,
                is_required: q.is_required ?? q.isRequired ?? true
              })
              .select('id')
              .single();
            if (crtErr) throw crtErr;
            targetQuestionId = createdQ.id;
          }

          autoOrder = Math.max(autoOrder + 1, (orderIndex || autoOrder) + 1);

          // Options handling for MC/TF
          const rawOptions = q.options;
          if ((normalizedType === 'multiple_choice' || normalizedType === 'true_false')) {
            // Clear old options then insert new if provided
            const { error: delOptErr } = await supabase
              .from('quiz_question_options')
              .delete()
              .eq('question_id', targetQuestionId);
            if (delOptErr) throw delOptErr;

            if (Array.isArray(rawOptions) && rawOptions.length > 0) {
              let optOrder = 1;
              const optionRows = rawOptions.map(opt => ({
                question_id: targetQuestionId,
                option_text: opt.option_text ?? opt.optionText,
                is_correct: opt.is_correct ?? opt.isCorrect ?? false,
                order_index: Number.isInteger(opt.order_index)
                  ? opt.order_index
                  : (Number.isInteger(opt.orderIndex) ? opt.orderIndex : optOrder++)
              }));
              const { error: insOptErr } = await supabase
                .from('quiz_question_options')
                .insert(optionRows);
              if (insOptErr) throw insOptErr;
            }
          }
        }
      } catch (e) {
        console.error('Update quiz questions error:', e);
        throw new AppError('Failed to update quiz questions', 500, 'UPDATE_QUIZ_QUESTIONS_FAILED');
      }
    }

    res.json(
      buildResponse(true, 'Quiz updated successfully', { quiz: updatedQuiz })
    );
  });

  /**
   * Delete quiz
   */
  deleteQuiz = catchAsync(async (req, res) => {
    const { quizId } = req.params;
    const instructorId = req.user.id;

    // Check if quiz exists and belongs to instructor
    const { data: existingQuiz } = await supabase
      .from('quizzes')
      .select('id, instructor_id')
      .eq('id', quizId)
      .eq('instructor_id', instructorId)
      .single();

    if (!existingQuiz) {
      throw new AppError('Quiz not found or access denied', 404, 'QUIZ_NOT_FOUND');
    }

    // Check if quiz has submissions
    const { data: submissions } = await supabase
      .from('quiz_submissions')
      .select('id')
      .eq('quiz_id', quizId)
      .limit(1);

    if (submissions && submissions.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete quiz with existing submissions',
        code: 'QUIZ_HAS_SUBMISSIONS'
      });
    }

    // Delete quiz (cascade will handle related records)
    const { error } = await supabase
      .from('quizzes')
      .delete()
      .eq('id', quizId);

    if (error) {
      console.error('Delete quiz error:', error);
      throw new AppError('Failed to delete quiz', 500, 'DELETE_QUIZ_FAILED');
    }

    res.json(buildResponse(true, 'Quiz deleted successfully'));
  });

  /**
   * Add question to quiz
   */
  addQuestion = catchAsync(async (req, res) => {
    const { quizId } = req.params;
    const instructorId = req.user.id;
    const questionData = req.body;

    // Validate input
    const validation = validate(createQuestionSchema, questionData);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if quiz exists and belongs to instructor
    const { data: quiz } = await supabase
      .from('quizzes')
      .select('id, instructor_id')
      .eq('id', quizId)
      .eq('instructor_id', instructorId)
      .single();

    if (!quiz) {
      throw new AppError('Quiz not found or access denied', 404, 'QUIZ_NOT_FOUND');
    }

    // Create question
    const { data: newQuestion, error: questionError } = await supabase
      .from('quiz_questions')
      .insert({
        quiz_id: quizId,
        question_text: questionData.questionText,
        question_type: questionData.questionType,
        points: questionData.points || 1,
        order_index: questionData.orderIndex,
        is_required: questionData.isRequired !== false
      })
      .select('*')
      .single();

    if (questionError) {
      console.error('Question creation error:', questionError);
      throw new AppError('Failed to create question', 500, 'QUESTION_CREATION_FAILED');
    }

    // Create options for multiple choice questions
    if (questionData.questionType === 'multiple_choice' && questionData.options) {
      const options = questionData.options.map(option => ({
        question_id: newQuestion.id,
        option_text: option.optionText,
        is_correct: option.isCorrect || false,
        order_index: option.orderIndex
      }));

      const { error: optionsError } = await supabase
        .from('quiz_question_options')
        .insert(options);

      if (optionsError) {
        console.error('Options creation error:', optionsError);
        // Rollback question creation
        await supabase
          .from('quiz_questions')
          .delete()
          .eq('id', newQuestion.id);
        
        throw new AppError('Failed to create question options', 500, 'OPTIONS_CREATION_FAILED');
      }
    }

    // Get question with options
    const { data: questionWithOptions } = await supabase
      .from('quiz_questions')
      .select(`
        *,
        quiz_question_options(
          id, question_id, option_text, is_correct, order_index
        )
      `)
      .eq('id', newQuestion.id)
      .single();

    res.status(201).json(
      buildResponse(true, 'Question added successfully', { question: questionWithOptions })
    );
  });

  /**
   * Update question
   */
  updateQuestion = catchAsync(async (req, res) => {
    const { quizId, questionId } = req.params;
    const instructorId = req.user.id;
    const updateData = req.body;

    // Validate input
    const validation = validate(updateQuestionSchema, updateData);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if quiz and question exist and belong to instructor
    const { data: question } = await supabase
      .from('quiz_questions')
      .select(`
        id,
        quizzes!inner(id, instructor_id)
      `)
      .eq('id', questionId)
      .eq('quiz_id', quizId)
      .eq('quizzes.instructor_id', instructorId)
      .single();

    if (!question) {
      throw new AppError('Question not found or access denied', 404, 'QUESTION_NOT_FOUND');
    }

    // Update question
    const { error } = await supabase
      .from('quiz_questions')
      .update({
        question_text: updateData.questionText,
        question_type: updateData.questionType,
        points: updateData.points,
        order_index: updateData.orderIndex,
        is_required: updateData.isRequired,
        updated_at: new Date().toISOString()
      })
      .eq('id', questionId);

    if (error) {
      console.error('Update question error:', error);
      throw new AppError('Failed to update question', 500, 'UPDATE_QUESTION_FAILED');
    }

    // Update options if provided
    if (updateData.options && updateData.questionType === 'multiple_choice') {
      // Delete existing options
      await supabase
        .from('quiz_question_options')
        .delete()
        .eq('question_id', questionId);

      // Create new options
      const options = updateData.options.map(option => ({
        question_id: questionId,
        option_text: option.optionText,
        is_correct: option.isCorrect || false,
        order_index: option.orderIndex
      }));

      const { error: optionsError } = await supabase
        .from('quiz_question_options')
        .insert(options);

      if (optionsError) {
        console.error('Options update error:', optionsError);
        throw new AppError('Failed to update question options', 500, 'OPTIONS_UPDATE_FAILED');
      }
    }

    // Get question with options
    const { data: questionWithOptions } = await supabase
      .from('quiz_questions')
      .select(`
        *,
        quiz_question_options(
          id, question_id, option_text, is_correct, order_index
        )
      `)
      .eq('id', questionId)
      .single();

    res.json(
      buildResponse(true, 'Question updated successfully', { question: questionWithOptions })
    );
  });

  /**
   * Delete question
   */
  deleteQuestion = catchAsync(async (req, res) => {
    const { quizId, questionId } = req.params;
    const instructorId = req.user.id;

    // Check if quiz and question exist and belong to instructor
    const { data: question } = await supabase
      .from('quiz_questions')
      .select(`
        id,
        quizzes!inner(id, instructor_id)
      `)
      .eq('id', questionId)
      .eq('quiz_id', quizId)
      .eq('quizzes.instructor_id', instructorId)
      .single();

    if (!question) {
      throw new AppError('Question not found or access denied', 404, 'QUESTION_NOT_FOUND');
    }

    // Delete question (cascade will handle options)
    const { error } = await supabase
      .from('quiz_questions')
      .delete()
      .eq('id', questionId);

    if (error) {
      console.error('Delete question error:', error);
      throw new AppError('Failed to delete question', 500, 'DELETE_QUESTION_FAILED');
    }

    res.json(buildResponse(true, 'Question deleted successfully'));
  });

  /**
   * Submit quiz answers
   */
  submitQuiz = catchAsync(async (req, res) => {
    const { quizId } = req.params;
    const studentId = req.user.id;
    const { answers } = req.body;

    // Validate input
    const validation = validate(createQuizSubmissionSchema, { quizId, answers });
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if quiz exists and is accessible to student
    const { data: quiz } = await supabase
      .from('quizzes')
      .select(`
        id, due_date, late_due_date, allow_late_submission, max_attempts,
        quiz_groups!inner(
          groups!inner(
            student_enrollments!inner(student_id)
          )
        )
      `)
      .eq('id', quizId)
      .eq('quiz_groups.groups.student_enrollments.student_id', studentId)
      .single();

    if (!quiz) {
      throw new AppError('Quiz not found or access denied', 404, 'QUIZ_NOT_FOUND');
    }

    // Check if quiz is still open
    const now = new Date();
    const dueDate = new Date(quiz.due_date);
    const lateDueDate = quiz.late_due_date ? new Date(quiz.late_due_date) : null;

    if (now > dueDate && (!quiz.allow_late_submission || !lateDueDate || now > lateDueDate)) {
      return res.status(400).json({
        success: false,
        message: 'Quiz submission deadline has passed',
        code: 'QUIZ_CLOSED'
      });
    }

    // Check attempt limit
    const { data: existingSubmissions } = await supabase
      .from('quiz_submissions')
      .select('attempt_number')
      .eq('quiz_id', quizId)
      .eq('student_id', studentId)
      .order('attempt_number', { ascending: false });

    const currentAttempt = existingSubmissions.length + 1;
    if (currentAttempt > quiz.max_attempts) {
      return res.status(400).json({
        success: false,
        message: 'Maximum attempts exceeded',
        code: 'MAX_ATTEMPTS_EXCEEDED'
      });
    }

    // Calculate submission status
    const isLate = now > dueDate;
    const submissionStatus = calculateQuizSubmissionStatus(now, dueDate, lateDueDate, quiz.allow_late_submission);

    // Create submission
    const { data: newSubmission, error: submissionError } = await supabase
      .from('quiz_submissions')
      .insert({
        quiz_id: quizId,
        student_id: studentId,
        attempt_number: currentAttempt,
        submitted_at: now.toISOString(),
        is_late: isLate
      })
      .select('id')
      .single();

    if (submissionError) {
      console.error('Submission creation error:', submissionError);
      throw new AppError('Failed to create submission', 500, 'SUBMISSION_CREATION_FAILED');
    }

    // Create answers
    const answerRecords = answers.map(answer => ({
      submission_id: newSubmission.id,
      question_id: answer.questionId,
      answer_text: answer.answerText,
      selected_option_id: answer.selectedOptionId
    }));

    const { error: answersError } = await supabase
      .from('quiz_answers')
      .insert(answerRecords);

    if (answersError) {
      console.error('Answers creation error:', answersError);
      // Rollback submission
      await supabase
        .from('quiz_submissions')
        .delete()
        .eq('id', newSubmission.id);
      
      throw new AppError('Failed to save answers', 500, 'ANSWERS_SAVE_FAILED');
    }

    res.status(201).json(
      buildResponse(true, 'Quiz submitted successfully', {
        submissionId: newSubmission.id,
        attemptNumber: currentAttempt,
        isLate,
        status: submissionStatus
      })
    );
  });

  /**
   * Get quiz submissions for instructor
   */
  getQuizSubmissions = catchAsync(async (req, res) => {
    const { quizId } = req.params;
    const {
      page = 1,
      limit = 20,
      search = '',
      status = 'all', // all, submitted, not_submitted, late
      sortBy = 'submitted_at',
      sortOrder = 'desc'
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const instructorId = req.user.id;

    // Verify quiz belongs to instructor
    const { data: quiz } = await supabase
      .from('quizzes')
      .select('id, title, due_date, late_due_date')
      .eq('id', quizId)
      .eq('instructor_id', instructorId)
      .single();

    if (!quiz) {
      throw new AppError('Quiz not found or access denied', 404, 'QUIZ_NOT_FOUND');
    }

    // Get all students in quiz groups
    const { data: students } = await supabase
      .from('quiz_groups')
      .select(`
        groups!inner(
          student_enrollments!inner(
            users!inner(id, username, full_name, email)
          )
        )
      `)
      .eq('quiz_id', quizId);

    if (!students || students.length === 0) {
      return res.json({
        success: true,
        data: {
          submissions: [],
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total: 0,
            pages: 0
          }
        }
      });
    }

    // Flatten students data
    const allStudents = students.flatMap(qg => 
      qg.groups.student_enrollments.map(se => se.users)
    );

    // Get submissions for these students
    const { data: submissions } = await supabase
      .from('quiz_submissions')
      .select(`
        id, student_id, attempt_number, submitted_at, is_late, 
        total_score, max_score, is_graded, grade, feedback, graded_at,
        users!inner(id, username, full_name, email)
      `)
      .eq('quiz_id', quizId)
      .in('student_id', allStudents.map(s => s.id));

    // Create tracking data
    const trackingData = allStudents.map(student => {
      const studentSubmissions = submissions?.filter(sub => sub.student_id === student.id) || [];
      const latestSubmission = studentSubmissions.length > 0 
        ? studentSubmissions.toSorted((a, b) => new Date(b.submitted_at) - new Date(a.submitted_at))[0]
        : null;

      return {
        studentId: student.id,
        username: student.username,
        fullName: student.full_name,
        email: student.email,
        totalSubmissions: studentSubmissions.length,
        latestSubmission: latestSubmission ? {
          id: latestSubmission.id,
          attemptNumber: latestSubmission.attempt_number,
          submittedAt: latestSubmission.submitted_at,
          isLate: latestSubmission.is_late,
          totalScore: latestSubmission.total_score,
          maxScore: latestSubmission.max_score,
          isGraded: latestSubmission.is_graded,
          grade: latestSubmission.grade,
          feedback: latestSubmission.feedback,
          gradedAt: latestSubmission.graded_at
        } : null,
        status: (() => {
          if (!latestSubmission) return 'not_submitted';
          return latestSubmission.is_late ? 'late' : 'submitted';
        })()
      };
    });

    // Apply filters
    let filteredData = trackingData;

    if (search.trim()) {
      filteredData = filteredData.filter(item => 
        item.fullName.toLowerCase().includes(search.toLowerCase()) ||
        item.username.toLowerCase().includes(search.toLowerCase()) ||
        item.email.toLowerCase().includes(search.toLowerCase())
      );
    }

    if (status !== 'all') {
      filteredData = filteredData.filter(item => item.status === status);
    }

    // Apply sorting
    filteredData.sort((a, b) => {
      const aValue = a[sortBy] || '';
      const bValue = b[sortBy] || '';
      
      if (sortOrder === 'asc') {
        return aValue > bValue ? 1 : -1;
      } else {
        return aValue < bValue ? 1 : -1;
      }
    });

    // Apply pagination
    const total = filteredData.length;
    const paginatedData = filteredData.slice(offset, offset + parseInt(limit));

    res.json(
      buildResponse(true, undefined, {
        submissions: paginatedData,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      })
    );
  });

  /**
   * Grade quiz submission
   */
  gradeQuizSubmission = catchAsync(async (req, res) => {
    const { submissionId } = req.params;
    const { grade, feedback } = req.body;
    const instructorId = req.user.id;

    // Validate grade
    const validation = validate(gradeQuizSubmissionSchema, { grade, feedback });
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if submission exists and instructor has access
    const { data: submission } = await supabase
      .from('quiz_submissions')
      .select(`
        id, quiz_id,
        quizzes!inner(instructor_id)
      `)
      .eq('id', submissionId)
      .eq('quizzes.instructor_id', instructorId)
      .single();

    if (!submission) {
      throw new AppError('Submission not found or access denied', 404, 'SUBMISSION_NOT_FOUND');
    }

    // Update submission with grade
    const { data: updatedSubmission, error } = await supabase
      .from('quiz_submissions')
      .update({
        grade,
        feedback,
        graded_at: new Date().toISOString(),
        graded_by: instructorId,
        is_graded: true,
        updated_at: new Date().toISOString()
      })
      .eq('id', submissionId)
      .select(`
        id, grade, feedback, graded_at, graded_by, is_graded,
        users!inner(full_name)
      `)
      .single();

    if (error) {
      console.error('Grade submission error:', error);
      throw new AppError('Failed to grade submission', 500, 'GRADE_SUBMISSION_FAILED');
    }

    res.json(
      buildResponse(true, 'Submission graded successfully', { submission: updatedSubmission })
    );
  });
}

module.exports = new QuizController();
