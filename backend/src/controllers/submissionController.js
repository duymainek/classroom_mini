const { supabase } = require('../services/supabaseClient');
const { validateSubmissionCreation } = require('../models/assignment');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');
const fileUploadService = require('../services/fileUploadService');
const notificationController = require('./notificationController');

class SubmissionController {
  /**
   * Submit assignment (Student only)
   */
  submitAssignment = catchAsync(async (req, res) => {
    const { assignmentId } = req.params;
    const { submissionText, tempAttachmentIds } = req.body;
    const studentId = req.user.id;

    // Check if assignment exists and student has access
    const { data: assignment } = await supabase
      .from('assignments')
      .select(`
        id, title, due_date, late_due_date, allow_late_submission,
        max_attempts, start_date, is_active, file_formats, max_file_size,
        instructor_id,
        assignment_groups!inner(
          groups!inner(
            student_enrollments!inner(student_id)
          )
        )
      `)
      .eq('id', assignmentId)
      .eq('is_active', true)
      .eq('assignment_groups.groups.student_enrollments.student_id', studentId)
      .single();

    if (!assignment) {
      throw new AppError('Assignment not found or access denied', 404, 'ASSIGNMENT_NOT_FOUND');
    }

    // Check if assignment is open for submission
    const now = new Date();
    const startDate = new Date(assignment.start_date);
    const dueDate = new Date(assignment.due_date);

    if (now < startDate) {
      return res.status(400).json({
        success: false,
        message: 'Assignment is not yet open for submission',
        code: 'ASSIGNMENT_NOT_OPEN'
      });
    }

    // Check if assignment is still open (considering late submission)
    const isLate = now > dueDate;
    if (isLate && !assignment.allow_late_submission) {
      return res.status(400).json({
        success: false,
        message: 'Assignment deadline has passed and late submission is not allowed',
        code: 'ASSIGNMENT_CLOSED'
      });
    }

    if (isLate && assignment.late_due_date) {
      const lateDueDate = new Date(assignment.late_due_date);
      if (now > lateDueDate) {
        return res.status(400).json({
          success: false,
          message: 'Late submission deadline has also passed',
          code: 'LATE_SUBMISSION_CLOSED'
        });
      }
    }

    // Check current submission count
    const { data: existingSubmissions } = await supabase
      .from('assignment_submissions')
      .select('id, attempt_number')
      .eq('assignment_id', assignmentId)
      .eq('student_id', studentId)
      .order('attempt_number', { ascending: false });

    const currentAttempts = existingSubmissions?.length || 0;
    if (currentAttempts >= assignment.max_attempts) {
      return res.status(400).json({
        success: false,
        message: `Maximum submission attempts (${assignment.max_attempts}) exceeded`,
        code: 'MAX_ATTEMPTS_EXCEEDED'
      });
    }

    const nextAttemptNumber = currentAttempts + 1;

    // Validate temp attachments if provided
    let tempAttachments = [];
    if (tempAttachmentIds && tempAttachmentIds.length > 0) {
      const { data: tempAtts, error: tempError } = await supabase
        .from('temp_attachments')
        .select('*')
        .in('temp_id', tempAttachmentIds)
        .eq('user_id', studentId)
        .eq('is_finalized', false)
        .eq('attachment_type', 'submission');

      if (tempError || !tempAtts || tempAtts.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Invalid or missing temporary attachments',
          code: 'INVALID_TEMP_ATTACHMENTS'
        });
      }

      tempAttachments = tempAtts;

      // Validate file formats
      if (assignment.file_formats && assignment.file_formats.length > 0) {
        const invalidFiles = tempAttachments.filter(att => {
          const fileExt = att.file_name.split('.').pop()?.toLowerCase();
          return !assignment.file_formats.includes(fileExt);
        });
        if (invalidFiles.length > 0) {
          return res.status(400).json({
            success: false,
            message: `Invalid file formats. Allowed: ${assignment.file_formats.join(', ')}`,
            code: 'INVALID_FILE_FORMAT'
          });
        }
      }

      // Validate file sizes
      const maxSizeBytes = (assignment.max_file_size || 10) * 1024 * 1024;
      const oversizedFiles = tempAttachments.filter(att => att.file_size > maxSizeBytes);
      if (oversizedFiles.length > 0) {
        return res.status(400).json({
          success: false,
          message: `Files exceed maximum size of ${assignment.max_file_size || 10}MB`,
          code: 'FILE_TOO_LARGE'
        });
      }
    }

