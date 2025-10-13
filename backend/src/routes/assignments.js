const express = require('express');
const router = express.Router();
const assignmentController = require('../controllers/assignmentController');
const fileUploadController = require('../controllers/fileUploadController');
const { authenticateToken, requireInstructor, requireAuthenticated } = require('../middleware/auth');

// Assignment CRUD routes (Instructor only)
router.post('/', authenticateToken, requireInstructor, assignmentController.createAssignment);
router.get('/', authenticateToken, requireAuthenticated, assignmentController.getAssignments);
router.get('/:assignmentId', authenticateToken, requireAuthenticated, assignmentController.getAssignmentById);
router.put('/:assignmentId', authenticateToken, requireInstructor, assignmentController.updateAssignment);
router.delete('/:assignmentId', authenticateToken, requireInstructor, assignmentController.deleteAssignment);

// Assignment attachment routes
router.post('/:assignmentId/attachments', authenticateToken, requireInstructor, fileUploadController.uploadAssignmentAttachments);
router.get('/:assignmentId/attachments', authenticateToken, requireAuthenticated, fileUploadController.getAssignmentAttachments);
router.delete('/attachments/:attachmentId', authenticateToken, requireInstructor, fileUploadController.deleteAssignmentAttachment);

// Assignment tracking and grading (Instructor only)
router.get('/:assignmentId/submissions', authenticateToken, requireInstructor, assignmentController.getAssignmentSubmissions);
router.put('/submissions/:submissionId/grade', authenticateToken, requireInstructor, assignmentController.gradeSubmission);

// Export routes
router.get('/:assignmentId/export/tracking', authenticateToken, requireInstructor, assignmentController.exportAssignmentTracking);
router.get('/:assignmentId/export', authenticateToken, requireInstructor, assignmentController.exportSubmissions);

// Bulk export routes
router.get('/export/all', authenticateToken, requireInstructor, assignmentController.exportAllAssignments);

module.exports = router;
