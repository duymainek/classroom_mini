/**
 * Group model and validation
 */

const Joi = require('joi');

// Group creation schema
const createGroupSchema = Joi.object({
  name: Joi.string()
    .min(2)
    .max(100)
    .required()
    .messages({
      'string.min': 'Group name must be at least 2 characters',
      'string.max': 'Group name cannot exceed 100 characters',
      'any.required': 'Group name is required'
    }),
  
  courseId: Joi.string()
    .uuid()
    .required()
    .messages({
      'string.uuid': 'Course ID must be a valid UUID',
      'any.required': 'Course ID is required'
    })
});

// Group update schema
const updateGroupSchema = Joi.object({
  name: Joi.string()
    .min(2)
    .max(100)
    .optional()
    .messages({
      'string.min': 'Group name must be at least 2 characters',
      'string.max': 'Group name cannot exceed 100 characters'
    }),
  
  courseId: Joi.string()
    .uuid()
    .optional()
    .messages({
      'string.uuid': 'Course ID must be a valid UUID'
    }),
  
  isActive: Joi.boolean()
    .optional()
}).min(1).messages({
  'object.min': 'At least one field must be provided for update'
});

/**
 * Validate group creation
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateGroupCreation(data) {
  const { error, value } = createGroupSchema.validate(data, { 
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
 * Validate group update
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateGroupUpdate(data) {
  const { error, value } = updateGroupSchema.validate(data, { 
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
  validateGroupCreation,
  validateGroupUpdate
};