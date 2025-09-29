const express = require('express');
const router = express.Router();
const assignmentController = require('../controllers/assignmentController');
const { authenticateToken, requireInstructor, requireAuthenticated } = require('../middleware/auth');

// Assignment CRUD routes (Instructor only)
router.post('/', authenticateToken, requireInstructor, assignmentController.createAssignment);
router.get('/', authenticateToken, requireAuthenticated, assignmentController.getAssignments);
router.get('/:assignmentId', authenticateToken, requireAuthenticated, assignmentController.getAssignmentById);
router.put('/:assignmentId', authenticateToken, requireInstructor, assignmentController.updateAssignment);
router.delete('/:assignmentId', authenticateToken, requireInstructor, assignmentController.deleteAssignment);

// Assignment tracking and grading (Instructor only)
router.get('/:assignmentId/submissions', authenticateToken, requireInstructor, assignmentController.getAssignmentSubmissions);
router.put('/submissions/:submissionId/grade', authenticateToken, requireInstructor, assignmentController.gradeSubmission);
router.get('/:assignmentId/export', authenticateToken, requireInstructor, assignmentController.exportSubmissions);

module.exports = router;
