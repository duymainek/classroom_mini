const express = require('express');
const router = express.Router();
const announcementController = require('../controllers/announcementController');
const announcementFileController = require('../controllers/announcementFileController');
const { authenticateToken } = require('../middleware/auth');

// All routes require authentication only - role-based logic handled in controllers
router.use(authenticateToken);

// Announcement CRUD (role checked in controller)
router.post('/', announcementController.createAnnouncement);
router.get('/', announcementController.getAnnouncements);
router.get('/:id', announcementController.getAnnouncementById);
router.put('/:id', announcementController.updateAnnouncement);
router.delete('/:id', announcementController.deleteAnnouncement);

// Comments
router.get('/:id/comments', announcementController.getAnnouncementComments);
router.post('/:id/comments', announcementController.addComment);

// Tracking
router.post('/:id/views', announcementController.trackView);
router.post('/files/:fileId/downloads', announcementController.trackDownload);
router.get('/:id/tracking', announcementController.getAnnouncementTracking);
router.get('/:id/file-tracking', announcementController.getFileDownloadTracking);

// File attachments
router.post('/temp-attachments', announcementFileController.uploadTempAttachment);
router.post('/:id/attachments/finalize', announcementFileController.finalizeTempAttachments);
router.get('/:id/attachments', announcementFileController.getAnnouncementAttachments);
router.delete('/attachments/:attachmentId', announcementFileController.deleteAnnouncementAttachment);

module.exports = router;
