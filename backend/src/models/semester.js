/**
 * Semester model and validation
 */

const Joi = require('joi');

// Semester creation schema
const createSemesterSchema = Joi.object({
  code: Joi.string()
    .min(2)
    .max(20)
    .required()
    .messages({
      'string.min': 'Semester code must be at least 2 characters',
      'string.max': 'Semester code cannot exceed 20 characters',
      'any.required': 'Semester code is required'
    }),
  
  name: Joi.string()
    .min(2)
    .max(100)
    .required()
    .messages({
      'string.min': 'Semester name must be at least 2 characters',
      'string.max': 'Semester name cannot exceed 100 characters',
      'any.required': 'Semester name is required'
    })
});

// Semester update schema
const updateSemesterSchema = Joi.object({
  code: Joi.string()
    .min(2)
    .max(20)
    .optional()
    .messages({
      'string.min': 'Semester code must be at least 2 characters',
      'string.max': 'Semester code cannot exceed 20 characters'
    }),
  
  name: Joi.string()
    .min(2)
    .max(100)
    .optional()
    .messages({
      'string.min': 'Semester name must be at least 2 characters',
      'string.max': 'Semester name cannot exceed 100 characters'
    }),
  
  isActive: Joi.boolean()
    .optional()
}).min(1).messages({
  'object.min': 'At least one field must be provided for update'
});

/**
 * Validate semester creation
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateSemesterCreation(data) {
  const { error, value } = createSemesterSchema.validate(data, { 
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
 * Validate semester update
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateSemesterUpdate(data) {
  const { error, value } = updateSemesterSchema.validate(data, { 
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
  validateSemesterCreation,
  validateSemesterUpdate
};