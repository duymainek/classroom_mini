const express = require('express');
const router = express.Router();
const submissionController = require('../controllers/submissionController');
const { authenticateToken, requireStudent, requireAuthenticated } = require('../middleware/auth');

// Submission routes (Student only)
router.post('/assignments/:assignmentId', authenticateToken, requireStudent, submissionController.submitAssignment);
router.get('/assignments/:assignmentId', authenticateToken, requireStudent, submissionController.getStudentSubmissions);
router.get('/', authenticateToken, requireStudent, submissionController.getStudentAllSubmissions);
router.put('/:submissionId', authenticateToken, requireStudent, submissionController.updateSubmission);
router.delete('/:submissionId', authenticateToken, requireStudent, submissionController.deleteSubmission);

module.exports = router;
