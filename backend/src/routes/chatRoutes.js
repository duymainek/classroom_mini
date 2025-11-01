const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { authenticateToken } = require('../middleware/auth');

router.use(authenticateToken);

router.get('/conversations', chatController.getConversations);
router.get('/unread-count', chatController.getUnreadCount);

router.post('/rooms/direct', chatController.getOrCreateDirectRoom);
router.get('/rooms/:roomId', chatController.getRoomDetails);
router.get('/rooms/:roomId/messages', chatController.getRoomMessages);
router.get('/rooms/:roomId/search', chatController.searchMessages);
router.put('/rooms/:roomId/hide', chatController.hideConversation);
router.put('/rooms/:roomId/mute', chatController.muteConversation);
router.post('/rooms/:roomId/read', chatController.markAsRead);

router.get('/users/search', chatController.searchUsers);

module.exports = router;

