const jwt = require('jsonwebtoken');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h';
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '7d';

// Validate JWT secrets
if (!JWT_SECRET || !JWT_REFRESH_SECRET) {
  throw new Error('JWT secrets must be defined in environment variables');
}

/**
 * Generate access token
 * @param {Object} payload - Token payload
 * @param {string} payload.userId - User ID
 * @param {string} payload.role - User role
 * @param {string} payload.username - Username
 * @returns {string} JWT token
 */
function generateAccessToken(payload) {
  try {
    return jwt.sign(
      {
        userId: payload.userId,
        role: payload.role,
        username: payload.username,
        type: 'access'
      },
      JWT_SECRET,
      {
        expiresIn: JWT_EXPIRES_IN,
        issuer: 'classroom-mini',
        audience: 'classroom-mini-app'
      }
    );
  } catch (error) {
    throw new Error(`Access token generation failed: ${error.message}`);
  }
}

/**
 * Generate refresh token
 * @param {Object} payload - Token payload
 * @param {string} payload.userId - User ID
 * @returns {string} JWT refresh token
 */
function generateRefreshToken(payload) {
  try {
    return jwt.sign(
      {
        userId: payload.userId,
        type: 'refresh'
      },
      JWT_REFRESH_SECRET,
      {
        expiresIn: JWT_REFRESH_EXPIRES_IN,
        issuer: 'classroom-mini',
        audience: 'classroom-mini-app'
      }
    );
  } catch (error) {
    throw new Error(`Refresh token generation failed: ${error.message}`);
  }
}

/**
 * Verify access token
 * @param {string} token - JWT token to verify
 * @returns {Object} Decoded token payload
 */
function verifyAccessToken(token) {
  try {
    return jwt.verify(token, JWT_SECRET, {
      issuer: 'classroom-mini',
      audience: 'classroom-mini-app'
    });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new Error('Access token expired');
    } else if (error.name === 'JsonWebTokenError') {
      throw new Error('Invalid access token');
    } else {
      throw new Error(`Access token verification failed: ${error.message}`);
    }
  }
}

/**
 * Verify refresh token
 * @param {string} token - JWT refresh token to verify
 * @returns {Object} Decoded token payload
 */
function verifyRefreshToken(token) {
  try {
    return jwt.verify(token, JWT_REFRESH_SECRET, {
      issuer: 'classroom-mini',
      audience: 'classroom-mini-app'
    });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new Error('Refresh token expired');
    } else if (error.name === 'JsonWebTokenError') {
      throw new Error('Invalid refresh token');
    } else {
      throw new Error(`Refresh token verification failed: ${error.message}`);
    }
  }
}

/**
 * Extract token from Authorization header
 * @param {string} authHeader - Authorization header value
 * @returns {string|null} Extracted token or null
 */
function extractTokenFromHeader(authHeader) {
  if (!authHeader) {
    return null;
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return null;
  }

  return parts[1];
}

/**
 * Generate token pair (access + refresh)
 * @param {Object} payload - Token payload
 * @returns {Object} Object containing both tokens
 */
function generateTokenPair(payload) {
  return {
    accessToken: generateAccessToken(payload),
    refreshToken: generateRefreshToken(payload)
  };
}

/**
 * Decode token without verification (for debugging)
 * @param {string} token - JWT token
 * @returns {Object} Decoded token
 */
function decodeToken(token) {
  try {
    return jwt.decode(token, { complete: true });
  } catch (error) {
    throw new Error(`Token decoding failed: ${error.message}`);
  }
}

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyAccessToken,
  verifyRefreshToken,
  extractTokenFromHeader,
  generateTokenPair,
  decodeToken
};