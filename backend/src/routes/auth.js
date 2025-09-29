const express = require('express');
const authController = require('../controllers/authController');
const { authenticateToken, requireInstructor } = require('../middleware/auth');
const { AppError } = require('../middleware/errorHandler');

const router = express.Router();

// Public routes (no authentication required)
router.post('/instructor/login', authController.instructorLogin);
router.post('/student/login', authController.studentLogin);
router.post('/refresh', authController.refreshToken);

// Protected routes (authentication required)
router.use(authenticateToken); // All routes below this require authentication

// User profile routes
router.get('/me', authController.getCurrentUser);
router.put('/profile', authController.updateProfile);
router.post('/logout', authController.logout);

// Instructor-only routes
router.post('/student/create', requireInstructor, authController.createStudent);
router.get('/students', requireInstructor, authController.getStudents);
router.put('/student/:studentId/status', requireInstructor, authController.toggleStudentStatus);

// Health check route for authentication service
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Authentication service is running',
    timestamp: new Date().toISOString(),
    user: req.user ? {
      id: req.user.id,
      username: req.user.username,
      role: req.user.role
    } : null
  });
});

// Test route for development
if (process.env.NODE_ENV === 'development') {
  router.get('/test', (req, res) => {
    res.json({
      success: true,
      message: 'Authentication routes are working',
      availableRoutes: [
        'POST /auth/instructor/login',
        'POST /auth/student/login',
        'POST /auth/refresh',
        'GET /auth/me (protected)',
        'PUT /auth/profile (protected)',
        'POST /auth/logout (protected)',
        'POST /auth/student/create (instructor only)',
        'GET /auth/students (instructor only)',
        'PUT /auth/student/:studentId/status (instructor only)'
      ]
    });
  });
}

module.exports = router;