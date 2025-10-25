const express = require('express');
const router = express.Router();
const announcementController = require('../controllers/announcementController');
const announcementFileController = require('../controllers/announcementFileController');
const { authenticateToken, requireRole } = require('../middleware/auth');

// All routes require authentication
router.use(authenticateToken);

// Create announcement (instructor only)
router.post('/', 
  requireRole(['instructor']),
  announcementController.createAnnouncement
);

// Get announcements with filters (instructor only)
router.get('/',
  requireRole(['instructor']),
  announcementController.getAnnouncements
);

// Get announcement by ID (instructor only)
router.get('/:id',
  requireRole(['instructor']),
  announcementController.getAnnouncementById
);

// Update announcement (instructor only)
router.put('/:id',
  requireRole(['instructor']),
  announcementController.updateAnnouncement
);

// Delete announcement (instructor only)
router.delete('/:id',
  requireRole(['instructor']),
  announcementController.deleteAnnouncement
);

// Get announcement comments
router.get('/:id/comments',
  announcementController.getAnnouncementComments
);

// Add comment to announcement
router.post('/:id/comments',
  announcementController.addComment
);

// Track announcement view (all authenticated users)
router.post('/:id/views',
  announcementController.trackView
);

// Track file download (student only)
router.post('/files/:fileId/downloads',
  requireRole(['student']),
  announcementController.trackDownload
);

// Get announcement tracking data (instructor only)
router.get('/:id/tracking',
  requireRole(['instructor']),
  announcementController.getAnnouncementTracking
);

// Get file download tracking data (instructor only)
router.get('/:id/file-tracking',
  requireRole(['instructor']),
  announcementController.getFileDownloadTracking
);

// File attachment routes
// Upload temporary attachment for announcement creation
router.post('/temp-attachments',
  requireRole(['instructor']),
  announcementFileController.uploadTempAttachment
);

// Finalize temporary attachments for announcement
router.post('/:id/attachments/finalize',
  requireRole(['instructor']),
  announcementFileController.finalizeTempAttachments
);

// Get announcement attachments
router.get('/:id/attachments',
  announcementFileController.getAnnouncementAttachments
);

// Delete announcement attachment
router.delete('/attachments/:attachmentId',
  requireRole(['instructor']),
  announcementFileController.deleteAnnouncementAttachment
);

module.exports = router;
