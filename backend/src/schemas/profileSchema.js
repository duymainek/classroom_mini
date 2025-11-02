const Joi = require('joi');

const VIETNAMESE_NAME_REGEX = /^[A-Za-zÀ-ỹ0-9\s]{2,50}$/;

const updateProfileSchema = Joi.object({
  full_name: Joi.string()
    .pattern(VIETNAMESE_NAME_REGEX)
    .min(2)
    .max(50)
    .optional()
    .messages({
      'string.pattern.base': 'Full name can only contain Vietnamese letters and spaces',
      'string.min': 'Full name must be at least 2 characters',
      'string.max': 'Full name cannot exceed 50 characters'
    }),
  email: Joi.string().email().max(255).optional().messages({
    'string.email': 'Please provide a valid email address',
    'string.max': 'Email cannot exceed 255 characters'
  })
}).min(1).messages({ 'object.min': 'At least one field must be provided for update' });

module.exports = { updateProfileSchema };


