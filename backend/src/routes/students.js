const express = require('express');
const studentController = require('../controllers/studentController');
const { authenticateToken, requireInstructor } = require('../middleware/auth');

const router = express.Router();

// All routes require instructor authentication
router.use(authenticateToken);
router.use(requireInstructor);

// Student CRUD operations
router.post('/', studentController.createStudent);
router.get('/', studentController.getStudents);
router.put('/:studentId', studentController.updateStudent);
router.delete('/:studentId', studentController.deleteStudent);

// Bulk operations
router.post('/bulk', studentController.bulkUpdateStudents);

// Statistics
router.get('/statistics', studentController.getStudentStatistics);

// Password management
router.post('/:studentId/reset-password', studentController.resetStudentPassword);

// Export students (CSV/Excel)
router.get('/export', studentController.exportStudents);

// Import students from CSV (JSON payload of parsed rows)
router.post('/import', studentController.importStudents);
router.post('/import/preview', studentController.previewImport);
router.get('/import/template', studentController.getImportTemplate);

// Health check for student management service
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Student management service is running',
    timestamp: new Date().toISOString(),
    instructor: req.user ? {
      id: req.user.id,
      username: req.user.username,
      role: req.user.role
    } : null
  });
});

module.exports = router;