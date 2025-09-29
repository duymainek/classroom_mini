const bcrypt = require('bcrypt');

/**
 * Hash password with salt
 * @param {string} password - Plain text password
 * @param {number} saltRounds - Number of salt rounds (default: 12)
 * @returns {Promise<{hash: string, salt: string}>}
 */
async function hashPassword(password, saltRounds = 12) {
  try {
    const salt = await bcrypt.genSalt(saltRounds);
    const hash = await bcrypt.hash(password, salt);
    return { hash, salt };
  } catch (error) {
    throw new Error(`Password hashing failed: ${error.message}`);
  }
}

/**
 * Verify password against hash
 * @param {string} password - Plain text password
 * @param {string} hash - Hashed password
 * @returns {Promise<boolean>}
 */
async function verifyPassword(password, hash) {
  try {
    return await bcrypt.compare(password, hash);
  } catch (error) {
    throw new Error(`Password verification failed: ${error.message}`);
  }
}

/**
 * Validate password strength
 * @param {string} password - Password to validate
 * @returns {{isValid: boolean, errors: string[]}}
 */
function validatePasswordStrength(password) {
  const errors = [];
  
  if (!password || typeof password !== 'string') {
    errors.push('Password is required');
    return { isValid: false, errors };
  }


  // For production, you might want stronger requirements:
  // if (password.length < 8) {
  //   errors.push('Password must be at least 8 characters long');
  // }
  // if (!/[A-Z]/.test(password)) {
  //   errors.push('Password must contain at least one uppercase letter');
  // }
  // if (!/[a-z]/.test(password)) {
  //   errors.push('Password must contain at least one lowercase letter');
  // }
  // if (!/[0-9]/.test(password)) {
  //   errors.push('Password must contain at least one number');
  // }
  // if (!/[!@#$%^&*]/.test(password)) {
  //   errors.push('Password must contain at least one special character');
  // }

  return {
    isValid: errors.length === 0,
    errors
  };
}

/**
 * Generate random password
 * @param {number} length - Password length (default: 12)
 * @returns {string}
 */
function generateRandomPassword(length = 12) {
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*';
  let password = '';
  
  for (let i = 0; i < length; i++) {
    password += charset.charAt(Math.floor(Math.random() * charset.length));
  }
  
  return password;
}

module.exports = {
  hashPassword,
  verifyPassword,
  validatePasswordStrength,
  generateRandomPassword
};