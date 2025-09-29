const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { authenticateToken } = require('../middleware/auth');

// All dashboard routes require authentication
router.use(authenticateToken);

// Dashboard endpoints
router.get('/instructor', dashboardController.getInstructorDashboard);
router.get('/student', dashboardController.getStudentDashboard);
router.get('/current-semester', dashboardController.getCurrentSemester);
router.post('/switch-semester/:semesterId', dashboardController.switchSemester);

module.exports = router;