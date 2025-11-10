const express = require('express');
const courseController = require('../controllers/courseController');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

// All routes require authentication only - role-based logic handled in controllers
router.use(authenticateToken);

// Course operations (role checked in controller)
router.post('/', courseController.createCourse);
router.get('/', courseController.getCourses);
router.get('/statistics', courseController.getCourseStatistics);
router.get('/semester/:semesterId', courseController.getCoursesBySemester);
router.get('/:courseId', courseController.getCourseById);
router.put('/:courseId', courseController.updateCourse);
router.delete('/:courseId', courseController.deleteCourse);

module.exports = router;