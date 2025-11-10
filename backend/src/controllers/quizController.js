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
  formatQuizSubmissionResponse,
  formatQuizGroups
} = require('../models/quiz');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');
const notificationController = require('./notificationController');
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

    // Format quiz response with proper field names
    const formattedQuiz = {
      ...formatQuizResponse(quizWithGroups),
      quizGroups: formatQuizGroups(quizWithGroups.quiz_groups || []),
      questions: (quizWithGroups.quiz_questions || []).map(q => ({
        id: q.id,
        quizId: q.quiz_id,
        questionText: q.question_text,
        questionType: q.question_type,
        points: q.points,
        orderIndex: q.order_index,
        isRequired: q.is_required,
        createdAt: q.created_at,
        updatedAt: q.updated_at,
        quiz_question_options: q.quiz_question_options || []
      })),
      course: quizWithGroups.courses,
      instructor: quizWithGroups.users || null
    };

    res.status(201).json(
      buildResponse(true, 'Quiz created successfully', { quiz: formattedQuiz })
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
      sortOrder = 'desc',
      includeQuestions = 'false' // Optional: include full questions data
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const userId = req.user.id;
    const userRole = req.user.role;

    // Determine if we should include full questions data
    const shouldIncludeQuestions = includeQuestions === 'true' || includeQuestions === true;
    
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
        ${shouldIncludeQuestions 
          ? `quiz_questions(
            id, quiz_id, question_text, question_type, points, order_index, is_required,
            quiz_question_options(id, question_id, option_text, is_correct, order_index)
          )`
          : 'quiz_questions(id)'}
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
            id, quiz_id, group_id,
            groups!inner(
              id, name,
              student_enrollments!inner(student_id)
            )
          ),
          ${shouldIncludeQuestions 
            ? `quiz_questions(
              id, quiz_id, question_text, question_type, points, order_index, is_required,
              quiz_question_options(id, question_id, option_text, is_correct, order_index)
            )`
            : 'quiz_questions(id)'}
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

    // Format quizzes: attach question_count and optionally include questions
    const quizzesWithCounts = (quizzes || []).map(q => {
      const questionCount = Array.isArray(q.quiz_questions) ? q.quiz_questions.length : 0;
      const { quiz_questions, quiz_groups, ...rest } = q;
      
      const formattedQuiz = { 
        ...rest, 
        question_count: questionCount,
        quizGroups: formatQuizGroups(quiz_groups || [])
      };
      
      // Include full questions if requested
      if (shouldIncludeQuestions && quiz_questions && quiz_questions.length > 0) {
        formattedQuiz.questions = quiz_questions.map(q => ({
          id: q.id,
          quizId: q.quiz_id,
          questionText: q.question_text,
          questionType: q.question_type,
          points: q.points,
          orderIndex: q.order_index,
          isRequired: q.is_required,
          createdAt: q.created_at,
          updatedAt: q.updated_at,
          quiz_question_options: q.quiz_question_options || []
        }));
      }
      
      return formattedQuiz;
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
            id, quiz_id, group_id,
            groups!inner(
              id, name,
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

    // Format quiz response with proper field names
    const formattedQuiz = {
      ...formatQuizResponse(quiz),
      quizGroups: formatQuizGroups(quiz.quiz_groups || []),
      questions: (quiz.quiz_questions || []).map(q => ({
        id: q.id,
        quizId: q.quiz_id,
        questionText: q.question_text,
        questionType: q.question_type,
        points: q.points,
        orderIndex: q.order_index,
        isRequired: q.is_required,
        createdAt: q.created_at,
        updatedAt: q.updated_at,
        options: (q.quiz_question_options || []).map(opt => ({
          id: opt.id,
          questionId: opt.question_id,
          optionText: opt.option_text,
          isCorrect: opt.is_correct,
          orderIndex: opt.order_index
        }))
      })),
      course: quiz.courses,
      instructor: quiz.users
    };

    res.json(buildResponse(true, undefined, { quiz: formattedQuiz }));
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

    // Check if quiz exists and is accessible to student
    const { data: quiz } = await supabase
      .from('quizzes')
      .select(`
        id, title, instructor_id, due_date, late_due_date, allow_late_submission, max_attempts,
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

    // Auto-grade answers
    // Get all questions with their correct answers
    const { data: questions } = await supabase
      .from('quiz_questions')
      .select(`
        id,
        question_type,
        points,
        quiz_question_options (
          id,
          is_correct
        )
      `)
      .eq('quiz_id', quizId);

    let totalScore = 0;
    let maxScore = 0;
    let hasEssayQuestion = false;

    // Get all answer records for this submission to map question_id to answer_id
    const { data: savedAnswerRecords } = await supabase
      .from('quiz_answers')
      .select('id, question_id')
      .eq('submission_id', newSubmission.id);

    // Create a map of question_id to answer_id
    const questionToAnswerMap = {};
    if (savedAnswerRecords) {
      savedAnswerRecords.forEach(record => {
        questionToAnswerMap[record.question_id] = record.id;
      });
    }

    // Calculate scores and update answers with is_correct and points_earned
    const answerUpdates = [];
    for (const question of questions) {
      maxScore += question.points;
      const studentAnswer = answers.find(a => a.questionId === question.id);

      if (!studentAnswer) continue;

      if (question.question_type === 'multiple_choice' || question.question_type === 'true_false') {
        // Auto-grade multiple choice and true/false
        const correctOption = question.quiz_question_options?.find(opt => opt.is_correct);
        const isCorrect = correctOption && studentAnswer.selectedOptionId === correctOption.id;
        const pointsEarned = isCorrect ? question.points : 0;
        
        if (isCorrect) {
          totalScore += question.points;
        }

        // Get answer record ID from map
        const answerId = questionToAnswerMap[question.id];
        if (answerId) {
          answerUpdates.push({
            id: answerId,
            is_correct: isCorrect,
            points_earned: pointsEarned
          });
        }
      } else if (question.question_type === 'essay') {
        // Essay questions need manual grading
        hasEssayQuestion = true;
      }
    }

    // Update answers with is_correct and points_earned
    if (answerUpdates.length > 0) {
      for (const update of answerUpdates) {
        await supabase
          .from('quiz_answers')
          .update({
            is_correct: update.is_correct,
            points_earned: update.points_earned
          })
          .eq('id', update.id);
      }
    }

    // Update submission with scores
    await supabase
      .from('quiz_submissions')
      .update({
        total_score: totalScore,
        max_score: maxScore,
        is_graded: !hasEssayQuestion // Only fully graded if no essay questions
      })
      .eq('id', newSubmission.id);

    // Get student info for notification
    const { data: studentInfo, error: studentInfoError } = await supabase
      .from('users')
      .select('full_name')
      .eq('id', studentId)
      .single();

    // Create notification for instructor
    if (quiz.instructor_id && studentInfo) {
      try {
        console.log('[Quiz Submission] Creating notification for instructor:', quiz.instructor_id);
        const result = await notificationController.createNotification(quiz.instructor_id, {
          type: 'quiz_submission',
          title: 'New Quiz Submission',
          body: `${studentInfo.full_name} has submitted "${quiz.title}" (Attempt #${currentAttempt})`,
          data: {
            quizId: quizId,
            quizTitle: quiz.title,
            submissionId: newSubmission.id,
            studentId: studentId,
            studentName: studentInfo.full_name,
            attemptNumber: currentAttempt,
            isLate: isLate,
            hasEssayQuestion: hasEssayQuestion,
            needsGrading: hasEssayQuestion,
            action_url: `/student/quizzes/${quizId}/submissions/${newSubmission.id}`
          }
        });
        console.log('[Quiz Submission] Notification creation result:', result);
      } catch (notificationError) {
        console.error('[Quiz Submission] Error creating notification:', notificationError);
        console.error('[Quiz Submission] Error stack:', notificationError.stack);
      }
    } else {
      if (!quiz.instructor_id) {
        console.error('[Quiz Submission] Quiz has no instructor_id:', quiz);
      }
      if (!studentInfo) {
        console.error('[Quiz Submission] Student info not found:', studentInfoError);
      }
    }

    res.status(201).json(
      buildResponse(true, 'Quiz submitted successfully', {
        submissionId: newSubmission.id,
        attemptNumber: currentAttempt,
        isLate,
        status: submissionStatus,
        totalScore,
        maxScore
      })
    );
  });

  /**
   * Get quiz submission by ID with full details
   * Accessible by: Instructor (owns the quiz) or Student (owns the submission)
   */
  getQuizSubmissionById = catchAsync(async (req, res) => {
    const { submissionId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Get submission with all related data
    const { data: submission, error } = await supabase
      .from('quiz_submissions')
      .select(`
        id,
        quiz_id,
        student_id,
        attempt_number,
        submitted_at,
        is_late,
        total_score,
        max_score,
        is_graded,
        grade,
        feedback,
        quizzes!inner (
          id,
          title,
          instructor_id
        ),
        users!quiz_submissions_student_id_fkey (
          id,
          full_name,
          email
        )
      `)
      .eq('id', submissionId)
      .single();

    if (error || !submission) {
      throw new AppError('Submission not found', 404, 'SUBMISSION_NOT_FOUND');
    }

    // Verify access: Instructor must own the quiz, Student must own the submission
    if (userRole === 'instructor') {
      if (submission.quizzes.instructor_id !== userId) {
        throw new AppError('Access denied', 403, 'ACCESS_DENIED');
      }
    } else if (userRole === 'student') {
      if (submission.student_id !== userId) {
        throw new AppError('Access denied', 403, 'ACCESS_DENIED');
      }
    } else {
      throw new AppError('Access denied', 403, 'ACCESS_DENIED');
    }

    // Get all answers with question details
    const { data: answers } = await supabase
      .from('quiz_answers')
      .select(`
        id,
        question_id,
        answer_text,
        selected_option_id,
        review_status,
        manual_score,
        points_earned,
        is_correct,
        quiz_questions!inner (
          id,
          question_text,
          question_type,
          points,
          quiz_question_options (
            id,
            option_text,
            is_correct
          )
        )
      `)
      .eq('submission_id', submissionId);

    // Calculate correctness and scores for each answer
    const answersWithDetails = answers.map(answer => {
      const question = answer.quiz_questions;
      let isCorrect = answer.is_correct;
      let score = answer.points_earned;

      // For auto-graded questions, always recalculate to ensure accuracy
      if (question.question_type === 'multiple_choice' || question.question_type === 'true_false') {
        const correctOption = question.quiz_question_options?.find(opt => opt.is_correct);
        if (correctOption && answer.selected_option_id === correctOption.id) {
          isCorrect = true;
          score = question.points;
        } else {
          isCorrect = false;
          score = 0;
        }
      } else if (question.question_type === 'essay') {
        // Essay questions - use manual_score if reviewed
        if (answer.review_status === 'approved' || answer.review_status === 'rejected') {
          score = answer.manual_score;
          isCorrect = answer.is_correct ?? false;
        } else {
          // Pending review
          score = null;
          isCorrect = false;
        }
      }

      return {
        id: answer.id,
        questionId: answer.question_id,
        answerText: answer.answer_text,
        selectedOptionId: answer.selected_option_id,
        reviewStatus: answer.review_status,
        manualScore: answer.manual_score,
        question: {
          id: question.id,
          questionText: question.question_text,
          questionType: question.question_type,
          points: question.points,
          options: question.quiz_question_options || []
        },
        isCorrect,
        score
      };
    });

    // Format response
    const responseData = {
      id: submission.id,
      quizId: submission.quiz_id,
      studentId: submission.student_id,
      attemptNumber: submission.attempt_number,
      submittedAt: submission.submitted_at,
      isLate: submission.is_late,
      totalScore: submission.total_score,
      maxScore: submission.max_score,
      isGraded: submission.is_graded,
      grade: submission.grade,
      feedback: submission.feedback,
      quiz: {
        id: submission.quizzes.id,
        title: submission.quizzes.title
      },
      student: {
        id: submission.users.id,
        fullName: submission.users.full_name,
        email: submission.users.email
      },
      answers: answersWithDetails
    };

    res.json(buildResponse(true, 'Submission retrieved successfully', responseData));
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
      status = 'all', // all, submitted, not_submitted, late, graded
      sortBy = 'submitted_at',
      sortOrder = 'desc',
      groupId = '', // Filter by specific group
      attemptFilter = 'all' // all, first_attempt, multiple_attempts
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

    // Get all students in quiz groups with group information
    let studentsQuery = supabase
      .from('quiz_groups')
      .select(`
        groups!inner(
          id, name,
          student_enrollments!inner(
            users!inner(id, username, full_name, email)
          )
        )
      `)
      .eq('quiz_id', quizId);

    // Apply group filter if specified
    if (groupId) {
      studentsQuery = studentsQuery.eq('group_id', groupId);
    }

    const { data: students, error: studentsError } = await studentsQuery;

    if (studentsError) {
      console.error('Error fetching students:', studentsError);
      throw new AppError('Failed to fetch students', 500, 'FETCH_STUDENTS_ERROR');
    }

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

    // Flatten students data with group information
    const allStudents = students.flatMap(qg => {
      if (!qg.groups || !qg.groups.student_enrollments) {
        return [];
      }
      return qg.groups.student_enrollments.map(se => ({
        ...se.users,
        groupId: qg.groups.id,
        groupName: qg.groups.name
      }));
    });

    // Remove duplicates based on student id
    const uniqueStudents = Array.from(
      new Map(allStudents.map(s => [s.id, s])).values()
    );

    // Get student IDs for query
    const studentIds = uniqueStudents.map(s => s.id);
    
    if (studentIds.length === 0) {
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

    // Get submissions for these students with answers
    const { data: submissions, error: submissionsError } = await supabase
      .from('quiz_submissions')
      .select(`
        id, quiz_id, student_id, attempt_number, submitted_at, is_late, 
        total_score, max_score, is_graded, grade, feedback, graded_at, graded_by,
        created_at, updated_at,
        student:users!quiz_submissions_student_id_fkey(id, username, full_name, email),
        quiz_answers(
          id, question_id, answer_text, selected_option_id, created_at
        )
      `)
      .eq('quiz_id', quizId)
      .in('student_id', studentIds);

    if (submissionsError) {
      console.error('Error fetching submissions:', submissionsError);
      throw new AppError('Failed to fetch submissions', 500, 'FETCH_SUBMISSIONS_ERROR');
    }

    // Create enhanced tracking data
    const trackingData = uniqueStudents.map(student => {
      const studentSubmissions = submissions?.filter(sub => sub.student_id === student.id) || [];
      const latestSubmission = studentSubmissions.length > 0 
        ? [...studentSubmissions].sort((a, b) => new Date(b.submitted_at) - new Date(a.submitted_at))[0]
        : null;

      // Calculate submission statistics
      const gradedSubmissions = studentSubmissions.filter(sub => sub.is_graded);
      const lateSubmissions = studentSubmissions.filter(sub => sub.is_late);
      const averageGrade = gradedSubmissions.length > 0 && gradedSubmissions.some(sub => sub.grade !== null)
        ? gradedSubmissions
            .filter(sub => sub.grade !== null)
            .reduce((sum, sub) => sum + parseFloat(sub.grade), 0) / gradedSubmissions.filter(sub => sub.grade !== null).length
        : null;

      return {
        studentId: student.id,
        username: student.username,
        fullName: student.full_name,
        email: student.email,
        groupId: student.groupId,
        groupName: student.groupName,
        totalSubmissions: studentSubmissions.length,
        gradedSubmissions: gradedSubmissions.length,
        lateSubmissions: lateSubmissions.length,
        averageGrade: averageGrade,
        latestSubmission: latestSubmission ? {
          id: latestSubmission.id,
          quizId: latestSubmission.quiz_id,
          studentId: latestSubmission.student_id,
          attemptNumber: latestSubmission.attempt_number,
          submittedAt: latestSubmission.submitted_at,
          isLate: latestSubmission.is_late,
          totalScore: latestSubmission.total_score,
          maxScore: latestSubmission.max_score,
          isGraded: latestSubmission.is_graded,
          grade: latestSubmission.grade,
          feedback: latestSubmission.feedback,
          gradedAt: latestSubmission.graded_at,
          gradedBy: latestSubmission.graded_by,
          createdAt: latestSubmission.created_at,
          updatedAt: latestSubmission.updated_at,
          answers: (latestSubmission.quiz_answers || []).map(ans => ({
            id: ans.id,
            questionId: ans.question_id,
            answerText: ans.answer_text,
            selectedOptionId: ans.selected_option_id,
            createdAt: ans.created_at
          })),
          student: latestSubmission.student ? {
            id: latestSubmission.student.id,
            username: latestSubmission.student.username,
            fullName: latestSubmission.student.full_name,
            email: latestSubmission.student.email
          } : null
        } : null,
        status: (() => {
          if (!latestSubmission) return 'not_submitted';
          if (latestSubmission.is_graded) return 'graded';
          if (latestSubmission.is_late) return 'late';
          return 'submitted';
        })(),
        hasMultipleAttempts: studentSubmissions.length > 1
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

    // Apply attempt filter
    if (attemptFilter === 'first_attempt') {
      filteredData = filteredData.filter(item => item.totalSubmissions === 1);
    } else if (attemptFilter === 'multiple_attempts') {
      filteredData = filteredData.filter(item => item.hasMultipleAttempts);
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

  /**
   * Review essay answer
   */
  reviewEssayAnswer = catchAsync(async (req, res) => {
    const { submissionId, answerId } = req.params;
    const { action, manualScore } = req.body;
    const instructorId = req.user.id;

    // Validate action
    if (!['approve', 'reject'].includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid action. Must be "approve" or "reject"',
        code: 'INVALID_ACTION'
      });
    }

    // Verify instructor has access to the submission
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

    // Get the answer and verify it belongs to the submission and is an essay question
    const { data: answer } = await supabase
      .from('quiz_answers')
      .select(`
        id, submission_id, question_id,
        quiz_questions!inner(id, question_type, points)
      `)
      .eq('id', answerId)
      .eq('submission_id', submissionId)
      .single();

    if (!answer) {
      throw new AppError('Answer not found', 404, 'ANSWER_NOT_FOUND');
    }

    if (answer.quiz_questions.question_type !== 'essay') {
      return res.status(400).json({
        success: false,
        message: 'Only essay questions can be manually reviewed',
        code: 'INVALID_QUESTION_TYPE'
      });
    }

    // Calculate the score based on action
    const questionPoints = answer.quiz_questions.points;
    const scoreToSet = manualScore !== undefined && manualScore !== null
      ? parseFloat(manualScore)
      : (action === 'approve' ? questionPoints : 0);

    // Update the answer with review status and manual score
    const { data: updatedAnswer, error: updateError } = await supabase
      .from('quiz_answers')
      .update({
        review_status: action === 'approve' ? 'approved' : 'rejected',
        manual_score: scoreToSet,
        points_earned: scoreToSet,
        is_correct: action === 'approve',
        updated_at: new Date().toISOString()
      })
      .eq('id', answerId)
      .select('id, review_status, manual_score, points_earned, is_correct')
      .single();

    if (updateError) {
      console.error('Review answer error:', updateError);
      throw new AppError('Failed to review answer', 500, 'REVIEW_ANSWER_FAILED');
    }

    // Recalculate total score for the submission
    const { data: allAnswers } = await supabase
      .from('quiz_answers')
      .select(`
        points_earned,
        quiz_questions!inner(question_type)
      `)
      .eq('submission_id', submissionId);

    const totalScore = allAnswers.reduce((sum, ans) => {
      return sum + (parseFloat(ans.points_earned) || 0);
    }, 0);

    // Update submission total score
    await supabase
      .from('quiz_submissions')
      .update({
        total_score: totalScore,
        updated_at: new Date().toISOString()
      })
      .eq('id', submissionId);

    res.json(
      buildResponse(true, 'Answer reviewed successfully', {
        answer: updatedAnswer,
        totalScore
      })
    );
  });

  /**
   * Complete grading for a submission
   */
  completeGrading = catchAsync(async (req, res) => {
    const { submissionId } = req.params;
    const instructorId = req.user.id;

    // Verify instructor has access to the submission
    const { data: submission } = await supabase
      .from('quiz_submissions')
      .select(`
        id, quiz_id, is_graded,
        quizzes!inner(instructor_id)
      `)
      .eq('id', submissionId)
      .eq('quizzes.instructor_id', instructorId)
      .single();

    if (!submission) {
      throw new AppError('Submission not found or access denied', 404, 'SUBMISSION_NOT_FOUND');
    }

    // Check if all essay answers have been reviewed
    // First get all answers with their questions
    const { data: allAnswers } = await supabase
      .from('quiz_answers')
      .select(`
        id,
        review_status,
        quiz_questions!inner(
          id,
          question_type
        )
      `)
      .eq('submission_id', submissionId);

    // Filter for pending essay answers in JavaScript
    const pendingAnswers = allAnswers?.filter(answer => 
      answer.quiz_questions?.question_type === 'essay' && 
      answer.review_status === 'pending'
    ) || [];

    if (pendingAnswers && pendingAnswers.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Cannot complete grading. ${pendingAnswers.length} essay answer(s) still pending review`,
        code: 'PENDING_REVIEWS',
        pendingCount: pendingAnswers.length
      });
    }

    // Recalculate total score from all answers (including reviewed essay answers)
    const { data: allAnswersForScore } = await supabase
      .from('quiz_answers')
      .select(`
        points_earned,
        manual_score,
        quiz_questions!inner(
          points,
          question_type
        )
      `)
      .eq('submission_id', submissionId);

    let recalculatedTotalScore = 0;
    let maxScore = 0;
    if (allAnswersForScore) {
      allAnswersForScore.forEach(answer => {
        const question = answer.quiz_questions;
        maxScore += question.points;
        
        if (question.question_type === 'essay') {
          // Use manual_score for essay questions
          recalculatedTotalScore += answer.manual_score || 0;
        } else {
          // Use points_earned for auto-graded questions
          recalculatedTotalScore += answer.points_earned || 0;
        }
      });
    }

    // Mark submission as graded and update total score
    const { data: updatedSubmission, error: updateError } = await supabase
      .from('quiz_submissions')
      .update({
        is_graded: true,
        total_score: recalculatedTotalScore,
        max_score: maxScore,
        graded_at: new Date().toISOString(),
        graded_by: instructorId,
        updated_at: new Date().toISOString()
      })
      .eq('id', submissionId)
      .select('id, is_graded, graded_at, graded_by, total_score, max_score')
      .single();

    if (updateError) {
      console.error('Complete grading error:', updateError);
      throw new AppError('Failed to complete grading', 500, 'COMPLETE_GRADING_FAILED');
    }

    res.json(
      buildResponse(true, 'Grading completed successfully', { submission: updatedSubmission })
    );
  });

  /**
   * Get student's submissions for a quiz
   */
  getStudentQuizSubmissions = catchAsync(async (req, res) => {
    const { quizId } = req.params;
    const studentId = req.user.id;

    // Verify quiz exists and student has access
    const { data: quiz } = await supabase
      .from('quizzes')
      .select(`
        id, title, max_attempts,
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

    // Get student's submissions for this quiz
    const { data: submissions, error } = await supabase
      .from('quiz_submissions')
      .select(`
        id, quiz_id, student_id, attempt_number, submitted_at, is_late,
        total_score, max_score, is_graded, grade, feedback, graded_at,
        created_at, updated_at
      `)
      .eq('quiz_id', quizId)
      .eq('student_id', studentId)
      .order('attempt_number', { ascending: false });

    if (error) {
      console.error('Get student quiz submissions error:', error);
      throw new AppError('Failed to fetch submissions', 500, 'FETCH_SUBMISSIONS_ERROR');
    }

    res.json(
      buildResponse(true, undefined, {
        submissions: submissions || [],
        maxAttempts: quiz.max_attempts,
        currentAttempts: submissions?.length || 0
      })
    );
  });
}

module.exports = new QuizController();
