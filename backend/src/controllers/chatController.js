const { catchAsync } = require('../middleware/errorHandler');
const ChatRoom = require('../models/ChatRoom');
const ChatMessage = require('../models/ChatMessage');
const { supabase } = require('../services/supabaseClient');

class ChatController {
  getConversations = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { limit = 20, offset = 0 } = req.query;

    const conversations = await ChatRoom.getConversationsForUser(userId, {
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json({
      success: true,
      data: {
        conversations,
        total: conversations.length,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });
  });

  getOrCreateDirectRoom = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { otherUserId } = req.body;

    if (!otherUserId) {
      return res.status(400).json({
        success: false,
        message: 'otherUserId is required'
      });
    }

    if (userId === otherUserId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot create chat with yourself'
      });
    }

    const room = await ChatRoom.getOrCreateDirectRoom(userId, otherUserId);

    res.status(200).json({
      success: true,
      message: 'Room ready',
      data: room
    });
  });

  getRoomDetails = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;

    const room = await ChatRoom.getById(roomId, userId);

    if (!room) {
      return res.status(404).json({
        success: false,
        message: 'Room not found or access denied'
      });
    }

    res.json({
      success: true,
      data: room
    });
  });

  getRoomMessages = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;
    const { limit = 50, before } = req.query;

    const { data: membership } = await supabase
      .from('chat_room_members')
      .select('id')
      .eq('room_id', roomId)
      .eq('user_id', userId)
      .single();

    if (!membership) {
      return res.status(403).json({
        success: false,
        message: 'Not a member of this room'
      });
    }

    const messages = await ChatMessage.getByRoomId(roomId, userId, {
      limit: parseInt(limit),
      before
    });

    res.json({
      success: true,
      data: {
        messages,
        hasMore: messages.length >= parseInt(limit)
      }
    });
  });

  searchMessages = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;
    const { q, limit = 20 } = req.query;

    if (!q) {
      return res.status(400).json({
        success: false,
        message: 'Search query (q) is required'
      });
    }

    const messages = await ChatMessage.search(roomId, userId, q, parseInt(limit));

    res.json({
      success: true,
      data: messages
    });
  });

  hideConversation = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;
    const { isHidden } = req.body;

    await ChatRoom.updateMemberSettings(roomId, userId, { isHidden });

    res.json({
      success: true,
      message: isHidden ? 'Conversation hidden' : 'Conversation restored'
    });
  });

  muteConversation = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;
    const { isMuted } = req.body;

    await ChatRoom.updateMemberSettings(roomId, userId, { isMuted });

    res.json({
      success: true,
      message: isMuted ? 'Conversation muted' : 'Conversation unmuted'
    });
  });

  searchUsers = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { q, limit = 20 } = req.query;

    const users = await ChatRoom.searchUsersForNewChat(userId, {
      query: q,
      limit: parseInt(limit)
    });

    res.json({
      success: true,
      data: users
    });
  });

  markAsRead = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;

    await ChatRoom.markAsRead(roomId, userId);

    res.json({
      success: true,
      message: 'Messages marked as read'
    });
  });

  getUnreadCount = catchAsync(async (req, res) => {
    const userId = req.user.id;

    const { data, error } = await supabase
      .from('chat_room_members')
      .select('unread_count')
      .eq('user_id', userId)
      .eq('is_hidden', false);

    if (error) throw error;

    const totalUnread = (data || []).reduce((sum, row) => sum + (row.unread_count || 0), 0);

    res.json({
      success: true,
      data: { unreadCount: totalUnread }
    });
  });
}

module.exports = new ChatController();

