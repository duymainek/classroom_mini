const express = require('express');
const router = express.Router();
const materialController = require('../controllers/materialController');
const materialFileController = require('../controllers/materialFileController');
const { authenticateToken } = require('../middleware/auth');

// Material CRUD routes
router.post('/', authenticateToken, materialController.createMaterial);
router.get('/', authenticateToken, materialController.getMaterials);
router.get('/:id', authenticateToken, materialController.getMaterialById);
router.put('/:id', authenticateToken, materialController.updateMaterial);
router.delete('/:id', authenticateToken, materialController.deleteMaterial);

// Material tracking routes
router.post('/:id/track-view', authenticateToken, materialController.trackView);
router.post('/attachments/:fileId/track-download', authenticateToken, materialController.trackDownload);
router.get('/:id/tracking', authenticateToken, materialController.getMaterialTracking);
router.get('/:id/file-tracking', authenticateToken, materialController.getFileDownloadTracking);

// Material file attachment routes
router.post('/temp-attachments', authenticateToken, materialFileController.uploadTempAttachment);
router.post('/:materialId/attachments/finalize', authenticateToken, materialFileController.finalizeTempAttachments);
router.get('/:materialId/attachments', authenticateToken, materialFileController.getMaterialAttachments);
router.delete('/attachments/:attachmentId', authenticateToken, materialFileController.deleteMaterialAttachment);

module.exports = router;
