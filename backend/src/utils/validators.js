const Joi = require('joi');

// Vietnamese name validation regex
const VIETNAMESE_NAME_REGEX = /^[A-Za-zÀ-ỹ0-9\s]{2,50}$/;
const USERNAME_REGEX = /^[a-zA-Z0-9_]{3,30}$/;

// Schema definitions
const loginSchema = Joi.object({
  username: Joi.string()
    .alphanum()
    .min(3)
    .max(50)
    .required()
    .messages({
      'string.alphanum': 'Username must only contain alphanumeric characters',
      'string.min': 'Username must be at least 3 characters long',
      'string.max': 'Username cannot exceed 50 characters',
      'any.required': 'Username is required'
    }),
  
  password: Joi.string()
    .max(100)
    .required()
    .messages({
      'string.max': 'Password cannot exceed 100 characters',
      'any.required': 'Password is required'
    })
});

const createUserSchema = Joi.object({
  username: Joi.string()
    .alphanum()
    .min(3)
    .max(50)
    .required()
    .messages({
      'string.alphanum': 'Username must only contain alphanumeric characters',
      'string.min': 'Username must be at least 3 characters long',
      'string.max': 'Username cannot exceed 50 characters',
      'any.required': 'Username is required'
    }),
  
  password: Joi.string()
    .max(100)
    .required()
    .messages({
      'string.max': 'Password cannot exceed 100 characters',
      'any.required': 'Password is required'
    }),
  
  email: Joi.string()
    .email()
    .max(255)
    .required()
    .messages({
      'string.email': 'Please provide a valid email address',
      'string.max': 'Email cannot exceed 255 characters',
      'any.required': 'Email is required'
    }),
  
  fullName: Joi.string()
    .min(2)
    .max(50)
    .required()
    .pattern(VIETNAMESE_NAME_REGEX)
    .messages({
      'string.min': 'Full name must be at least 2 characters long',
      'string.max': 'Full name cannot exceed 50 characters',
      'string.pattern.base': 'Full name can only contain Vietnamese letters and spaces',
      'any.required': 'Full name is required'
    })
});

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string()
    .required()
    .messages({
      'any.required': 'Refresh token is required'
    })
});

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
  email: Joi.string()
    .email()
    .max(255)
    .optional()
    .messages({
      'string.email': 'Please provide a valid email address',
      'string.max': 'Email cannot exceed 255 characters'
    }),
}).min(1).messages({
  'object.min': 'At least one field must be provided for update'
});

// Enhanced student creation schema
const createStudentSchema = Joi.object({
  username: Joi.string()
    .pattern(USERNAME_REGEX)
    .min(3)
    .max(30)
    .required()
    .messages({
      'string.pattern.base': 'Username can only contain letters, numbers, and underscores',
      'string.min': 'Username must be at least 3 characters',
      'string.max': 'Username cannot exceed 30 characters',
      'any.required': 'Username is required'
    }),
  
  password: Joi.string()
    .min(6)
    .max(50)
    .required()
    .messages({
      'string.min': 'Password must be at least 6 characters',
      'string.max': 'Password cannot exceed 50 characters',
      'any.required': 'Password is required'
    }),
  
  email: Joi.string()
    .email()
    .max(255)
    .required()
    .messages({
      'string.email': 'Please provide a valid email address',
      'string.max': 'Email cannot exceed 255 characters',
      'any.required': 'Email is required'
    }),
  
  fullName: Joi.string()
    .pattern(VIETNAMESE_NAME_REGEX)
    .min(2)
    .max(50)
    .required()
    .messages({
      'string.pattern.base': 'Full name can only contain Vietnamese letters and spaces',
      'string.min': 'Full name must be at least 2 characters',
      'string.max': 'Full name cannot exceed 50 characters',
      'any.required': 'Full name is required'
    })
});

// Student update schema
const updateStudentSchema = Joi.object({
  email: Joi.string()
    .email()
    .max(255)
    .optional()
    .messages({
      'string.email': 'Please provide a valid email address',
      'string.max': 'Email cannot exceed 255 characters'
    }),
  
  fullName: Joi.string()
    .pattern(VIETNAMESE_NAME_REGEX)
    .min(2)
    .max(50)
    .optional()
    .messages({
      'string.pattern.base': 'Full name can only contain Vietnamese letters and spaces',
      'string.min': 'Full name must be at least 2 characters',
      'string.max': 'Full name cannot exceed 50 characters'
    }),
  
  isActive: Joi.boolean()
    .optional()
}).min(1).messages({
  'object.min': 'At least one field must be provided for update'
});

