const express = require('express');
const router = express.Router();
const { authenticateToken, requireRole } = require('../middleware/auth');
const fileUploadController = require('../controllers/fileUploadController');

/**
 * @route POST /api/attachments/temp
 * @desc Upload temporary attachment for assignment creation
 * @access Private (Instructor only)
 */
router.post(
  '/attachments/temp',
  authenticateToken,
  requireRole(['instructor']),
  fileUploadController.uploadTempAttachment
);

/**
 * @route POST /api/assignments/:assignmentId/attachments
 * @desc Upload assignment attachments
 * @access Private (Instructor only)
 */
router.post(
  '/:assignmentId/attachments',
  authenticateToken,
  requireRole(['instructor']),
  fileUploadController.uploadAssignmentAttachments
);

/**
 * @route GET /api/assignments/:assignmentId/attachments
 * @desc Get assignment attachments
 * @access Private (Instructor and Students in assigned groups)
 */
router.get(
  '/:assignmentId/attachments',
  authenticateToken,
  fileUploadController.getAssignmentAttachments
);

/**
 * @route POST /api/assignments/:assignmentId/finalize-attachments
 * @desc Finalize temporary attachments for assignment
 * @access Private (Instructor only)
 */
router.post(
  '/:assignmentId/finalize-attachments',
  authenticateToken,
  requireRole(['instructor']),
  fileUploadController.finalizeTempAttachments
);

/**
 * @route DELETE /api/attachments/:attachmentId
 * @desc Delete a specific attachment
 * @access Private (Instructor only)
 */
router.delete(
  '/attachments/:attachmentId',
  authenticateToken,
  requireRole(['instructor']),
  fileUploadController.deleteAssignmentAttachment
);

module.exports = router;