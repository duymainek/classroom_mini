const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const { authenticateToken } = require('../middleware/auth');

// Routes
router.get('/', authenticateToken, profileController.getProfile);
router.put('/', authenticateToken, profileController.updateProfile);
router.post('/avatar', authenticateToken, profileController.handleAvatarUpload, profileController.uploadAvatar);

module.exports = router;
