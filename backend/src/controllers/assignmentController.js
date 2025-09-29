const { supabase } = require('../services/supabaseClient');
const { validateAssignmentCreation, validateAssignmentUpdate } = require('../models/assignment');
const { AppError, catchAsync } = require('../middleware/errorHandler');

class AssignmentController {
  /**
   * Create new assignment
   */
  createAssignment = catchAsync(async (req, res) => {
    const {
      title,
      description,
      courseId,
      startDate,
      dueDate,
      lateDueDate,
      allowLateSubmission,
      maxAttempts,
      fileFormats,
      maxFileSize,
      groupIds
    } = req.body;

    const instructorId = req.user.id;

    // Validate input
    const validation = validateAssignmentCreation({
      title,
      description,
      courseId,
      startDate,
      dueDate,
      lateDueDate,
      allowLateSubmission,
      maxAttempts,
      fileFormats,
      maxFileSize,
      groupIds
    });

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

    // Create assignment
    const { data: newAssignment, error: assignmentError } = await supabase
      .from('assignments')
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
        file_formats: fileFormats || [],
        max_file_size: maxFileSize || 10
      })
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, file_formats, max_file_size, is_active,
        created_at, updated_at,
        courses!inner(code, name)
      `)
      .single();

    if (assignmentError) {
      console.error('Assignment creation error:', assignmentError);
      throw new AppError('Failed to create assignment', 500, 'ASSIGNMENT_CREATION_FAILED');
    }

    // Create assignment-group relationships
    if (groupIds && groupIds.length > 0) {
      const assignmentGroups = groupIds.map(groupId => ({
        assignment_id: newAssignment.id,
        group_id: groupId
      }));

      const { error: groupsError } = await supabase
        .from('assignment_groups')
        .insert(assignmentGroups);

      if (groupsError) {
        console.error('Assignment groups creation error:', groupsError);
        // Rollback assignment creation
        await supabase
          .from('assignments')
          .delete()
          .eq('id', newAssignment.id);
        
        throw new AppError('Failed to assign groups to assignment', 500, 'GROUP_ASSIGNMENT_FAILED');
      }
    }

    // Get assignment with groups for response
    const { data: assignmentWithGroups } = await supabase
      .from('assignments')
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, file_formats, max_file_size, is_active,
        created_at, updated_at,
        courses!inner(code, name),
        assignment_groups(
          groups!inner(id, name)
        )
      `)
      .eq('id', newAssignment.id)
      .single();

    res.status(201).json({
      success: true,
      message: 'Assignment created successfully',
      data: {
        assignment: assignmentWithGroups
      }
    });
  });

  /**
   * Get assignments with pagination, search, and filters
   */
  getAssignments = catchAsync(async (req, res) => {
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
      .from('assignments')
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, file_formats, max_file_size, is_active,
        created_at, updated_at,
        courses!inner(code, name, semester_id),
        users!assignments_instructor_id_fkey(full_name),
        assignment_groups(
          groups!inner(id, name)
        )
      `, { count: 'exact' });

    // Apply role-based filtering
    if (userRole === 'student') {
      // Students can only see assignments assigned to their groups
      query = query
        .select(`
          id, title, description, course_id, instructor_id,
          start_date, due_date, late_due_date, allow_late_submission,
          max_attempts, file_formats, max_file_size, is_active,
          created_at, updated_at,
          courses!inner(code, name),
          users!assignments_instructor_id_fkey(full_name),
          assignment_groups!inner(
            groups!inner(
              student_enrollments!inner(student_id)
            )
          )
        `)
        .eq('assignment_groups.groups.student_enrollments.student_id', userId);
    } else {
      // Instructors can see all assignments
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

    const { data: assignments, error, count } = await query;

    if (error) {
      console.error('Get assignments error:', error);
      throw new AppError('Failed to fetch assignments', 500, 'GET_ASSIGNMENTS_FAILED');
    }

    res.json({
      success: true,
      data: {
        assignments: assignments || [],
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count || 0,
          pages: Math.ceil((count || 0) / parseInt(limit))
        }
      }
    });
  });

  /**
   * Get assignment by ID with full details
   */
  getAssignmentById = catchAsync(async (req, res) => {
    const { assignmentId } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Build query with role-based access
    let query = supabase
      .from('assignments')
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, file_formats, max_file_size, is_active,
        created_at, updated_at,
        courses!inner(code, name),
        users!assignments_instructor_id_fkey(full_name),
        assignment_attachments(id, file_name, file_url, file_size, file_type, created_at),
        assignment_groups(
          groups!inner(id, name)
        )
      `)
      .eq('id', assignmentId);

    // Apply role-based filtering
    if (userRole === 'student') {
      query = query
        .select(`
          id, title, description, course_id, instructor_id,
          start_date, due_date, late_due_date, allow_late_submission,
          max_attempts, file_formats, max_file_size, is_active,
          created_at, updated_at,
          courses!inner(code, name),
          users!assignments_instructor_id_fkey(full_name),
          assignment_attachments(id, file_name, file_url, file_size, file_type, created_at),
          assignment_groups!inner(
            groups!inner(
              student_enrollments!inner(student_id)
            )
          )
        `)
        .eq('assignment_groups.groups.student_enrollments.student_id', userId);
    } else {
      query = query.eq('instructor_id', userId);
    }

    const { data: assignment, error } = await query.single();

    if (error || !assignment) {
      throw new AppError('Assignment not found', 404, 'ASSIGNMENT_NOT_FOUND');
    }

    res.json({
      success: true,
      data: {
        assignment
      }
    });
  });

  /**
   * Update assignment
   */
  updateAssignment = catchAsync(async (req, res) => {
    const { assignmentId } = req.params;
    const instructorId = req.user.id;
    const updateData = req.body;

    // Validate input
    const validation = validateAssignmentUpdate(updateData);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if assignment exists and belongs to instructor
    const { data: existingAssignment } = await supabase
      .from('assignments')
      .select('id, instructor_id')
      .eq('id', assignmentId)
      .eq('instructor_id', instructorId)
      .single();

    if (!existingAssignment) {
      throw new AppError('Assignment not found or access denied', 404, 'ASSIGNMENT_NOT_FOUND');
    }

    // Update assignment
    const { data: updatedAssignment, error } = await supabase
      .from('assignments')
      .update({
        ...updateData,
        updated_at: new Date().toISOString()
      })
      .eq('id', assignmentId)
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, file_formats, max_file_size, is_active,
        created_at, updated_at,
        courses!inner(code, name)
      `)
      .single();

    if (error) {
      console.error('Update assignment error:', error);
      throw new AppError('Failed to update assignment', 500, 'UPDATE_ASSIGNMENT_FAILED');
    }

    res.json({
      success: true,
      message: 'Assignment updated successfully',
      data: {
        assignment: updatedAssignment
      }
    });
  });

  /**
   * Delete assignment
   */
  deleteAssignment = catchAsync(async (req, res) => {
    const { assignmentId } = req.params;
    const instructorId = req.user.id;

    // Check if assignment exists and belongs to instructor
    const { data: existingAssignment } = await supabase
      .from('assignments')
      .select('id, instructor_id')
      .eq('id', assignmentId)
      .eq('instructor_id', instructorId)
      .single();

    if (!existingAssignment) {
      throw new AppError('Assignment not found or access denied', 404, 'ASSIGNMENT_NOT_FOUND');
    }

    // Check if assignment has submissions
    const { data: submissions } = await supabase
      .from('assignment_submissions')
      .select('id')
      .eq('assignment_id', assignmentId)
      .limit(1);

    if (submissions && submissions.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete assignment with existing submissions',
        code: 'ASSIGNMENT_HAS_SUBMISSIONS'
      });
    }

    // Delete assignment (cascade will handle related records)
    const { error } = await supabase
      .from('assignments')
      .delete()
      .eq('id', assignmentId);

    if (error) {
      console.error('Delete assignment error:', error);
      throw new AppError('Failed to delete assignment', 500, 'DELETE_ASSIGNMENT_FAILED');
    }

    res.json({
      success: true,
      message: 'Assignment deleted successfully'
    });
  });

  /**
   * Get assignment submissions with tracking
   */
  getAssignmentSubmissions = catchAsync(async (req, res) => {
    const { assignmentId } = req.params;
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

    // Verify assignment belongs to instructor
    const { data: assignment } = await supabase
      .from('assignments')
      .select('id, title, due_date, late_due_date')
      .eq('id', assignmentId)
      .eq('instructor_id', instructorId)
      .single();

    if (!assignment) {
      throw new AppError('Assignment not found or access denied', 404, 'ASSIGNMENT_NOT_FOUND');
    }

    // Get all students in assignment groups
    const { data: students } = await supabase
      .from('assignment_groups')
      .select(`
        groups!inner(
          student_enrollments!inner(
            users!inner(id, username, full_name, email)
          )
        )
      `)
      .eq('assignment_id', assignmentId);

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
    const allStudents = students.flatMap(ag => 
      ag.groups.student_enrollments.map(se => se.users)
    );

    // Get submissions for these students
    const { data: submissions } = await supabase
      .from('assignment_submissions')
      .select(`
        id, student_id, attempt_number, submission_text,
        submitted_at, is_late, grade, feedback, graded_at,
        users!inner(id, username, full_name, email)
      `)
      .eq('assignment_id', assignmentId)
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

    res.json({
      success: true,
      data: {
        submissions: paginatedData,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  });

  /**
   * Grade assignment submission
   */
  gradeSubmission = catchAsync(async (req, res) => {
    const { submissionId } = req.params;
    const { grade, feedback } = req.body;
    const instructorId = req.user.id;

    // Validate grade
    if (grade < 0 || grade > 100) {
      return res.status(400).json({
        success: false,
        message: 'Grade must be between 0 and 100'
      });
    }

    // Check if submission exists and instructor has access
    const { data: submission } = await supabase
      .from('assignment_submissions')
      .select(`
        id, assignment_id,
        assignments!inner(instructor_id)
      `)
      .eq('id', submissionId)
      .eq('assignments.instructor_id', instructorId)
      .single();

    if (!submission) {
      throw new AppError('Submission not found or access denied', 404, 'SUBMISSION_NOT_FOUND');
    }

    // Update submission with grade
    const { data: updatedSubmission, error } = await supabase
      .from('assignment_submissions')
      .update({
        grade,
        feedback,
        graded_at: new Date().toISOString(),
        graded_by: instructorId,
        updated_at: new Date().toISOString()
      })
      .eq('id', submissionId)
      .select(`
        id, grade, feedback, graded_at, graded_by,
        users!inner(full_name)
      `)
      .single();

    if (error) {
      console.error('Grade submission error:', error);
      throw new AppError('Failed to grade submission', 500, 'GRADE_SUBMISSION_FAILED');
    }

    res.json({
      success: true,
      message: 'Submission graded successfully',
      data: {
        submission: updatedSubmission
      }
    });
  });

  /**
   * Export assignment submissions to CSV
   */
  exportSubmissions = catchAsync(async (req, res) => {
    const { assignmentId } = req.params;
    const instructorId = req.user.id;

    // Verify assignment belongs to instructor
    const { data: assignment } = await supabase
      .from('assignments')
      .select('id, title')
      .eq('id', assignmentId)
      .eq('instructor_id', instructorId)
      .single();

    if (!assignment) {
      throw new AppError('Assignment not found or access denied', 404, 'ASSIGNMENT_NOT_FOUND');
    }

    // Get all submissions with student info
    const { data: submissions } = await supabase
      .from('assignment_submissions')
      .select(`
        id, attempt_number, submission_text, submitted_at, is_late, grade, feedback,
        users!inner(username, full_name, email)
      `)
      .eq('assignment_id', assignmentId)
      .order('submitted_at', { ascending: false });

    if (!submissions || submissions.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No submissions found for this assignment'
      });
    }

    // Generate CSV
    const jsoncsv = require('json-csv');
    const fields = [
      { name: 'username', label: 'Username' },
      { name: 'full_name', label: 'Full Name' },
      { name: 'email', label: 'Email' },
      { name: 'attempt_number', label: 'Attempt' },
      { name: 'submitted_at', label: 'Submitted At' },
      { name: 'is_late', label: 'Is Late', transform: (v) => v ? 'Yes' : 'No' },
      { name: 'grade', label: 'Grade' },
      { name: 'feedback', label: 'Feedback' }
    ];

    const csv = await jsoncsv.buffered(submissions, { fields, encoding: 'utf8' });
    const filename = `assignment_${assignmentId}_submissions_${new Date().toISOString().slice(0,19).replace(/[:T]/g, '-')}.csv`;

    // Add BOM for Excel compatibility
    const bom = Buffer.from([0xEF, 0xBB, 0xBF]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.status(200).send(Buffer.concat([bom, Buffer.from(csv, 'utf8')]));
  });
}

module.exports = new AssignmentController();
