const Joi = require('joi');

const loginSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(50).required().messages({
    'string.alphanum': 'Username must only contain alphanumeric characters',
    'string.min': 'Username must be at least 3 characters long',
    'string.max': 'Username cannot exceed 50 characters',
    'any.required': 'Username is required'
  }),
  password: Joi.string().max(100).required().messages({
    'string.max': 'Password cannot exceed 100 characters',
    'any.required': 'Password is required'
  })
});

const createUserSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(50).required().messages({
    'string.alphanum': 'Username must only contain alphanumeric characters',
    'string.min': 'Username must be at least 3 characters long',
    'string.max': 'Username cannot exceed 50 characters',
    'any.required': 'Username is required'
  }),
  password: Joi.string().max(100).required().messages({
    'string.max': 'Password cannot exceed 100 characters',
    'any.required': 'Password is required'
  }),
  email: Joi.string().email().max(255).required().messages({
    'string.email': 'Please provide a valid email address',
    'string.max': 'Email cannot exceed 255 characters',
    'any.required': 'Email is required'
  }),
  fullName: Joi.string().min(2).max(50).required().messages({
    'string.min': 'Full name must be at least 2 characters long',
    'string.max': 'Full name cannot exceed 50 characters',
    'any.required': 'Full name is required'
  })
});

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required().messages({ 'any.required': 'Refresh token is required' })
});

module.exports = { loginSchema, createUserSchema, refreshTokenSchema };

