const Joi = require('joi');

const VIETNAMESE_NAME_REGEX = /^[A-Za-zÀ-ỹ0-9\s]{2,50}$/;
const USERNAME_REGEX = /^[a-zA-Z0-9_]{3,30}$/;

const createStudentSchema = Joi.object({
  username: Joi.string().pattern(USERNAME_REGEX).min(3).max(30).required().messages({
    'string.pattern.base': 'Username can only contain letters, numbers, and underscores',
    'string.min': 'Username must be at least 3 characters',
    'string.max': 'Username cannot exceed 30 characters',
    'any.required': 'Username is required'
  }),
  password: Joi.string().min(6).max(50).required().messages({
    'string.min': 'Password must be at least 6 characters',
    'string.max': 'Password cannot exceed 50 characters',
    'any.required': 'Password is required'
  }),
  email: Joi.string().email().max(255).required().messages({
    'string.email': 'Please provide a valid email address',
    'string.max': 'Email cannot exceed 255 characters',
    'any.required': 'Email is required'
  }),
  fullName: Joi.string().pattern(VIETNAMESE_NAME_REGEX).min(2).max(50).required().messages({
    'string.pattern.base': 'Full name can only contain Vietnamese letters and spaces',
    'string.min': 'Full name must be at least 2 characters',
    'string.max': 'Full name cannot exceed 50 characters',
    'any.required': 'Full name is required'
  })
});

const updateStudentSchema = Joi.object({
  email: Joi.string().email().max(255).optional().messages({
    'string.email': 'Please provide a valid email address',
    'string.max': 'Email cannot exceed 255 characters'
  }),
  fullName: Joi.string().pattern(VIETNAMESE_NAME_REGEX).min(2).max(50).optional().messages({
    'string.pattern.base': 'Full name can only contain Vietnamese letters and spaces',
    'string.min': 'Full name must be at least 2 characters',
    'string.max': 'Full name cannot exceed 50 characters'
  }),
  isActive: Joi.boolean().optional()
}).min(1).messages({ 'object.min': 'At least one field must be provided for update' });

const bulkOperationSchema = Joi.object({
  studentIds: Joi.array().items(Joi.string().uuid()).min(1).max(100).required().messages({
    'array.min': 'At least one student must be selected',
    'array.max': 'Cannot perform bulk operations on more than 100 students at once',
    'any.required': 'Student IDs are required'
  }),
  action: Joi.string().valid('activate', 'deactivate', 'delete').required().messages({
    'any.only': 'Action must be one of: activate, deactivate, delete',
    'any.required': 'Action is required'
  }),
  data: Joi.object().optional()
});

module.exports = { createStudentSchema, updateStudentSchema, bulkOperationSchema };

