/**
 * Assignment model and validation
 */

const Joi = require('joi');

// Assignment creation schema
const createAssignmentSchema = Joi.object({
  title: Joi.string()
    .min(2)
    .max(255)
    .required()
    .messages({
      'string.min': 'Assignment title must be at least 2 characters',
      'string.max': 'Assignment title cannot exceed 255 characters',
      'any.required': 'Assignment title is required'
    }),
  
  description: Joi.string()
    .max(5000)
    .optional()
    .allow('')
    .messages({
      'string.max': 'Description cannot exceed 5000 characters'
    }),
  
  courseId: Joi.string()
    .uuid()
    .required()
    .messages({
      'string.uuid': 'Course ID must be a valid UUID',
      'any.required': 'Course ID is required'
    }),
  
  startDate: Joi.date()
    .iso()
    .required()
    .messages({
      'date.format': 'Start date must be a valid ISO date',
      'any.required': 'Start date is required'
    }),
  
  dueDate: Joi.date()
    .iso()
    .min(Joi.ref('startDate'))
    .required()
    .messages({
      'date.format': 'Due date must be a valid ISO date',
      'date.min': 'Due date must be after start date',
      'any.required': 'Due date is required'
    }),
  
  lateDueDate: Joi.date()
    .iso()
    .min(Joi.ref('dueDate'))
    .optional()
    .allow(null)
    .messages({
      'date.format': 'Late due date must be a valid ISO date',
      'date.min': 'Late due date must be after due date'
    }),
  
  allowLateSubmission: Joi.boolean()
    .optional()
    .default(false),
  
  maxAttempts: Joi.number()
    .integer()
    .min(1)
    .max(10)
    .optional()
    .default(1)
    .messages({
      'number.min': 'Max attempts must be at least 1',
      'number.max': 'Max attempts cannot exceed 10'
    }),
  
  fileFormats: Joi.array()
    .items(Joi.string().valid('pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'zip', 'rar'))
    .optional()
    .default([])
    .messages({
      'array.includes': 'Invalid file format. Allowed formats: pdf, doc, docx, txt, jpg, jpeg, png, zip, rar'
    }),
  
  maxFileSize: Joi.number()
    .integer()
    .min(1)
    .max(100)
    .optional()
    .default(10)
    .messages({
      'number.min': 'Max file size must be at least 1 MB',
      'number.max': 'Max file size cannot exceed 100 MB'
    }),
  
  groupIds: Joi.array()
    .items(Joi.string().uuid())
    .min(1)
    .optional()
    .messages({
      'array.min': 'At least one group must be selected',
      'string.uuid': 'Group ID must be a valid UUID'
    })
});

// Assignment update schema
const updateAssignmentSchema = Joi.object({
  title: Joi.string()
    .min(2)
    .max(255)
    .optional()
    .messages({
      'string.min': 'Assignment title must be at least 2 characters',
      'string.max': 'Assignment title cannot exceed 255 characters'
    }),
  
  description: Joi.string()
    .max(5000)
    .optional()
    .allow('')
    .messages({
      'string.max': 'Description cannot exceed 5000 characters'
    }),
  
  startDate: Joi.date()
    .iso()
    .optional()
    .messages({
      'date.format': 'Start date must be a valid ISO date'
    }),
  
  dueDate: Joi.date()
    .iso()
    .optional()
    .messages({
      'date.format': 'Due date must be a valid ISO date'
    }),
  
  lateDueDate: Joi.date()
    .iso()
    .optional()
    .messages({
      'date.format': 'Late due date must be a valid ISO date'
    }),
  
  allowLateSubmission: Joi.boolean()
    .optional(),
  
  maxAttempts: Joi.number()
    .integer()
    .min(1)
    .max(10)
    .optional()
    .messages({
      'number.min': 'Max attempts must be at least 1',
      'number.max': 'Max attempts cannot exceed 10'
    }),
  
  fileFormats: Joi.array()
    .items(Joi.string().valid('pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'zip', 'rar'))
    .optional()
    .messages({
      'array.includes': 'Invalid file format. Allowed formats: pdf, doc, docx, txt, jpg, jpeg, png, zip, rar'
    }),
  
  maxFileSize: Joi.number()
    .integer()
    .min(1)
    .max(100)
    .optional()
    .messages({
      'number.min': 'Max file size must be at least 1 MB',
      'number.max': 'Max file size cannot exceed 100 MB'
    }),
  
  isActive: Joi.boolean()
    .optional()
}).min(1).messages({
  'object.min': 'At least one field must be provided for update'
});

// Submission creation schema
const createSubmissionSchema = Joi.object({
  assignmentId: Joi.string()
    .uuid()
    .required()
    .messages({
      'string.uuid': 'Assignment ID must be a valid UUID',
      'any.required': 'Assignment ID is required'
    }),
  
  submissionText: Joi.string()
    .max(5000)
    .optional()
    .allow('')
    .messages({
      'string.max': 'Submission text cannot exceed 5000 characters'
    }),
  
  attachments: Joi.array()
    .items(Joi.object({
      fileName: Joi.string().required(),
      fileUrl: Joi.string().uri().required(),
      fileSize: Joi.number().integer().min(1).required(),
      fileType: Joi.string().required()
    }))
    .optional()
    .default([])
    .messages({
      'array.items': 'Invalid attachment format'
    })
});

// Grade submission schema
const gradeSubmissionSchema = Joi.object({
  grade: Joi.number()
    .min(0)
    .max(100)
    .required()
    .messages({
      'number.min': 'Grade must be at least 0',
      'number.max': 'Grade must not exceed 100',
      'any.required': 'Grade is required'
    }),
  
  feedback: Joi.string()
    .max(2000)
    .optional()
    .allow('')
    .messages({
      'string.max': 'Feedback cannot exceed 2000 characters'
    })
});

/**
 * Validate assignment creation
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: Object[], data?: Object}}
 */
function validateAssignmentCreation(data) {
  const { error, value } = createAssignmentSchema.validate(data, { 
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    return {
      isValid: false,
      errors: error.details.map(detail => ({
        field: detail.path[0],
        message: detail.message
      }))
    };
  }

  return {
    isValid: true,
    data: value
  };
}

/**
 * Validate assignment update
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: Object[], data?: Object}}
 */
function validateAssignmentUpdate(data) {
  const { error, value } = updateAssignmentSchema.validate(data, { 
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    return {
      isValid: false,
      errors: error.details.map(detail => ({
        field: detail.path[0],
        message: detail.message
      }))
    };
  }

  return {
    isValid: true,
    data: value
  };
}

/**
 * Validate submission creation
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: Object[], data?: Object}}
 */
function validateSubmissionCreation(data) {
  const { error, value } = createSubmissionSchema.validate(data, { 
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    return {
      isValid: false,
      errors: error.details.map(detail => ({
        field: detail.path[0],
        message: detail.message
      }))
    };
  }

  return {
    isValid: true,
    data: value
  };
}

/**
 * Validate grade submission
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: Object[], data?: Object}}
 */
function validateGradeSubmission(data) {
  const { error, value } = gradeSubmissionSchema.validate(data, { 
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    return {
      isValid: false,
      errors: error.details.map(detail => ({
        field: detail.path[0],
        message: detail.message
      }))
    };
  }

  return {
    isValid: true,
    data: value
  };
}

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
  validateAssignmentCreation,
  validateAssignmentUpdate,
  validateSubmissionCreation,
  validateGradeSubmission,
  validateFileUpload,
  calculateSubmissionStatus,
  formatAssignmentResponse
};