// Bulk operation schema
const bulkOperationSchema = Joi.object({
  studentIds: Joi.array()
    .items(Joi.string().uuid())
    .min(1)
    .max(100)
    .required()
    .messages({
      'array.min': 'At least one student must be selected',
      'array.max': 'Cannot perform bulk operations on more than 100 students at once',
      'any.required': 'Student IDs are required'
    }),
  
  action: Joi.string()
    .valid('activate', 'deactivate', 'delete')
    .required()
    .messages({
      'any.only': 'Action must be one of: activate, deactivate, delete',
      'any.required': 'Action is required'
    }),
  
  data: Joi.object().optional()
});

function validate(schema, data) {
  const { error, value } = schema.validate(data, { 
    abortEarly: false,
    stripUnknown: true
  });

  if (error) {
    return {
      isValid: false,
      errors: error.details.map(detail => ({
        field: detail.path.join('.'),
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
 * Validate login request
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateLogin(data) {
  return validate(loginSchema, data);
}

/**
 * Validate user creation request
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateUserCreation(data) {
  return validate(createUserSchema, data);
}

/**
 * Validate refresh token request
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateRefreshToken(data) {
  return validate(refreshTokenSchema, data);
}

/**
 * Validate profile update request
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateProfileUpdate(data) {
  return validate(updateProfileSchema, data);
}

/**
 * Sanitize user data for client response
 * @param {Object} user - User object from database
 * @returns {Object} Sanitized user object
 */
function sanitizeUserData(user) {
  const {
    password_hash,
    salt,
    ...sanitizedUser
  } = user;

  return {
    ...sanitizedUser,
    full_name: user.full_name,
    avatar_url: user.avatar_url,
    last_login_at: user.last_login_at,
    created_at: user.created_at,
    updated_at: user.updated_at
  };
}

/**
 * Validate username format
 * @param {string} username - Username to validate
 * @returns {boolean}
 */
function isValidUsername(username) {
  return /^\w{3,50}$/.test(username);
}

/**
 * Validate email format
 * @param {string} email - Email to validate
 * @returns {boolean}
 */
function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

/**
 * Validate student creation request
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateStudentCreation(data) {
  return validate(createStudentSchema, data);
}

/**
 * Validate student update request
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateStudentUpdate(data) {
  return validate(updateStudentSchema, data);
}

/**
 * Validate bulk operation request
 * @param {Object} data - Request data to validate
 * @returns {{isValid: boolean, errors?: string[], data?: Object}}
 */
function validateBulkOperation(data) {
  return validate(bulkOperationSchema, data);
}

/**
 * Validate Vietnamese name format
 * @param {string} name - Name to validate
 * @returns {boolean}
 */
function isValidVietnameseName(name) {
  if (!name || typeof name !== 'string') return false;
  
  // Remove extra spaces and normalize
  const normalized = name.trim().replaceAll(/\s+/g, ' ');
  
  // Check length
  if (normalized.length < 2 || normalized.length > 50) return false;
  
  // Check for valid Vietnamese characters only
  if (!VIETNAMESE_NAME_REGEX.test(normalized)) return false;
  
  // Prevent names with only spaces or single characters
  if (normalized.split(' ').some((part) => part.length < 1)) return false;
  
  // Prevent common injection patterns
  const dangerousPatterns = [
    /<[^>]*>/g, // HTML tags
    /javascript:/gi,
    /on\w+\s*=/gi, // Event handlers
    /(union|select|insert|update|delete|drop)\s/gi, // SQL
  ];
  
  for (const pattern of dangerousPatterns) {
    if (pattern.test(normalized)) return false;
  }
  
  return true;
}

module.exports = {
  validate,
  validateLogin,
  validateUserCreation,
  validateRefreshToken,
  validateProfileUpdate,
  validateStudentCreation,
  validateStudentUpdate,
  validateBulkOperation,
  sanitizeUserData,
  isValidUsername,
  isValidEmail,
  isValidVietnameseName
};