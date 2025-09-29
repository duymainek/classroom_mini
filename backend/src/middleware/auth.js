const { verifyAccessToken, extractTokenFromHeader } = require('../utils/tokenUtils');
const { supabase } = require('../services/supabaseClient');

/**
 * Middleware to authenticate requests using JWT tokens
 */
async function authenticateToken(req, res, next) {
  try {
    const authHeader = req.headers['authorization'];
    const token = extractTokenFromHeader(authHeader);

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access token required',
        code: 'TOKEN_MISSING'
      });
    }

    // Verify JWT token
    let decoded;
    try {
      decoded = verifyAccessToken(token);
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: error.message,
        code: 'TOKEN_INVALID'
      });
    }

    // Verify user still exists and is active
    const { data: user, error } = await supabase
      .from('users')
      .select('id, username, role, is_active, full_name, email')
      .eq('id', decoded.userId)
      .eq('is_active', true)
      .single();

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'User not found or inactive',
        code: 'USER_NOT_FOUND'
      });
    }

    // Add user info to request object
    req.user = {
      id: user.id,
      username: user.username,
      role: user.role,
      fullName: user.full_name,
      email: user.email,
      isActive: user.is_active
    };

    next();
  } catch (error) {
    console.error('Authentication middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error during authentication',
      code: 'AUTH_ERROR'
    });
  }
}

/**
 * Middleware to require specific role(s)
 * @param {string|string[]} requiredRoles - Required role(s)
 */
function requireRole(requiredRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
        code: 'AUTH_REQUIRED'
      });
    }

    const roles = Array.isArray(requiredRoles) ? requiredRoles : [requiredRoles];
    
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Required role(s): ${roles.join(', ')}`,
        code: 'INSUFFICIENT_PERMISSIONS'
      });
    }

    next();
  };
}

/**
 * Middleware to require instructor role
 */
const requireInstructor = requireRole('instructor');

/**
 * Middleware to require student role
 */
const requireStudent = requireRole('student');

/**
 * Middleware to allow both instructor and student roles
 */
const requireAuthenticated = requireRole(['instructor', 'student']);

/**
 * Optional authentication middleware (doesn't fail if no token)
 */
async function optionalAuth(req, res, next) {
  try {
    const authHeader = req.headers['authorization'];
    const token = extractTokenFromHeader(authHeader);

    if (!token) {
      req.user = null;
      return next();
    }

    // Try to verify token
    let decoded;
    try {
      decoded = verifyAccessToken(token);
    } catch (error) {
      req.user = null;
      return next();
    }

    // Try to get user info
    const { data: user, error } = await supabase
      .from('users')
      .select('id, username, role, is_active, full_name, email')
      .eq('id', decoded.userId)
      .eq('is_active', true)
      .single();

    if (error || !user) {
      req.user = null;
      return next();
    }

    req.user = {
      id: user.id,
      username: user.username,
      role: user.role,
      fullName: user.full_name,
      email: user.email,
      isActive: user.is_active
    };

    next();
  } catch (error) {
    console.error('Optional auth middleware error:', error);
    req.user = null;
    next();
  }
}

module.exports = {
  authenticateToken,
  requireRole,
  requireInstructor,
  requireStudent,
  requireAuthenticated,
  optionalAuth
};