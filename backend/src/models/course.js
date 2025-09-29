/**
 * Course model and validation
 */

const Joi = require('joi');

// Course creation schema
const createCourseSchema = Joi.object({
  code: Joi.string()
    .min(2)
    .max(20)
    .required()
    .messages({
      'string.min': 'Course code must be at least 2 characters',
      'string.max': 'Course code cannot exceed 20 characters',
      'any.required': 'Course code is required'
    }),
  
  name: Joi.string()
    .min(2)
    .max(100)
    .required()
    .messages({
      'string.min': 'Course name must be at least 2 characters',
      'string.max': 'Course name cannot exceed 100 characters',
      'any.required': 'Course name is required'
    }),
  
  sessionCount: Joi.number()
    .integer()
    .valid(10, 15)
    .required()
    .messages({
      'any.only': 'Session count must be either 10 or 15',
      'any.required': 'Session count is required'
    }),
  
  semesterId: Joi.string()
    .uuid()
    .required()
    .messages({
      'string.uuid': 'Semester ID must be a valid UUID',
      'any.required': 'Semester ID is required'
    })
});

// Course update schema
const updateCourseSchema = Joi.object({
  code: Joi.string()
    .min(2)
    .max(20)
    .optional()
    .messages({
      'string.min': 'Course code must be at least 2 characters',
      'string.max': 'Course code cannot exceed 20 characters'
    }),
  
  name: Joi.string()
    .min(2)
    .max(100)
    .optional()
    .messages({
      'string.min': 'Course name must be at least 2 characters',
      'string.max': 'Course name cannot exceed 100 characters'
    }),
  
  sessionCount: Joi.number()
    .integer()
    .valid(10, 15)
    .optional()
    .messages({
      'any.only': 'Session count must be either 10 or 15'
    }),
  
  semesterId: Joi.string()
    .uuid()
    .optional()
    .messages({
      'string.uuid': 'Semester ID must be a valid UUID'
    }),
  
  isActive: Joi.boolean()
    .optional()
}).min(1).messages({
  'object.min': 'At least one field must be provided for update'
});

/**
 * Validate course creation
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateCourseCreation(data) {
  const { error, value } = createCourseSchema.validate(data, { 
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
 * Validate course update
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateCourseUpdate(data) {
  const { error, value } = updateCourseSchema.validate(data, { 
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

module.exports = {
  validateCourseCreation,
  validateCourseUpdate
};