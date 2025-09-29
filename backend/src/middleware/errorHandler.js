/**
 * Custom error class for application-specific errors
 */
class AppError extends Error {
  constructor(message, statusCode = 500, code = 'INTERNAL_ERROR', details = null) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Handle Supabase errors
 * @param {Object} error - Supabase error object
 * @returns {AppError} Formatted app error
 */
function handleSupabaseError(error) {
  let message = 'Database operation failed';
  let statusCode = 500;
  let code = 'DATABASE_ERROR';

  switch (error.code) {
    case '23505': // Unique violation
      message = 'Resource already exists';
      statusCode = 409;
      code = 'DUPLICATE_RESOURCE';
      break;
    case '23503': // Foreign key violation
      message = 'Referenced resource not found';
      statusCode = 400;
      code = 'INVALID_REFERENCE';
      break;
    case '23502': // Not null violation
      message = 'Required field missing';
      statusCode = 400;
      code = 'MISSING_REQUIRED_FIELD';
      break;
    case 'PGRST116': // No rows found
      message = 'Resource not found';
      statusCode = 404;
      code = 'RESOURCE_NOT_FOUND';
      break;
    default:
      if (error.message) {
        message = error.message;
      }
  }

  return new AppError(message, statusCode, code, error.details);
}

/**
 * Handle JWT errors
 * @param {Object} error - JWT error object
 * @returns {AppError} Formatted app error
 */
function handleJWTError(error) {
  let message = 'Authentication failed';
  let code = 'AUTH_ERROR';

  if (error.name === 'TokenExpiredError') {
    message = 'Token has expired';
    code = 'TOKEN_EXPIRED';
  } else if (error.name === 'JsonWebTokenError') {
    message = 'Invalid token';
    code = 'TOKEN_INVALID';
  }

  return new AppError(message, 401, code);
}

/**
 * Handle validation errors
 * @param {Object} error - Validation error object
 * @returns {AppError} Formatted app error
 */
function handleValidationError(error) {
  const message = 'Validation failed';
  const details = error.details ? error.details.map(detail => detail.message) : null;
  
  return new AppError(message, 400, 'VALIDATION_ERROR', details);
}

/**
 * Development error response
 * @param {Object} error - Error object
 * @param {Object} res - Express response object
 */
function sendErrorDev(error, res) {
  res.status(error.statusCode).json({
    success: false,
    message: error.message,
    code: error.code,
    details: error.details,
    stack: error.stack,
    error: error
  });
}

/**
 * Production error response
 * @param {Object} error - Error object
 * @param {Object} res - Express response object
 */
function sendErrorProd(error, res) {
  // Only send operational errors to client in production
  if (error.isOperational) {
    res.status(error.statusCode).json({
      success: false,
      message: error.message,
      code: error.code,
      details: error.details
    });
  } else {
    // Log error for debugging
    console.error('ERROR:', error);

    // Send generic message
    res.status(500).json({
      success: false,
      message: 'Something went wrong',
      code: 'INTERNAL_ERROR'
    });
  }
}

/**
 * Global error handling middleware
 */
function errorHandler(error, req, res, next) {
  let err = { ...error };
  err.message = error.message;

  // Log error
  console.error('Error Handler:', {
    message: error.message,
    stack: error.stack,
    url: req.originalUrl,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });

  // Handle specific error types
  if (error.code && error.code.startsWith('23')) {
    // Supabase/PostgreSQL errors
    err = handleSupabaseError(error);
  } else if (error.name === 'TokenExpiredError' || error.name === 'JsonWebTokenError') {
    // JWT errors
    err = handleJWTError(error);
  } else if (error.name === 'ValidationError') {
    // Validation errors
    err = handleValidationError(error);
  } else if (!error.statusCode) {
    // Convert unknown errors to AppError
    err = new AppError(error.message || 'Internal server error', 500);
  }

  // Set default values
  err.statusCode = err.statusCode || 500;
  err.code = err.code || 'INTERNAL_ERROR';

  // Send response based on environment
  if (process.env.NODE_ENV === 'development') {
    sendErrorDev(err, res);
  } else {
    sendErrorProd(err, res);
  }
}

/**
 * Handle unhandled routes
 */
function notFoundHandler(req, res, next) {
  const error = new AppError(
    `Route ${req.originalUrl} not found`,
    404,
    'ROUTE_NOT_FOUND'
  );
  next(error);
}

/**
 * Async error wrapper
 * @param {Function} fn - Async function to wrap
 * @returns {Function} Wrapped function
 */
function catchAsync(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = {
  AppError,
  errorHandler,
  notFoundHandler,
  catchAsync
};