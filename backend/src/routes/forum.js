const express = require('express');
const multer = require('multer');
const router = express.Router();
const forumController = require('../controllers/forumController');
const { authenticateToken } = require('../middleware/auth');

// Configure multer for file uploads
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    // Allow multiple file types
    const allowedTypes = [
      // Images
      'image/jpeg', 'image/png', 'image/gif', 'image/webp',
      // Documents
      'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'text/plain',
      // Spreadsheets
      'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'text/csv',
      // Presentations
      'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      // Archives
      'application/zip', 'application/x-rar-compressed',
      // Code files
      'text/x-python', 'application/javascript', 'application/typescript', 'text/html', 'text/css', 'application/json'
    ];
    
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('File type not supported'), false);
    }
  }
});

// All routes require authentication
router.use(authenticateToken);

// =====================================================
// TOPIC ROUTES
// =====================================================

// Create topic (all authenticated users)
router.post('/topics', forumController.createTopic);

// Get topics list with filters
router.get('/topics', forumController.getTopics);

// Get single topic by ID with replies
router.get('/topics/:id', forumController.getTopicById);

// Update topic (own topics only)
router.put('/topics/:id', forumController.updateTopic);

// Delete topic (own topics only)
router.delete('/topics/:id', forumController.deleteTopic);

// Search topics
router.get('/topics/search', forumController.searchTopics);

// Track topic view
router.post('/topics/:id/views', forumController.trackTopicView);

// Upload attachment for forum
router.post('/attachments/upload', upload.single('file'), forumController.uploadAttachment);

// =====================================================
// REPLY ROUTES
// =====================================================

// Get replies for a topic
router.get('/topics/:topicId/replies', forumController.getTopicReplies);

// Add reply to topic
router.post('/topics/:topicId/replies', forumController.addReply);

// Update reply (own replies only)
router.put('/replies/:id', forumController.updateReply);

// Delete reply (own replies only)
router.delete('/replies/:id', forumController.deleteReply);

// Like/Unlike reply
router.post('/replies/:id/like', forumController.toggleLike);

module.exports = router;
