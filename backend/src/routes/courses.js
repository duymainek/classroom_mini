const express = require('express');
const courseController = require('../controllers/courseController');
const { authenticateToken, requireInstructor } = require('../middleware/auth');

const router = express.Router();

// All routes require instructor authentication
router.use(authenticateToken);
router.use(requireInstructor);

// Course CRUD operations
router.post('/', courseController.createCourse);
router.get('/', courseController.getCourses);
router.get('/statistics', courseController.getCourseStatistics);
router.get('/semester/:semesterId', courseController.getCoursesBySemester);
router.get('/:courseId', courseController.getCourseById);
router.put('/:courseId', courseController.updateCourse);
router.delete('/:courseId', courseController.deleteCourse);

// Health check for course management service
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Course management service is running',
    timestamp: new Date().toISOString(),
    instructor: req.user ? {
      id: req.user.id,
      username: req.user.username,
      role: req.user.role
    } : null
  });
});

module.exports = router;