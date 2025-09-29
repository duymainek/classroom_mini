const express = require('express');
const semesterController = require('../controllers/semesterController');
const { authenticateToken, requireInstructor } = require('../middleware/auth');

const router = express.Router();

// All routes require instructor authentication
router.use(authenticateToken);
router.use(requireInstructor);

// Semester CRUD operations
router.post('/', semesterController.createSemester);
router.get('/', semesterController.getSemesters);
router.get('/statistics', semesterController.getSemesterStatistics);
router.get('/:semesterId', semesterController.getSemesterById);
router.put('/:semesterId', semesterController.updateSemester);
router.delete('/:semesterId', semesterController.deleteSemester);

// Health check for semester management service
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Semester management service is running',
    timestamp: new Date().toISOString(),
    instructor: req.user ? {
      id: req.user.id,
      username: req.user.username,
      role: req.user.role
    } : null
  });
});

module.exports = router;