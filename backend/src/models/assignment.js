/**
 * Assignment model and validation
 */

const Joi = require('joi');

/**
 * Validate file upload
 * @param {Object} file - File object to validate
 * @param {Array} allowedFormats - Allowed file formats
 * @param {number} maxSize - Maximum file size in MB
 * @returns {{isValid: boolean, error?: string}}
 */
function validateFileUpload(file, allowedFormats = [], maxSize = 10) {
  if (!file) {
    return { isValid: false, error: 'No file provided' };
  }

  // Check file size
  const fileSizeMB = file.size / (1024 * 1024);
  if (fileSizeMB > maxSize) {
    return { 
      isValid: false, 
      error: `File size exceeds maximum allowed size of ${maxSize}MB` 
    };
  }

  // Check file format
  if (allowedFormats.length > 0) {
    const fileExtension = file.name.split('.').pop().toLowerCase();
    if (!allowedFormats.includes(fileExtension)) {
      return { 
        isValid: false, 
        error: `File format not allowed. Allowed formats: ${allowedFormats.join(', ')}` 
      };
    }
  }

  return { isValid: true };
}

/**
 * Calculate submission status
 * @param {Date} submittedAt - Submission timestamp
 * @param {Date} dueDate - Assignment due date
 * @param {Date} lateDueDate - Late submission due date
 * @param {boolean} allowLateSubmission - Whether late submission is allowed
 * @returns {string} - Status: 'on_time', 'late', 'too_late'
 */
function calculateSubmissionStatus(submittedAt, dueDate, lateDueDate, allowLateSubmission) {
  const submitted = new Date(submittedAt);
  const due = new Date(dueDate);
  
  if (submitted <= due) {
    return 'on_time';
  }
  
  if (allowLateSubmission && lateDueDate) {
    const lateDue = new Date(lateDueDate);
    if (submitted <= lateDue) {
      return 'late';
    }
  }
  
  return 'too_late';
}

/**
 * Format assignment data for response
 * @param {Object} assignment - Assignment data from database
 * @returns {Object} - Formatted assignment data
 */
function formatAssignmentResponse(assignment) {
  return {
    id: assignment.id,
    title: assignment.title,
    description: assignment.description,
    courseId: assignment.course_id,
    instructorId: assignment.instructor_id,
    startDate: assignment.start_date,
    dueDate: assignment.due_date,
    lateDueDate: assignment.late_due_date,
    allowLateSubmission: assignment.allow_late_submission,
    maxAttempts: assignment.max_attempts,
    fileFormats: assignment.file_formats,
    maxFileSize: assignment.max_file_size,
    isActive: assignment.is_active,
    createdAt: assignment.created_at,
    updatedAt: assignment.updated_at,
    course: assignment.courses,
    instructor: assignment.users
  };
}

module.exports = {
  validateFileUpload,
  calculateSubmissionStatus,
  formatAssignmentResponse
};