    // Validate that at least text or files are provided
    if ((!submissionText || submissionText.trim().length === 0) && tempAttachments.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Either submission text or files must be provided',
        code: 'EMPTY_SUBMISSION'
      });
    }

    // Create submission
    const { data: newSubmission, error: submissionError } = await supabase
      .from('assignment_submissions')
      .insert({
        assignment_id: assignmentId,
        student_id: studentId,
        attempt_number: nextAttemptNumber,
        submission_text: submissionText?.trim(),
        submitted_at: now.toISOString(),
        is_late: isLate
      })
      .select(`
        id, assignment_id, student_id, attempt_number,
        submission_text, submitted_at, is_late, created_at
      `)
      .single();

    if (submissionError) {
      console.error('Submission creation error:', submissionError);
      throw new AppError('Failed to create submission', 500, 'SUBMISSION_CREATION_FAILED');
    }

    // Finalize temp attachments if provided
    const finalAttachments = [];
    if (tempAttachments.length > 0) {
      for (const tempAttachment of tempAttachments) {
        try {
          const sanitizedName = fileUploadService.sanitizeFilename(tempAttachment.file_name);
          const permanentPath = `submissions/${newSubmission.id}/${Date.now()}_${sanitizedName}`;
          const moveResult = await fileUploadService.moveFile(
            tempAttachment.file_path,
            permanentPath
          );

          if (!moveResult.success) {
            console.error(`Failed to move file ${tempAttachment.file_name}:`, moveResult.error);
            continue;
          }

          const { data: submissionAttachment, error: insertError } = await supabase
            .from('submission_attachments')
            .insert({
              submission_id: newSubmission.id,
              file_name: tempAttachment.file_name,
              file_url: moveResult.publicUrl || tempAttachment.file_url,
              file_size: tempAttachment.file_size,
              file_type: tempAttachment.file_type
            })
            .select('id, file_name, file_url, file_size, file_type, created_at')
            .single();

          if (insertError) {
            console.error('Insert submission attachment error:', insertError);
            continue;
          }

          await supabase
            .from('temp_attachments')
            .update({ is_finalized: true })
            .eq('id', tempAttachment.id);

          finalAttachments.push(submissionAttachment);
        } catch (error) {
          console.error(`Error processing temp attachment ${tempAttachment.temp_id}:`, error);
        }
      }

      // Clean up finalized temp attachments
      const processedTempIds = tempAttachments.map(t => t.id);
      if (processedTempIds.length > 0) {
        await supabase
          .from('temp_attachments')
          .delete()
          .in('id', processedTempIds);
      }
    }

    // Get complete submission with attachments
    const { data: completeSubmission } = await supabase
      .from('assignment_submissions')
      .select(`
        id, assignment_id, student_id, attempt_number,
        submission_text, submitted_at, is_late, created_at, updated_at,
        submission_attachments(id, file_name, file_url, file_size, file_type, created_at)
      `)
      .eq('id', newSubmission.id)
      .single();

    // Get student info for notification
    const { data: studentInfo, error: studentInfoError } = await supabase
      .from('users')
      .select('full_name')
      .eq('id', studentId)
      .single();

    // Create notification for instructor
    if (assignment.instructor_id && studentInfo) {
      try {
        console.log('[Assignment Submission] Creating notification for instructor:', assignment.instructor_id);
        const result = await notificationController.createNotification(assignment.instructor_id, {
          type: 'submission',
          title: 'New Assignment Submission',
          body: `${studentInfo.full_name} has submitted "${assignment.title}" (Attempt #${nextAttemptNumber}${isLate ? ' - Late' : ''})`,
          data: {
            assignmentId: assignmentId,
            assignmentTitle: assignment.title,
            submissionId: newSubmission.id,
            studentId: studentId,
            studentName: studentInfo.full_name,
            attemptNumber: nextAttemptNumber,
            isLate: isLate,
            action_url: `/assignments/${assignmentId}/submissions`
          }
        });
        console.log('[Assignment Submission] Notification creation result:', result);
      } catch (notificationError) {
        console.error('[Assignment Submission] Error creating notification:', notificationError);
        console.error('[Assignment Submission] Error stack:', notificationError.stack);
      }
    } else {
      if (!assignment.instructor_id) {
        console.error('[Assignment Submission] Assignment has no instructor_id:', assignment);
      }
      if (!studentInfo) {
        console.error('[Assignment Submission] Student info not found:', studentInfoError);
      }
    }

    const message = isLate 
      ? 'Assignment submitted successfully (late submission)' 
      : 'Assignment submitted successfully';

    res.status(201).json(buildResponse(true, message, {
      submission: completeSubmission
    }));
  });

  /**
   * Get student's submissions for an assignment
   */
  getStudentSubmissions = catchAsync(async (req, res) => {
    const { assignmentId } = req.params;
    const studentId = req.user.id;

    // Check if assignment exists and student has access
    const { data: assignment } = await supabase
      .from('assignments')
      .select(`
        id, title, due_date, late_due_date, allow_late_submission,
        max_attempts, start_date, is_active,
        assignment_groups!inner(
          groups!inner(
            student_enrollments!inner(student_id)
          )
        )
      `)
      .eq('id', assignmentId)
      .eq('is_active', true)
      .eq('assignment_groups.groups.student_enrollments.student_id', studentId)
      .single();

    if (!assignment) {
      throw new AppError('Assignment not found or access denied', 404, 'ASSIGNMENT_NOT_FOUND');
    }

    // Get student's submissions
    const { data: submissions } = await supabase
      .from('assignment_submissions')
      .select(`
        id, attempt_number, submission_text, submitted_at, is_late,
        grade, feedback, graded_at, created_at,
        submission_attachments(id, file_name, file_url, file_size, file_type)
      `)
      .eq('assignment_id', assignmentId)
      .eq('student_id', studentId)
      .order('attempt_number', { ascending: true });

    res.json({
      success: true,
      data: {
        assignment: {
          id: assignment.id,
          title: assignment.title,
          dueDate: assignment.due_date,
          lateDueDate: assignment.late_due_date,
          allowLateSubmission: assignment.allow_late_submission,
          maxAttempts: assignment.max_attempts,
          startDate: assignment.start_date,
          isActive: assignment.is_active
        },
        submissions: submissions || [],
        currentAttempts: submissions?.length || 0,
        remainingAttempts: Math.max(0, assignment.max_attempts - (submissions?.length || 0))
      }
    });
  });

  /**
   * Get student's all submissions across all assignments
   */
  getStudentAllSubmissions = catchAsync(async (req, res) => {
    const {
      page = 1,
      limit = 20,
      search = '',
      status = 'all', // all, submitted, graded, pending
      sortBy = 'submitted_at',
      sortOrder = 'desc'
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);
    const studentId = req.user.id;

    // Build query
    let query = supabase
      .from('assignment_submissions')
      .select(`
        id, assignment_id, attempt_number, submission_text,
        submitted_at, is_late, grade, feedback, graded_at,
        created_at, updated_at,
        assignments!inner(
          id, title, due_date, late_due_date, allow_late_submission,
          courses!inner(code, name)
        )
      `, { count: 'exact' })
      .eq('student_id', studentId);

    // Apply search filter
    if (search.trim()) {
      query = query.or(`
        assignments.title.ilike.%${search}%,
        assignments.courses.code.ilike.%${search}%,
        assignments.courses.name.ilike.%${search}%
      `);
    }

    // Apply status filter
    if (status === 'submitted') {
      query = query.not('submitted_at', 'is', null);
    } else if (status === 'graded') {
      query = query.not('grade', 'is', null);
    } else if (status === 'pending') {
      query = query.is('grade', null);
    }

    // Apply sorting
    query = query.order(sortBy, { ascending: sortOrder === 'asc' });

    // Apply pagination
    query = query.range(offset, offset + parseInt(limit) - 1);

    const { data: submissions, error, count } = await query;

    if (error) {
      console.error('Get student submissions error:', error);
      throw new AppError('Failed to fetch submissions', 500, 'GET_SUBMISSIONS_FAILED');
    }

    res.json({
      success: true,
      data: {
        submissions: submissions || [],
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
   * Update submission (if allowed)
   */
  updateSubmission = catchAsync(async (req, res) => {
    const { submissionId } = req.params;
    const { submissionText, attachments } = req.body;
    const studentId = req.user.id;

    // Check if submission exists and belongs to student
    const { data: existingSubmission } = await supabase
      .from('assignment_submissions')
      .select(`
        id, assignment_id, student_id, submitted_at, grade,
        assignments!inner(due_date, late_due_date, allow_late_submission)
      `)
      .eq('id', submissionId)
      .eq('student_id', studentId)
      .single();

    if (!existingSubmission) {
      throw new AppError('Submission not found or access denied', 404, 'SUBMISSION_NOT_FOUND');
    }

    // Check if submission can be updated (not graded and within time limit)
    if (existingSubmission.grade !== null) {
      return res.status(400).json({
        success: false,
        message: 'Cannot update graded submission',
        code: 'SUBMISSION_ALREADY_GRADED'
      });
    }

    const now = new Date();
    const dueDate = new Date(existingSubmission.assignments.due_date);
    const lateDueDate = existingSubmission.assignments.late_due_date 
      ? new Date(existingSubmission.assignments.late_due_date) 
      : null;

    // Check if still within submission window
    const isLate = now > dueDate;
    if (isLate && !existingSubmission.assignments.allow_late_submission) {
      return res.status(400).json({
        success: false,
        message: 'Cannot update submission after deadline',
        code: 'SUBMISSION_DEADLINE_PASSED'
      });
    }

    if (isLate && lateDueDate && now > lateDueDate) {
      return res.status(400).json({
        success: false,
        message: 'Cannot update submission after late deadline',
        code: 'LATE_SUBMISSION_DEADLINE_PASSED'
      });
    }

    // Update submission
    const { data: updatedSubmission, error } = await supabase
      .from('assignment_submissions')
      .update({
        submission_text: submissionText?.trim(),
        updated_at: now.toISOString()
      })
      .eq('id', submissionId)
      .select(`
        id, assignment_id, student_id, attempt_number,
        submission_text, submitted_at, is_late, updated_at
      `)
      .single();

    if (error) {
      console.error('Update submission error:', error);
      throw new AppError('Failed to update submission', 500, 'UPDATE_SUBMISSION_FAILED');
    }

    // Update attachments if provided
    if (attachments !== undefined) {
      // Delete existing attachments
      await supabase
        .from('submission_attachments')
        .delete()
        .eq('submission_id', submissionId);

      // Insert new attachments
      if (attachments && attachments.length > 0) {
        const submissionAttachments = attachments.map(attachment => ({
          submission_id: submissionId,
          file_name: attachment.fileName,
          file_url: attachment.fileUrl,
          file_size: attachment.fileSize,
          file_type: attachment.fileType
        }));

        const { error: attachmentsError } = await supabase
          .from('submission_attachments')
          .insert(submissionAttachments);

        if (attachmentsError) {
          console.error('Update submission attachments error:', attachmentsError);
          throw new AppError('Failed to update submission attachments', 500, 'ATTACHMENTS_UPDATE_FAILED');
        }
      }
    }

    res.json({
      success: true,
      message: 'Submission updated successfully',
      data: {
        submission: updatedSubmission
      }
    });
  });

  /**
   * Delete submission (if allowed)
   */
  deleteSubmission = catchAsync(async (req, res) => {
    const { submissionId } = req.params;
    const studentId = req.user.id;

    // Check if submission exists and belongs to student
    const { data: existingSubmission } = await supabase
      .from('assignment_submissions')
      .select(`
        id, assignment_id, student_id, grade,
        assignments!inner(due_date, late_due_date, allow_late_submission)
      `)
      .eq('id', submissionId)
      .eq('student_id', studentId)
      .single();

    if (!existingSubmission) {
      throw new AppError('Submission not found or access denied', 404, 'SUBMISSION_NOT_FOUND');
    }

    // Check if submission can be deleted (not graded and within time limit)
    if (existingSubmission.grade !== null) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete graded submission',
        code: 'SUBMISSION_ALREADY_GRADED'
      });
    }

    const now = new Date();
    const dueDate = new Date(existingSubmission.assignments.due_date);
    const lateDueDate = existingSubmission.assignments.late_due_date 
      ? new Date(existingSubmission.assignments.late_due_date) 
      : null;

    // Check if still within submission window
    const isLate = now > dueDate;
    if (isLate && !existingSubmission.assignments.allow_late_submission) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete submission after deadline',
        code: 'SUBMISSION_DEADLINE_PASSED'
      });
    }

    if (isLate && lateDueDate && now > lateDueDate) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete submission after late deadline',
        code: 'LATE_SUBMISSION_DEADLINE_PASSED'
      });
    }

    // Delete submission (cascade will handle attachments)
    const { error } = await supabase
      .from('assignment_submissions')
      .delete()
      .eq('id', submissionId);

    if (error) {
      console.error('Delete submission error:', error);
      throw new AppError('Failed to delete submission', 500, 'DELETE_SUBMISSION_FAILED');
    }

    res.json({
      success: true,
      message: 'Submission deleted successfully'
    });
  });
}

module.exports = new SubmissionController();
