const express = require('express');
const groupController = require('../controllers/groupController');
const { authenticateToken, requireInstructor } = require('../middleware/auth');

const router = express.Router();

// All routes require instructor authentication
router.use(authenticateToken);
router.use(requireInstructor);

// Group CRUD operations
router.post('/', groupController.createGroup);
router.get('/', groupController.getGroups);
router.get('/statistics', groupController.getGroupStatistics);
router.get('/course/:courseId', groupController.getGroupsByCourse);
router.get('/:groupId', groupController.getGroupById);
router.put('/:groupId', groupController.updateGroup);
router.delete('/:groupId', groupController.deleteGroup);

// Health check for group management service
router.get('/health', (req, res) => {
  res.json({
    success: true,
    message: 'Group management service is running',
    timestamp: new Date().toISOString(),
    instructor: req.user ? {
      id: req.user.id,
      username: req.user.username,
      role: req.user.role
    } : null
  });
});

module.exports = router;