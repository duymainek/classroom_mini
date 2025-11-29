const { supabase } = require('../services/supabaseClient');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');
const fileUploadController = require('./fileUploadController');
require('../types/assignment.type');

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
      groupIds,
      attachmentIds // changed from attachments
    } = req.body;

    const instructorId = req.user.id;

    // Basic validation
    if (!title || title.trim().length < 2) {
      return res.status(400).json({
        success: false,
        message: 'Title is required and must be at least 2 characters'
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

    // Finalize temporary attachments if any
    if (attachmentIds && attachmentIds.length > 0) {
      try {
        console.log('=== FINALIZE TEMP ATTACHMENTS DEBUG ===');
        console.log('Assignment ID:', newAssignment.id);
        console.log('Instructor ID:', instructorId);
        console.log('Attachment IDs to finalize:', attachmentIds);
        
        // Call finalize method directly
        const mockReq = {
          params: { assignmentId: newAssignment.id },
          body: { tempAttachmentIds: attachmentIds },
          user: { id: instructorId }
        };
        const mockRes = {
          json: (data) => {
            console.log('Finalize response:', data);
            return data;
          },
          status: (code) => ({ 
            json: (data) => {
              console.log('Finalize status response:', code, data);
              return { statusCode: code, body: data };
            }
          })
        };

        console.log('Calling finalizeTempAttachments...');
        try {
          // Call the method directly without catchAsync wrapper
          const result = await fileUploadController.finalizeTempAttachments(mockReq, mockRes);
          console.log('Finalize result:', result);
          console.log('Successfully finalized temp attachments');
          
          // Add small delay to ensure database commit
          await new Promise(resolve => setTimeout(resolve, 100));
        } catch (finalizeError) {
          console.error('Finalize method error:', finalizeError);
          console.error('Finalize error stack:', finalizeError.stack);
        }
        console.log('=== END FINALIZE DEBUG ===');
      } catch (error) {
        console.error('Error finalizing temp attachments:', error);
        console.error('Error stack:', error.stack);
        // Don't fail assignment creation, just log the error
      }
    } else {
      console.log('No attachment IDs provided for finalization');
    }

    // Get assignment with groups and attachments for response
    const { data: assignmentWithGroups } = await supabase
      .from('assignments')
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, file_formats, max_file_size, is_active,
        created_at, updated_at,
        courses!inner(code, name),
        assignment_groups(
          group_id,
          groups!inner(id, name)
        ),
        assignment_attachments(
          id, file_name, file_url, file_size, file_type, created_at
        )
      `)
      .eq('id', newAssignment.id)
      .single();

    res.status(201).json(
      buildResponse(true, 'Assignment created successfully', { assignment: assignmentWithGroups })
    );
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
        ),
        assignment_attachments(
          id, file_name, file_url, file_size, file_type, created_at
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
          ),
          assignment_attachments(
            id, file_name, file_url, file_size, file_type, created_at
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

    res.json(
      buildResponse(true, undefined, {
        assignments: assignments || [],
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

    res.json(buildResponse(true, undefined, { assignment }));
  });

  /**
   * Update assignment
   */
  updateAssignment = catchAsync(async (req, res) => {
    const { assignmentId } = req.params;
    const instructorId = req.user.id;
    const { attachmentIds, ...updateData } = req.body; // separate attachmentIds

    // Validate input
    const validation = validate(updateAssignmentSchema, updateData);
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
    const { error } = await supabase
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

    // Handle attachment linking
    if (attachmentIds !== undefined) {
      // First, unlink existing attachments from this assignment
      await supabase
        .from('assignment_attachments')
        .update({ assignment_id: null })
        .eq('assignment_id', assignmentId);

      // Link new attachments if provided
      if (attachmentIds.length > 0) {
        const { error: attachmentsError } = await supabase
          .from('assignment_attachments')
          .update({ assignment_id: assignmentId })
          .in('id', attachmentIds);

        if (attachmentsError) {
          console.error('Assignment attachments update error:', attachmentsError);
          throw new AppError('Failed to update attachments for assignment', 500, 'ATTACHMENT_UPDATE_FAILED');
        }
      }
    }

    // Get assignment with attachments for response
    const { data: finalAssignment } = await supabase
      .from('assignments')
      .select(`
        id, title, description, course_id, instructor_id,
        start_date, due_date, late_due_date, allow_late_submission,
        max_attempts, file_formats, max_file_size, is_active,
        created_at, updated_at,
        courses!inner(code, name),
        assignment_attachments(id, file_name, file_url, file_size, file_type, created_at),
        assignment_groups(
          groups!inner(id, name)
        )
      `)
      .eq('id', assignmentId)
      .single();

    res.json(
      buildResponse(true, 'Assignment updated successfully', { assignment: finalAssignment })
    );
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

    // Delete assignment (cascade will handle related records including submissions)
    const { error } = await supabase
      .from('assignments')
      .delete()
      .eq('id', assignmentId);

    if (error) {
      console.error('Delete assignment error:', error);
      throw new AppError('Failed to delete assignment', 500, 'DELETE_ASSIGNMENT_FAILED');
    }

    res.json(buildResponse(true, 'Assignment deleted successfully'));
  });

  /**
   * Get assignment submissions with enhanced real-time tracking
   */
  getAssignmentSubmissions = catchAsync(async (req, res) => {
    const { assignmentId } = req.params;
    const {
      page = 1,
      limit = 20,
      search = '',
      status = 'all', // all, submitted, not_submitted, late, graded, ungraded
      sortBy = 'submitted_at',
      sortOrder = 'desc',
      groupId = '', // Filter by specific group
      attemptFilter = 'all' // all, first_attempt, multiple_attempts
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

    // Get all students in assignment groups with enhanced filtering
    let studentsQuery = supabase
      .from('assignment_groups')
      .select(`
        groups!inner(
          id, name,
          student_enrollments!inner(
            users!inner(id, username, full_name, email)
          )
        )
      `)
      .eq('assignment_id', assignmentId);

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
    const allStudents = students.flatMap(ag => {
      if (!ag.groups || !ag.groups.student_enrollments) {
        return [];
      }
      return ag.groups.student_enrollments.map(se => ({
        ...se.users,
        groupId: ag.groups.id,
        groupName: ag.groups.name
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

    // Get submissions for these students with attachments
    // Note: Must specify foreign key relationship explicitly because there are two FKs to users table
    const { data: submissions, error: submissionsError } = await supabase
      .from('assignment_submissions')
      .select(`
        id, student_id, attempt_number, submission_text,
        submitted_at, is_late, grade, feedback, graded_at, graded_by,
        created_at, updated_at, assignment_id,
        student:users!assignment_submissions_student_id_fkey(id, username, full_name, email),
        submission_attachments(id, file_name, file_url, file_size, file_type, created_at)
      `)
      .eq('assignment_id', assignmentId)
      .in('student_id', studentIds);

    if (submissionsError) {
      console.error('Error fetching submissions:', submissionsError);
      console.error('Assignment ID:', assignmentId);
      console.error('Student IDs:', studentIds);
      throw new AppError('Failed to fetch submissions', 500, 'FETCH_SUBMISSIONS_ERROR');
    }

    // Create enhanced tracking data
    const trackingData = uniqueStudents.map(student => {
      const studentSubmissions = submissions?.filter(sub => sub.student_id === student.id) || [];
      const latestSubmission = studentSubmissions.length > 0 
        ? [...studentSubmissions].sort((a, b) => new Date(b.submitted_at) - new Date(a.submitted_at))[0]
        : null;

      // Calculate submission statistics
      const gradedSubmissions = studentSubmissions.filter(sub => sub.grade !== null);
      const lateSubmissions = studentSubmissions.filter(sub => sub.is_late);
      const averageGrade = gradedSubmissions.length > 0 
        ? gradedSubmissions.reduce((sum, sub) => sum + parseFloat(sub.grade), 0) / gradedSubmissions.length 
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
          assignmentId: latestSubmission.assignment_id,
          studentId: latestSubmission.student_id,
          attemptNumber: latestSubmission.attempt_number,
          submissionText: latestSubmission.submission_text,
          submittedAt: latestSubmission.submitted_at,
          isLate: latestSubmission.is_late,
          grade: latestSubmission.grade,
          feedback: latestSubmission.feedback,
          gradedAt: latestSubmission.graded_at,
          gradedBy: latestSubmission.graded_by,
          createdAt: latestSubmission.created_at,
          updatedAt: latestSubmission.updated_at,
          attachments: (latestSubmission.submission_attachments || []).map(att => ({
            id: att.id,
            file_name: att.file_name,
            file_url: att.file_url,
            file_size: att.file_size,
            file_type: att.file_type,
            created_at: att.created_at
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
          if (latestSubmission.grade !== null) return 'graded';
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

    res.json(
      buildResponse(true, 'Submission graded successfully', { submission: updatedSubmission })
    );
  });

  /**
   * Export assignment submissions to CSV with enhanced data
   */
  exportSubmissions = catchAsync(async (req, res) => {
    const { assignmentId } = req.params;
    const { 
      includeGrades = true,
      includeFeedback = true,
      includeAttempts = true
    } = req.query;
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

    // Get all submissions with enhanced student and group info
    // Note: Must specify foreign key relationship explicitly because there are two FKs to users table
    const { data: submissions } = await supabase
      .from('assignment_submissions')
      .select(`
        id, attempt_number, submission_text, submitted_at, is_late, grade, feedback,
        student:users!assignment_submissions_student_id_fkey(username, full_name, email),
        assignments!inner(
          assignment_groups!inner(
            groups!inner(id, name)
          )
        )
      `)
      .eq('assignment_id', assignmentId)
      .order('submitted_at', { ascending: false });

    if (!submissions || submissions.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No submissions found for this assignment'
      });
    }

    // Flatten submissions data for CSV export
    const flattenedSubmissions = submissions.map(sub => ({
      username: sub.student?.username || '',
      full_name: sub.student?.full_name || '',
      email: sub.student?.email || '',
      group_name: sub.assignments?.assignment_groups?.[0]?.groups?.name || 'N/A',
      attempt_number: sub.attempt_number || '',
      submitted_at: sub.submitted_at || '',
      is_late: sub.is_late ? 'Yes' : 'No',
      grade: sub.grade || '',
      feedback: sub.feedback || '',
      submission_text: sub.submission_text || ''
    }));

    // Generate enhanced CSV with conditional fields
    const jsoncsv = require('json-csv');
    const fields = [
      { name: 'username', label: 'Username' },
      { name: 'full_name', label: 'Full Name' },
      { name: 'email', label: 'Email' },
      { name: 'group_name', label: 'Group' },
      { name: 'attempt_number', label: 'Attempt' },
      { name: 'submitted_at', label: 'Submitted At' },
      { name: 'is_late', label: 'Is Late' }
    ];

    // Add conditional fields based on query parameters
    if (includeGrades === 'true') {
      fields.push({ name: 'grade', label: 'Grade' });
    }
    if (includeFeedback === 'true') {
      fields.push({ name: 'feedback', label: 'Feedback' });
    }
    if (includeAttempts === 'true') {
      fields.push({ name: 'submission_text', label: 'Submission Text' });
    }

    const csv = await new Promise((resolve, reject) => {
      jsoncsv.toCSV({
        data: flattenedSubmissions || [],
        fields: fields
      }, (err, csvString) => {
        if (err) reject(err);
        else resolve(csvString);
      });
    });
    const filename = `assignment_${assignmentId}_submissions_${new Date().toISOString().slice(0,19).replace(/[:T]/g, '-')}.csv`;

    // Add BOM for Excel compatibility
    const bom = Buffer.from([0xEF, 0xBB, 0xBF]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.status(200).send(Buffer.concat([bom, Buffer.from(csv, 'utf8')]));
  });

  /**
   * Export assignment tracking data to CSV (includes all students - submitted and not submitted)
   */
  exportAssignmentTracking = catchAsync(async (req, res) => {
    const { assignmentId } = req.params;
    const { 
      search = '',
      status = 'all',
      groupId = '',
      sortBy = 'fullName',
      sortOrder = 'asc'
    } = req.query;
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
    let studentsQuery = supabase
      .from('assignment_groups')
      .select(`
        groups!inner(
          id, name,
          student_enrollments!inner(
            users!inner(id, username, full_name, email)
          )
        )
      `)
      .eq('assignment_id', assignmentId);

    if (groupId) {
      studentsQuery = studentsQuery.eq('group_id', groupId);
    }

    const { data: students } = await studentsQuery;

    if (!students || students.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No students found for this assignment'
      });
    }

    // Flatten students data with group information
    const allStudents = students.flatMap(ag => 
      ag.groups.student_enrollments.map(se => ({
        ...se.users,
        groupId: ag.groups.id,
        groupName: ag.groups.name
      }))
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

    // Create tracking data for export
    const trackingData = allStudents.map(student => {
      const studentSubmissions = submissions?.filter(sub => sub.student_id === student.id) || [];
      const latestSubmission = studentSubmissions.length > 0 
        ? [...studentSubmissions].sort((a, b) => new Date(b.submitted_at) - new Date(a.submitted_at))[0]
        : null;

      const gradedSubmissions = studentSubmissions.filter(sub => sub.grade !== null);
      const lateSubmissions = studentSubmissions.filter(sub => sub.is_late);
      const averageGrade = gradedSubmissions.length > 0 
        ? gradedSubmissions.reduce((sum, sub) => sum + parseFloat(sub.grade), 0) / gradedSubmissions.length 
        : null;

      const status = (() => {
        if (!latestSubmission) return 'not_submitted';
        if (latestSubmission.grade !== null) return 'graded';
        if (latestSubmission.is_late) return 'late';
        return 'submitted';
      })();

      return {
        username: student.username,
        fullName: student.full_name,
        email: student.email,
        groupName: student.groupName,
        totalSubmissions: studentSubmissions.length,
        gradedSubmissions: gradedSubmissions.length,
        lateSubmissions: lateSubmissions.length,
        averageGrade: averageGrade ? averageGrade.toFixed(2) : '',
        latestSubmittedAt: latestSubmission?.submitted_at || '',
        latestGrade: latestSubmission?.grade || '',
        latestIsLate: latestSubmission?.is_late ? 'Yes' : 'No',
        status: status
      };
    });

    // Apply filters (same as getAssignmentSubmissions)
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

    // Generate CSV
    const jsoncsv = require('json-csv');
    const fields = [
      { name: 'username', label: 'Username' },
      { name: 'fullName', label: 'Full Name' },
      { name: 'email', label: 'Email' },
      { name: 'groupName', label: 'Group' },
      { name: 'status', label: 'Status' },
      { name: 'totalSubmissions', label: 'Total Submissions' },
      { name: 'gradedSubmissions', label: 'Graded Submissions' },
      { name: 'lateSubmissions', label: 'Late Submissions' },
      { name: 'averageGrade', label: 'Average Grade' },
      { name: 'latestGrade', label: 'Latest Grade' },
      { name: 'latestSubmittedAt', label: 'Latest Submitted At' },
      { name: 'latestIsLate', label: 'Latest Is Late' }
    ];

    const csv = await new Promise((resolve, reject) => {
      jsoncsv.toCSV({
        data: filteredData || [],
        fields: fields
      }, (err, csvString) => {
        if (err) reject(err);
        else resolve(csvString);
      });
    });
    const filename = `assignment_${assignmentId}_tracking_${new Date().toISOString().slice(0,19).replace(/[:T]/g, '-')}.csv`;

    // Add BOM for Excel compatibility
    const bom = Buffer.from([0xEF, 0xBB, 0xBF]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.status(200).send(Buffer.concat([bom, Buffer.from(csv, 'utf8')]));
  });

  /**
   * Export all assignments for a course/semester to CSV
   */
  exportAllAssignments = catchAsync(async (req, res) => {
    const { 
      courseId = '',
      semesterId = '',
      includeSubmissions = true,
      includeGrades = true
    } = req.query;
    const instructorId = req.user.id;

    // Build query for assignments
    let assignmentsQuery = supabase
      .from('assignments')
      .select(`
        id, title, description, start_date, due_date, late_due_date,
        allow_late_submission, max_attempts, is_active, created_at,
        courses!inner(code, name, semester_id),
        users!assignments_instructor_id_fkey(full_name)
      `)
      .eq('instructor_id', instructorId);

    if (courseId) {
      assignmentsQuery = assignmentsQuery.eq('course_id', courseId);
    }
    if (semesterId) {
      assignmentsQuery = assignmentsQuery.eq('courses.semester_id', semesterId);
    }

    const { data: assignments } = await assignmentsQuery;

    if (!assignments || assignments.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No assignments found for the specified criteria'
      });
    }

    // Get submission statistics for each assignment
    const assignmentsWithStats = await Promise.all(
      assignments.map(async (assignment) => {
        const { data: submissions } = await supabase
          .from('assignment_submissions')
          .select('id, grade, is_late, submitted_at')
          .eq('assignment_id', assignment.id);

        const totalSubmissions = submissions?.length || 0;
        const gradedSubmissions = submissions?.filter(s => s.grade !== null).length || 0;
        const lateSubmissions = submissions?.filter(s => s.is_late).length || 0;
        const averageGrade = gradedSubmissions > 0 
          ? submissions.filter(s => s.grade !== null)
              .reduce((sum, s) => sum + parseFloat(s.grade), 0) / gradedSubmissions
          : null;

        return {
          ...assignment,
          totalSubmissions,
          gradedSubmissions,
          lateSubmissions,
          averageGrade: averageGrade ? averageGrade.toFixed(2) : 'N/A'
        };
      })
    );

    // Generate CSV
    const jsoncsv = require('json-csv');
    const fields = [
      { name: 'title', label: 'Assignment Title' },
      { name: 'courses.code', label: 'Course Code' },
      { name: 'courses.name', label: 'Course Name' },
      { name: 'users.full_name', label: 'Instructor' },
      { name: 'start_date', label: 'Start Date' },
      { name: 'due_date', label: 'Due Date' },
      { name: 'late_due_date', label: 'Late Due Date' },
      { name: 'max_attempts', label: 'Max Attempts' },
      { name: 'is_active', label: 'Active', filter: (v) => v ? 'Yes' : 'No' }
    ];

    if (includeSubmissions === 'true') {
      fields.push(
        { name: 'totalSubmissions', label: 'Total Submissions' },
        { name: 'gradedSubmissions', label: 'Graded Submissions' },
        { name: 'lateSubmissions', label: 'Late Submissions' }
      );
    }

    if (includeGrades === 'true') {
      fields.push({ name: 'averageGrade', label: 'Average Grade' });
    }

    const csv = await new Promise((resolve, reject) => {
      jsoncsv.toCSV({
        data: assignmentsWithStats || [],
        fields: fields
      }, (err, csvString) => {
        if (err) reject(err);
        else resolve(csvString);
      });
    });
    const filename = `assignments_export_${new Date().toISOString().slice(0,19).replace(/[:T]/g, '-')}.csv`;

    // Add BOM for Excel compatibility
    const bom = Buffer.from([0xEF, 0xBB, 0xBF]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.status(200).send(Buffer.concat([bom, Buffer.from(csv, 'utf8')]));
  });
}

module.exports = new AssignmentController();
