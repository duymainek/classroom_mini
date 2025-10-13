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
    }),

  attachmentIds: Joi.array()
    .items(Joi.string().uuid())
    .optional()
    .default([])
    .messages({
      'array.items': 'Invalid attachment ID format',
      'string.uuid': 'Attachment ID must be a valid UUID'
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
    .optional(),
    
  attachmentIds: Joi.array()
    .items(Joi.string().uuid())
    .optional()
    .messages({
      'array.items': 'Invalid attachment ID format',
      'string.uuid': 'Attachment ID must be a valid UUID'
    })
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

module.exports = {
  createAssignmentSchema,
  updateAssignmentSchema,
  createSubmissionSchema,
  gradeSubmissionSchema
};