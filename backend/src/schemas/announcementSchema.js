const Joi = require('joi');

/**
 * Validation schemas for announcement operations
 */

// Create announcement schema
const createAnnouncementSchema = Joi.object({
  title: Joi.string()
    .min(2)
    .max(200)
    .required()
    .messages({
      'string.min': 'Title must be at least 2 characters long',
      'string.max': 'Title must not exceed 200 characters',
      'any.required': 'Title is required'
    }),
  
  content: Joi.string()
    .min(10)
    .required()
    .messages({
      'string.min': 'Content must be at least 10 characters long',
      'any.required': 'Content is required'
    }),
  
  courseId: Joi.string()
    .uuid()
    .required()
    .messages({
      'string.guid': 'Course ID must be a valid UUID',
      'any.required': 'Course ID is required'
    }),
  
  scopeType: Joi.string()
    .valid('one_group', 'multiple_groups', 'all_groups')
    .required()
    .messages({
      'any.only': 'Scope type must be one of: one_group, multiple_groups, all_groups',
      'any.required': 'Scope type is required'
    }),
  
  groupIds: Joi.array()
    .items(Joi.string().uuid())
    .when('scopeType', {
      is: 'one_group',
      then: Joi.array().length(1).required(),
      otherwise: Joi.array().optional()
    })
    .messages({
      'array.length': 'One group scope requires exactly one group ID',
      'string.guid': 'Group ID must be a valid UUID'
    }),
  
  attachmentIds: Joi.array()
    .items(Joi.string().uuid())
    .max(5)
    .optional()
    .messages({
      'array.max': 'Maximum 5 attachments allowed'
    })
});

// Update announcement schema
const updateAnnouncementSchema = Joi.object({
  title: Joi.string()
    .min(2)
    .max(200)
    .optional()
    .messages({
      'string.min': 'Title must be at least 2 characters long',
      'string.max': 'Title must not exceed 200 characters'
    }),
  
  content: Joi.string()
    .min(10)
    .optional()
    .messages({
      'string.min': 'Content must be at least 10 characters long'
    }),
  
  attachmentIds: Joi.array()
    .items(Joi.string().uuid())
    .max(5)
    .optional()
    .messages({
      'array.max': 'Maximum 5 attachments allowed'
    })
});

// Add comment schema
const addCommentSchema = Joi.object({
  commentText: Joi.string()
    .min(1)
    .max(500)
    .required()
    .messages({
      'string.min': 'Comment must not be empty',
      'string.max': 'Comment must not exceed 500 characters',
      'any.required': 'Comment text is required'
    }),
  
  parentCommentId: Joi.string()
    .uuid()
    .optional()
    .messages({
      'string.guid': 'Parent comment ID must be a valid UUID'
    })
});

// Get announcements query schema
const getAnnouncementsQuerySchema = Joi.object({
  page: Joi.number()
    .integer()
    .min(1)
    .default(1)
    .messages({
      'number.base': 'Page must be a number',
      'number.integer': 'Page must be an integer',
      'number.min': 'Page must be at least 1'
    }),
  
  limit: Joi.number()
    .integer()
    .min(1)
    .max(100)
    .default(20)
    .messages({
      'number.base': 'Limit must be a number',
      'number.integer': 'Limit must be an integer',
      'number.min': 'Limit must be at least 1',
      'number.max': 'Limit must not exceed 100'
    }),
  
  search: Joi.string()
    .max(100)
    .optional()
    .messages({
      'string.max': 'Search term must not exceed 100 characters'
    }),
  
  courseId: Joi.string()
    .uuid()
    .optional()
    .messages({
      'string.guid': 'Course ID must be a valid UUID'
    }),
  
  scopeType: Joi.string()
    .valid('one_group', 'multiple_groups', 'all_groups')
    .optional()
    .messages({
      'any.only': 'Scope type must be one of: one_group, multiple_groups, all_groups'
    }),
  
  sortBy: Joi.string()
    .valid('published_at', 'title', 'updated_at')
    .default('published_at')
    .messages({
      'any.only': 'Sort by must be one of: published_at, title, updated_at'
    }),
  
  sortOrder: Joi.string()
    .valid('asc', 'desc')
    .default('desc')
    .messages({
      'any.only': 'Sort order must be asc or desc'
    })
});

// Get comments query schema
const getCommentsQuerySchema = Joi.object({
  page: Joi.number()
    .integer()
    .min(1)
    .default(1)
    .messages({
      'number.base': 'Page must be a number',
      'number.integer': 'Page must be an integer',
      'number.min': 'Page must be at least 1'
    }),
  
  limit: Joi.number()
    .integer()
    .min(1)
    .max(50)
    .default(20)
    .messages({
      'number.base': 'Limit must be a number',
      'number.integer': 'Limit must be an integer',
      'number.min': 'Limit must be at least 1',
      'number.max': 'Limit must not exceed 50'
    })
});

// Get tracking query schema
const getTrackingQuerySchema = Joi.object({
  groupId: Joi.string()
    .uuid()
    .optional()
    .messages({
      'string.guid': 'Group ID must be a valid UUID'
    }),
  
  status: Joi.string()
    .valid('all', 'viewed', 'not_viewed')
    .default('all')
    .messages({
      'any.only': 'Status must be one of: all, viewed, not_viewed'
    })
});

// Get file tracking query schema
const getFileTrackingQuerySchema = Joi.object({
  fileId: Joi.string()
    .uuid()
    .optional()
    .messages({
      'string.guid': 'File ID must be a valid UUID'
    })
});

/**
 * Validate request data against schema
 */
function validateAnnouncementData(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.body, { 
      abortEarly: false,
      stripUnknown: true 
    });
    
    if (error) {
      const errorMessages = error.details.map(detail => detail.message);
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errorMessages
      });
    }
    
    req.body = value;
    next();
  };
}

/**
 * Validate query parameters against schema
 */
function validateAnnouncementQuery(schema) {
  return (req, res, next) => {
    const { error, value } = schema.validate(req.query, { 
      abortEarly: false,
      stripUnknown: true 
    });
    
    if (error) {
      const errorMessages = error.details.map(detail => detail.message);
      return res.status(400).json({
        success: false,
        message: 'Query validation failed',
        errors: errorMessages
      });
    }
    
    req.query = value;
    next();
  };
}

module.exports = {
  createAnnouncementSchema,
  updateAnnouncementSchema,
  addCommentSchema,
  getAnnouncementsQuerySchema,
  getCommentsQuerySchema,
  getTrackingQuerySchema,
  getFileTrackingQuerySchema,
  validateAnnouncementData,
  validateAnnouncementQuery
};
