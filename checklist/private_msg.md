# PRIVATE CHAT - TECHNICAL IMPLEMENTATION GUIDE

## 📋 DATABASE REVIEW & SCHEMA UPDATES

### Current Schema Analysis

**✅ Good:**
- `chat_users`, `chat_rooms`, `chat_messages` tables exist
- Support for different message types (text, image, file)
- Metadata JSONB for extensibility

**⚠️ Issues Found:**

1. **Missing last_message tracking** in `chat_rooms` - Cần để sort conversations
2. **Missing unread_count** - Cần để hiển thị số tin nhắn chưa đọc
3. **Missing user_room_settings** - Để handle hide/archive conversations per user
4. **Missing message read status** - Để track message đã đọc chưa

### Database Migration: `002_update_chat_schema.sql`

```sql
-- =====================================================
-- PRIVATE CHAT SCHEMA UPDATES
-- =====================================================

-- Add columns to chat_rooms for better UX
ALTER TABLE chat_rooms
  ADD COLUMN IF NOT EXISTS last_message_id UUID REFERENCES chat_messages(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMPTZ DEFAULT NOW();

-- Create index for sorting rooms by last message
CREATE INDEX IF NOT EXISTS idx_chat_rooms_last_message ON chat_rooms(last_message_at DESC);

-- =====================================================
-- NEW TABLE: chat_room_members
-- Track user-specific room settings and visibility
-- =====================================================
CREATE TABLE IF NOT EXISTS chat_room_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES chat_users(id) ON DELETE CASCADE,
  
  -- User settings for this room
  is_hidden BOOLEAN DEFAULT FALSE, -- Hide from list (not delete messages)
  is_muted BOOLEAN DEFAULT FALSE,
  is_archived BOOLEAN DEFAULT FALSE,
  
  -- Unread tracking
  unread_count INTEGER DEFAULT 0,
  last_read_message_id UUID REFERENCES chat_messages(id) ON DELETE SET NULL,
  last_read_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Timestamps
  joined_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint: one row per user per room
  UNIQUE(room_id, user_id)
);

-- Indexes for performance
CREATE INDEX idx_chat_room_members_user ON chat_room_members(user_id);
CREATE INDEX idx_chat_room_members_room ON chat_room_members(room_id);
CREATE INDEX idx_chat_room_members_hidden ON chat_room_members(user_id, is_hidden) 
  WHERE is_hidden = FALSE;

-- =====================================================
-- NEW TABLE: chat_message_read_status
-- Track which users have read which messages
-- =====================================================
CREATE TABLE IF NOT EXISTS chat_message_read_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES chat_users(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint
  UNIQUE(message_id, user_id)
);

-- Indexes
CREATE INDEX idx_message_read_status_message ON chat_message_read_status(message_id);
CREATE INDEX idx_message_read_status_user ON chat_message_read_status(user_id);

-- =====================================================
-- TRIGGERS FOR AUTO-UPDATE
-- =====================================================

-- Trigger: Update chat_rooms.last_message when new message created
CREATE OR REPLACE FUNCTION update_room_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chat_rooms 
  SET 
    last_message_id = NEW.id,
    last_message_at = NEW.created_at,
    updated_at = NOW()
  WHERE id = NEW.room_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_room_last_message
AFTER INSERT ON chat_messages
FOR EACH ROW
EXECUTE FUNCTION update_room_last_message();

-- Trigger: Increment unread_count for room members (except sender)
CREATE OR REPLACE FUNCTION increment_unread_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chat_room_members
  SET 
    unread_count = unread_count + 1,
    updated_at = NOW()
  WHERE room_id = NEW.room_id 
    AND user_id != NEW.author_id
    AND is_hidden = FALSE;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_increment_unread_count
AFTER INSERT ON chat_messages
FOR EACH ROW
EXECUTE FUNCTION increment_unread_count();

-- Trigger: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_chat_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_chat_room_members_updated_at
BEFORE UPDATE ON chat_room_members
FOR EACH ROW
EXECUTE FUNCTION update_chat_updated_at();

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function: Get or create direct chat room between 2 users
CREATE OR REPLACE FUNCTION get_or_create_direct_room(
  user1_id UUID,
  user2_id UUID
)
RETURNS UUID AS $$
DECLARE
  room_id UUID;
  user_ids_array UUID[];
BEGIN
  -- Sort user IDs for consistent ordering
  IF user1_id < user2_id THEN
    user_ids_array := ARRAY[user1_id, user2_id];
  ELSE
    user_ids_array := ARRAY[user2_id, user1_id];
  END IF;

  -- Try to find existing direct room
  SELECT id INTO room_id
  FROM chat_rooms
  WHERE type = 'direct'
    AND user_ids = user_ids_array
  LIMIT 1;

  -- If not found, create new room
  IF room_id IS NULL THEN
    INSERT INTO chat_rooms (type, user_ids, metadata)
    VALUES ('direct', user_ids_array, '{}')
    RETURNING id INTO room_id;
    
    -- Create room members for both users
    INSERT INTO chat_room_members (room_id, user_id)
    VALUES 
      (room_id, user1_id),
      (room_id, user2_id);
  END IF;

  RETURN room_id;
END;
$$ LANGUAGE plpgsql;

-- Function: Mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(
  p_room_id UUID,
  p_user_id UUID,
  p_last_message_id UUID
)
RETURNS VOID AS $$
BEGIN
  -- Reset unread count
  UPDATE chat_room_members
  SET 
    unread_count = 0,
    last_read_message_id = p_last_message_id,
    last_read_at = NOW(),
    updated_at = NOW()
  WHERE room_id = p_room_id 
    AND user_id = p_user_id;
    
  -- Insert read status for recent messages (last 100)
  INSERT INTO chat_message_read_status (message_id, user_id)
  SELECT id, p_user_id
  FROM chat_messages
  WHERE room_id = p_room_id
    AND author_id != p_user_id
    AND id <= p_last_message_id
    AND NOT EXISTS (
      SELECT 1 FROM chat_message_read_status 
      WHERE message_id = chat_messages.id 
        AND user_id = p_user_id
    )
  ORDER BY created_at DESC
  LIMIT 100
  ON CONFLICT (message_id, user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE chat_room_members IS 'User-specific room settings and unread tracking';
COMMENT ON TABLE chat_message_read_status IS 'Track message read status per user';
COMMENT ON FUNCTION get_or_create_direct_room IS 'Get existing or create new direct chat room between 2 users';
COMMENT ON FUNCTION mark_messages_as_read IS 'Mark all messages in room as read for user';
```

---

## 🏗️ BACKEND ARCHITECTURE

### File Structure

```
backend/
├── server.js                    # Main server with Socket.IO
├── sockets/
│   ├── chatSocket.js           # Socket.IO event handlers
│   └── socketAuth.js           # Socket authentication middleware
├── controllers/
│   └── chatController.js       # REST API controller
├── models/
│   ├── ChatRoom.js             # ChatRoom model
│   ├── ChatMessage.js          # ChatMessage model
│   └── ChatUser.js             # ChatUser model
├── routes/
│   └── chatRoutes.js           # Chat REST routes
├── services/
│   ├── chatService.js          # Business logic
│   └── supabaseClient.js       # Supabase client (existing)
└── middleware/
    └── auth.js                  # Auth middleware (existing)
```

### `server.js` - Setup Socket.IO

```javascript
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const chatRoutes = require('./routes/chatRoutes');
const { initializeChatSocket } = require('./sockets/chatSocket');

const app = express();
const server = http.createServer(app);

// Socket.IO configuration
const io = socketIo(server, {
  cors: {
    origin: process.env.CLIENT_URL || '*',
    methods: ['GET', 'POST'],
    credentials: true
  },
  transports: ['websocket', 'polling']
});

// Middleware
app.use(cors());
app.use(express.json());

// REST API routes
app.use('/api/chat', chatRoutes);

// Initialize Socket.IO handlers
initializeChatSocket(io);

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`Socket.IO ready for connections`);
});

module.exports = { app, server, io };
```

### `sockets/socketAuth.js` - Socket Authentication Middleware

```javascript
const jwt = require('jsonwebtoken');

/**
 * Socket.IO Authentication Middleware
 * Verifies JWT token from socket handshake
 */
const socketAuthMiddleware = async (socket, next) => {
  try {
    // Get token from handshake auth or query
    const token = socket.handshake.auth.token || socket.handshake.query.token;
    
    if (!token) {
      return next(new Error('Authentication error: No token provided'));
    }

    // Verify JWT token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Attach user info to socket
    socket.userId = decoded.id;
    socket.userRole = decoded.role;
    
    console.log(`Socket authenticated: User ${socket.userId}`);
    next();
    
  } catch (error) {
    console.error('Socket auth error:', error);
    next(new Error('Authentication error: Invalid token'));
  }
};

module.exports = { socketAuthMiddleware };
```

### `sockets/chatSocket.js` - Socket.IO Event Handlers

```javascript
const { socketAuthMiddleware } = require('./socketAuth');
const { supabase } = require('../services/supabaseClient');
const ChatMessage = require('../models/ChatMessage');

/**
 * Initialize Chat Socket.IO handlers
 * @param {SocketIO.Server} io - Socket.IO server instance
 */
function initializeChatSocket(io) {
  // Apply authentication middleware
  io.use(socketAuthMiddleware);

  // Namespace for chat
  const chatNamespace = io.of('/chat');
  chatNamespace.use(socketAuthMiddleware);

  chatNamespace.on('connection', async (socket) => {
    const userId = socket.userId;
    console.log(`User ${userId} connected to chat namespace`);

    // ===================================================
    // GLOBAL EVENTS (for all conversations notification)
    // ===================================================

    /**
     * Join user's global notification channel
     * This receives notifications about ANY new messages in ANY conversation
     */
    socket.join(`user:${userId}`);
    console.log(`User ${userId} joined global notification channel`);

    /**
     * Update user's online status
     */
    await updateUserOnlineStatus(userId, true);

    // ===================================================
    // ROOM-SPECIFIC EVENTS
    // ===================================================

    /**
     * Join a specific chat room
     * Client emits: { roomId: 'uuid' }
     */
    socket.on('join_room', async (data) => {
      try {
        const { roomId } = data;
        console.log(`User ${userId} joining room ${roomId}`);

        // Verify user is member of this room
        const { data: membership, error } = await supabase
          .from('chat_room_members')
          .select('*')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .single();

        if (error || !membership) {
          socket.emit('error', { message: 'Not a member of this room' });
          return;
        }

        // Join the socket room
        socket.join(`room:${roomId}`);
        console.log(`User ${userId} joined room ${roomId}`);

        // Mark messages as read
        await markRoomAsRead(roomId, userId);

        // Emit success
        socket.emit('joined_room', { roomId });

        // Notify other users in room that user is online
        socket.to(`room:${roomId}`).emit('user_joined', {
          userId,
          timestamp: new Date().toISOString()
        });

      } catch (error) {
        console.error('Join room error:', error);
        socket.emit('error', { message: 'Failed to join room' });
      }
    });

    /**
     * Leave a specific chat room
     * Client emits: { roomId: 'uuid' }
     */
    socket.on('leave_room', (data) => {
      try {
        const { roomId } = data;
        console.log(`User ${userId} leaving room ${roomId}`);

        // Leave the socket room
        socket.leave(`room:${roomId}`);

        // Notify others
        socket.to(`room:${roomId}`).emit('user_left', {
          userId,
          timestamp: new Date().toISOString()
        });

        socket.emit('left_room', { roomId });

      } catch (error) {
        console.error('Leave room error:', error);
      }
    });

    /**
     * Send message in a room
     * Client emits: { 
     *   roomId: 'uuid', 
     *   text: 'message text',
     *   type: 'text' | 'image' | 'file',
     *   uri?: 'file url',
     *   name?: 'file name',
     *   size?: file size,
     *   mime_type?: 'mime type',
     *   replied_message_id?: 'uuid'
     * }
     */
    socket.on('send_message', async (data) => {
      try {
        const { roomId, text, type, uri, name, size, mime_type, replied_message_id } = data;

        console.log(`User ${userId} sending message to room ${roomId}`);

        // Verify user is member of room
        const { data: membership, error: memberError } = await supabase
          .from('chat_room_members')
          .select('*')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .single();

        if (memberError || !membership) {
          socket.emit('error', { message: 'Not a member of this room' });
          return;
        }

        // Create message in database
        const message = await ChatMessage.create({
          roomId,
          authorId: userId,
          text,
          type: type || 'text',
          uri,
          name,
          size,
          mimeType: mime_type,
          repliedMessageId: replied_message_id
        });

        // Get room members to notify
        const { data: members } = await supabase
          .from('chat_room_members')
          .select('user_id')
          .eq('room_id', roomId);

        // Broadcast message to all room members
        chatNamespace.to(`room:${roomId}`).emit('new_message', message);

        // Send global notification to offline users
        members.forEach(member => {
          if (member.user_id !== userId) {
            // Send to user's global notification channel
            chatNamespace.to(`user:${member.user_id}`).emit('new_message_notification', {
              roomId,
              message,
              timestamp: new Date().toISOString()
            });
          }
        });

        // Acknowledge to sender
        socket.emit('message_sent', { 
          tempId: data.tempId, // Client-side temporary ID
          message 
        });

      } catch (error) {
        console.error('Send message error:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    /**
     * Typing indicator
     * Client emits: { roomId: 'uuid', isTyping: boolean }
     */
    socket.on('typing', (data) => {
      try {
        const { roomId, isTyping } = data;

        // Broadcast to others in room (not sender)
        socket.to(`room:${roomId}`).emit('user_typing', {
          userId,
          roomId,
          isTyping,
          timestamp: new Date().toISOString()
        });

      } catch (error) {
        console.error('Typing error:', error);
      }
    });

    /**
     * Mark messages as read
     * Client emits: { roomId: 'uuid', lastMessageId: 'uuid' }
     */
    socket.on('mark_read', async (data) => {
      try {
        const { roomId, lastMessageId } = data;

        await markRoomAsRead(roomId, userId, lastMessageId);

        // Notify sender about read status
        socket.to(`room:${roomId}`).emit('messages_read', {
          userId,
          roomId,
          lastMessageId,
          timestamp: new Date().toISOString()
        });

      } catch (error) {
        console.error('Mark read error:', error);
      }
    });

    // ===================================================
    // DISCONNECT
    // ===================================================

    socket.on('disconnect', async () => {
      console.log(`User ${userId} disconnected from chat`);

      // Update user's online status
      await updateUserOnlineStatus(userId, false);

      // Leave all rooms (automatic by Socket.IO)
      // But notify others in rooms
      const rooms = Array.from(socket.rooms).filter(room => room.startsWith('room:'));
      rooms.forEach(roomId => {
        socket.to(roomId).emit('user_left', {
          userId,
          timestamp: new Date().toISOString()
        });
      });
    });

  });
}

// ===================================================
// HELPER FUNCTIONS
// ===================================================

/**
 * Update user's online status in database
 */
async function updateUserOnlineStatus(userId, isOnline) {
  try {
    await supabase
      .from('chat_users')
      .update({ 
        last_seen: new Date().toISOString(),
        metadata: { online: isOnline }
      })
      .eq('id', userId);
  } catch (error) {
    console.error('Update online status error:', error);
  }
}

/**
 * Mark all messages in room as read for user
 */
async function markRoomAsRead(roomId, userId, lastMessageId = null) {
  try {
    // Get last message ID if not provided
    if (!lastMessageId) {
      const { data: lastMsg } = await supabase
        .from('chat_messages')
        .select('id')
        .eq('room_id', roomId)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();
      
      lastMessageId = lastMsg?.id;
    }

    if (!lastMessageId) return;

    // Call stored procedure to mark messages as read
    await supabase.rpc('mark_messages_as_read', {
      p_room_id: roomId,
      p_user_id: userId,
      p_last_message_id: lastMessageId
    });

  } catch (error) {
    console.error('Mark room as read error:', error);
  }
}

module.exports = { initializeChatSocket };
```

### `controllers/chatController.js` - REST API Controller

```javascript
const { catchAsync } = require('../middleware/errorHandler');
const ChatRoom = require('../models/ChatRoom');
const ChatMessage = require('../models/ChatMessage');
const { supabase } = require('../services/supabaseClient');

class ChatController {
  /**
   * Get all conversations for current user
   * GET /api/chat/conversations
   * Query: ?limit=20&offset=0
   */
  getConversations = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { limit = 20, offset = 0 } = req.query;

    /**
     * TODO: Implement logic to:
     * 1. Query chat_room_members WHERE user_id = userId AND is_hidden = FALSE
     * 2. JOIN with chat_rooms to get room details
     * 3. Include last_message from chat_rooms.last_message_id
     * 4. Include unread_count from chat_room_members
     * 5. Get other user's info for direct chats (from user_ids array)
     * 6. Order by chat_rooms.last_message_at DESC (most recent first)
     * 7. Apply pagination with limit and offset
     * 8. Return array of conversation objects with:
     *    - roomId, type, name, imageUrl
     *    - otherUser (for direct chats): id, fullName, avatarUrl, role, lastSeen
     *    - lastMessage: id, text, type, createdAt, authorId
     *    - unreadCount
     *    - updatedAt
     */

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

  /**
   * Get or create direct chat room with another user
   * POST /api/chat/rooms/direct
   * Body: { otherUserId: 'uuid' }
   */
  getOrCreateDirectRoom = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { otherUserId } = req.body;

    /**
     * TODO: Implement logic to:
     * 1. Validate otherUserId exists in users table
     * 2. Cannot chat with yourself (userId !== otherUserId)
     * 3. Call get_or_create_direct_room(userId, otherUserId) SQL function
     * 4. Return room details with other user info
     */

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

  /**
   * Get chat room details
   * GET /api/chat/rooms/:roomId
   */
  getRoomDetails = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;

    /**
     * TODO: Implement logic to:
     * 1. Verify user is member of room (check chat_room_members)
     * 2. Get room details from chat_rooms
     * 3. Get other user details for direct chats
     * 4. Get current user's room settings (is_muted, etc)
     * 5. Return room object with all details
     */

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

  /**
   * Get messages in a room with pagination
   * GET /api/chat/rooms/:roomId/messages
   * Query: ?limit=50&before=messageId (for pagination)
   */
  getRoomMessages = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;
    const { limit = 50, before } = req.query;

    /**
     * TODO: Implement logic to:
     * 1. Verify user is member of room
     * 2. Query chat_messages WHERE room_id = roomId
     * 3. If 'before' param provided, get messages created_at < that message's timestamp
     * 4. Order by created_at DESC (newest first for pagination)
     * 5. Include author info (JOIN chat_users)
     * 6. Include replied_message details if replied_message_id exists
     * 7. Include read status (who read this message)
     * 8. Apply limit
     * 9. Return messages array (reverse to show oldest first in UI)
     */

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

  /**
   * Search messages in a room
   * GET /api/chat/rooms/:roomId/search
   * Query: ?q=keyword&limit=20
   */
  searchMessages = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;
    const { q, limit = 20 } = req.query;

    /**
     * TODO: Implement logic to:
     * 1. Verify user is member of room
     * 2. Query chat_messages WHERE room_id = roomId AND text ILIKE '%keyword%'
     * 3. Order by created_at DESC
     * 4. Include author info
     * 5. Apply limit
     * 6. Return matching messages with context
     */

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

  /**
   * Hide conversation (not delete messages)
   * PUT /api/chat/rooms/:roomId/hide
   * Body: { isHidden: true }
   */
  hideConversation = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;
    const { isHidden } = req.body;

    /**
     * TODO: Implement logic to:
     * 1. Update chat_room_members SET is_hidden = isHidden 
     *    WHERE room_id = roomId AND user_id = userId
     * 2. Messages still exist in database (not deleted)
     * 3. If isHidden = true, conversation removed from list
     * 4. If user receives new message, is_hidden auto set to false (via trigger)
     * 5. Return success
     */

    await ChatRoom.updateMemberSettings(roomId, userId, { isHidden });

    res.json({
      success: true,
      message: isHidden ? 'Conversation hidden' : 'Conversation restored'
    });
  });

  /**
   * Mute/unmute conversation
   * PUT /api/chat/rooms/:roomId/mute
   * Body: { isMuted: true }
   */
  muteConversation = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;
    const { isMuted } = req.body;

    /**
     * TODO: Implement logic to:
     * 1. Update chat_room_members SET is_muted = isMuted
     *    WHERE room_id = roomId AND user_id = userId
     * 2. When muted, user still receives messages but no notifications
     * 3. Return success
     */

    await ChatRoom.updateMemberSettings(roomId, userId, { isMuted });

    res.json({
      success: true,
      message: isMuted ? 'Conversation muted' : 'Conversation unmuted'
    });
  });

  /**
   * Get all users to start new conversation
   * GET /api/chat/users/search
   * Query: ?q=keyword&limit=20 (search by name)
   */
  searchUsers = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { q, limit = 20 } = req.query;

    /**
     * TODO: Implement logic to:
     * 1. Query users table WHERE id != userId (exclude self)
     * 2. If q provided, filter by full_name ILIKE '%keyword%'
     * 3. Order by full_name ASC
     * 4. Apply limit
     * 5. For each user, check if direct chat room already exists
     * 6. Return users array with:
     *    - id, fullName, avatarUrl, role
     *    - existingRoomId (if chat already exists)
     * 7. Prioritize instructor role in results (instructors first)
     */

    const users = await ChatRoom.searchUsersForNewChat(userId, {
      query: q,
      limit: parseInt(limit)
    });

    res.json({
      success: true,
      data: users
    });
  });

  /**
   * Mark all messages in room as read
   * POST /api/chat/rooms/:roomId/read
   */
  markAsRead = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { roomId } = req.params;

    /**
     * TODO: Implement logic to:
     * 1. Call mark_messages_as_read SQL function
     * 2. Reset unread_count to 0 in chat_room_members
     * 3. Update last_read_message_id and last_read_at
     * 4. Return success
     */

    await ChatRoom.markAsRead(roomId, userId);

    res.json({
      success: true,
      message: 'Messages marked as read'
    });
  });

  /**
   * Get unread message count across all conversations
   * GET /api/chat/unread-count
   */
  getUnreadCount = catchAsync(async (req, res) => {
    const userId = req.user.id;

    /**
     * TODO: Implement logic to:
     * 1. SUM(unread_count) FROM chat_room_members 
     *    WHERE user_id = userId AND is_hidden = FALSE
     * 2. Return total unread count
     * 3. Used for app badge notification
     */

    const { data, error } = await supabase
      .from('chat_room_members')
      .select('unread_count')
      .eq('user_id', userId)
      .eq('is_hidden', false);

    if (error) throw error;

    const totalUnread = data.reduce((sum, row) => sum + row.unread_count, 0);

    res.json({
      success: true,
      data: { unreadCount: totalUnread }
    });
  });
}

module.exports = new ChatController();
```

### `routes/chatRoutes.js`

```javascript
const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const { authenticateToken } = require('../middleware/auth');

// All chat routes require authentication
router.use(authenticateToken);

// Conversations
router.get('/conversations', chatController.getConversations);
router.get('/unread-count', chatController.getUnreadCount);

// Rooms
router.post('/rooms/direct', chatController.getOrCreateDirectRoom);
router.get('/rooms/:roomId', chatController.getRoomDetails);
router.get('/rooms/:roomId/messages', chatController.getRoomMessages);
router.get('/rooms/:roomId/search', chatController.searchMessages);
router.put('/rooms/:roomId/hide', chatController.hideConversation);
router.put('/rooms/:roomId/mute', chatController.muteConversation);
router.post('/rooms/:roomId/read', chatController.markAsRead);

// Users
router.get('/users/search', chatController.searchUsers);

module.exports = router;
```

---

## 📱 FRONTEND (FLUTTER) ARCHITECTURE

### File Structure

```
lib/app/
├── data/
│   ├── models/
│   │   ├── request/
│   │   │   ├── create_direct_room_request.dart
│   │   │   ├── send_message_request.dart
│   │   │   └── hide_conversation_request.dart
│   │   └── response/
│   │       ├── conversation_response.dart
│   │       ├── chat_room_response.dart
│   │       ├── chat_message_response.dart
│   │       ├── chat_user_response.dart
│   │       └── search_users_response.dart
│   ├── services/
│   │   ├── chat_api_service.dart     # Retrofit REST API
│   │   └── chat_socket_service.dart  # Socket.IO client
│   └── repositories/
│       └── chat_repository.dart
├── modules/
│   └── chat/
│       ├── controllers/
│       │   ├── chat_list_controller.dart
│       │   ├── chat_room_controller.dart
│       │   └── new_chat_controller.dart
│       ├── views/
│       │   ├── chat_list_page.dart
│       │   ├── chat_room_page.dart
│       │   └── new_chat_page.dart
│       ├── widgets/
│       │   ├── conversation_card.dart
│       │   ├── message_bubble.dart
│       │   ├── message_input.dart
│       │   └── typing_indicator.dart
│       └── bindings/
│           └── chat_binding.dart
└── routes/
    └── app_pages.dart
```

### Models - Request

**`models/request/create_direct_room_request.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'create_direct_room_request.g.dart';

/// Request to create or get direct chat room with another user
@JsonSerializable()
class CreateDirectRoomRequest {
  @JsonKey(name: 'otherUserId')
  final String otherUserId;

  CreateDirectRoomRequest({required this.otherUserId});

  factory CreateDirectRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateDirectRoomRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateDirectRoomRequestToJson(this);
}
```

**`models/request/send_message_request.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'send_message_request.g.dart';

/// Socket.IO event data for sending message
@JsonSerializable()
class SendMessageRequest {
  final String roomId;
  final String? text;
  final String type; // 'text', 'image', 'file'
  
  // For file/image messages
  final String? uri;
  final String? name;
  final int? size;
  @JsonKey(name: 'mime_type')
  final String? mimeType;
  
  // For image dimensions
  final double? width;
  final double? height;
  
  // For reply
  @JsonKey(name: 'replied_message_id')
  final String? repliedMessageId;
  
  // Client-side temporary ID (before server confirms)
  final String? tempId;

  SendMessageRequest({
    required this.roomId,
    this.text,
    required this.type,
    this.uri,
    this.name,
    this.size,
    this.mimeType,
    this.width,
    this.height,
    this.repliedMessageId,
    this.tempId,
  });

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}
```

### Models - Response

**`models/response/chat_user_response.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'chat_user_response.g.dart';

@JsonSerializable()
class ChatUserResponse {
  final String id;
  
  @JsonKey(name: 'full_name')
  final String fullName;
  
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  
  final String role; // 'instructor' or 'student'
  
  @JsonKey(name: 'last_seen')
  final DateTime? lastSeen;
  
  final Map<String, dynamic>? metadata; // Contains { online: bool }

  ChatUserResponse({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    this.lastSeen,
    this.metadata,
  });

  factory ChatUserResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatUserResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatUserResponseToJson(this);
  
  bool get isOnline => metadata?['online'] == true;
  bool get isInstructor => role == 'instructor';
  
  String get displayName => fullName;
  String get roleLabel => isInstructor ? 'Instructor' : 'Student';
}
```

**`models/response/chat_message_response.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';
import 'chat_user_response.dart';

part 'chat_message_response.g.dart';

@JsonSerializable()
class ChatMessageResponse {
  final String id;
  
  @JsonKey(name: 'room_id')
  final String roomId;
  
  @JsonKey(name: 'author_id')
  final String authorId;
  
  final String? text;
  final String type; // 'text', 'image', 'file', 'custom'
  final String? status;
  
  // File/Image data
  final String? uri;
  final String? name;
  final int? size;
  @JsonKey(name: 'mime_type')
  final String? mimeType;
  final double? width;
  final double? height;
  
  // Reply data
  @JsonKey(name: 'replied_message_id')
  final String? repliedMessageId;
  
  @JsonKey(name: 'replied_message')
  final ChatMessageResponse? repliedMessage;
  
  final Map<String, dynamic>? metadata;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  // Author info (from JOIN)
  final ChatUserResponse? author;
  
  // Read status
  @JsonKey(name: 'read_by')
  final List<String>? readBy; // Array of user IDs who read this message

  ChatMessageResponse({
    required this.id,
    required this.roomId,
    required this.authorId,
    this.text,
    required this.type,
    this.status,
    this.uri,
    this.name,
    this.size,
    this.mimeType,
    this.width,
    this.height,
    this.repliedMessageId,
    this.repliedMessage,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.author,
    this.readBy,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageResponseToJson(this);
  
  bool get isTextMessage => type == 'text';
  bool get isImageMessage => type == 'image';
  bool get isFileMessage => type == 'file';
  bool get hasReply => repliedMessageId != null;
  
  String get displayTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
```

**`models/response/conversation_response.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';
import 'chat_user_response.dart';
import 'chat_message_response.dart';

part 'conversation_response.g.dart';

/// Represents a conversation in the chat list
@JsonSerializable()
class ConversationResponse {
  @JsonKey(name: 'room_id')
  final String roomId;
  
  final String type; // 'direct', 'group', 'channel'
  final String? name;
  
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  
  // For direct chats, info about the other user
  @JsonKey(name: 'other_user')
  final ChatUserResponse? otherUser;
  
  // Last message in conversation
  @JsonKey(name: 'last_message')
  final ChatMessageResponse? lastMessage;
  
  // Unread count for current user
  @JsonKey(name: 'unread_count')
  final int unreadCount;
  
  // Room settings for current user
  @JsonKey(name: 'is_muted')
  final bool isMuted;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  ConversationResponse({
    required this.roomId,
    required this.type,
    this.name,
    this.imageUrl,
    this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    required this.isMuted,
    required this.updatedAt,
  });

  factory ConversationResponse.fromJson(Map<String, dynamic> json) =>
      _$ConversationResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationResponseToJson(this);
  
  bool get isDirect => type == 'direct';
  bool get hasUnread => unreadCount > 0;
  
  String get displayName {
    if (isDirect && otherUser != null) {
      return otherUser!.displayName;
    }
    return name ?? 'Chat';
  }
  
  String? get displayAvatar {
    if (isDirect && otherUser != null) {
      return otherUser!.avatarUrl;
    }
    return imageUrl;
  }
  
  String get lastMessagePreview {
    if (lastMessage == null) return 'No messages yet';
    if (lastMessage!.isTextMessage) return lastMessage!.text ?? '';
    if (lastMessage!.isImageMessage) return '📷 Image';
    if (lastMessage!.isFileMessage) return '📎 ${lastMessage!.name}';
    return 'Message';
  }
}
```

### API Service (Retrofit)

**`services/chat_api_service.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/request/create_direct_room_request.dart';
import '../models/response/conversation_response.dart';
import '../models/response/chat_room_response.dart';
import '../models/response/chat_message_response.dart';
import '../models/response/search_users_response.dart';

part 'chat_api_service.g.dart';

@RestApi()
abstract class ChatApiService {
  factory ChatApiService(Dio dio, {String baseUrl}) = _ChatApiService;

  /// Get all conversations for current user
  /// GET /api/chat/conversations?limit=20&offset=0
  @GET('/chat/conversations')
  Future<ApiResponse<ConversationsListResponse>> getConversations({
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  });

  /// Get or create direct chat room
  /// POST /api/chat/rooms/direct
  @POST('/chat/rooms/direct')
  Future<ApiResponse<ChatRoomResponse>> getOrCreateDirectRoom(
    @Body() CreateDirectRoomRequest request,
  );

  /// Get chat room details
  /// GET /api/chat/rooms/:roomId
  @GET('/chat/rooms/{roomId}')
  Future<ApiResponse<ChatRoomResponse>> getRoomDetails(
    @Path('roomId') String roomId,
  );

  /// Get messages in room
  /// GET /api/chat/rooms/:roomId/messages?limit=50&before=messageId
  @GET('/chat/rooms/{roomId}/messages')
  Future<ApiResponse<MessagesListResponse>> getRoomMessages(
    @Path('roomId') String roomId, {
    @Query('limit') int? limit,
    @Query('before') String? before, // Message ID for pagination
  });

  /// Search messages in room
  /// GET /api/chat/rooms/:roomId/search?q=keyword&limit=20
  @GET('/chat/rooms/{roomId}/search')
  Future<ApiResponse<List<ChatMessageResponse>>> searchMessages(
    @Path('roomId') String roomId,
    @Query('q') String query, {
    @Query('limit') int? limit,
  });

  /// Hide conversation
  /// PUT /api/chat/rooms/:roomId/hide
  @PUT('/chat/rooms/{roomId}/hide')
  Future<SimpleResponse> hideConversation(
    @Path('roomId') String roomId,
    @Body() Map<String, dynamic> body, // { isHidden: true }
  );

  /// Mute conversation
  /// PUT /api/chat/rooms/:roomId/mute
  @PUT('/chat/rooms/{roomId}/mute')
  Future<SimpleResponse> muteConversation(
    @Path('roomId') String roomId,
    @Body() Map<String, dynamic> body, // { isMuted: true }
  );

  /// Mark messages as read
  /// POST /api/chat/rooms/:roomId/read
  @POST('/chat/rooms/{roomId}/read')
  Future<SimpleResponse> markAsRead(
    @Path('roomId') String roomId,
  );

  /// Search users for new chat
  /// GET /api/chat/users/search?q=keyword&limit=20
  @GET('/chat/users/search')
  Future<ApiResponse<List<SearchUserResponse>>> searchUsers({
    @Query('q') String? query,
    @Query('limit') int? limit,
  });

  /// Get total unread count
  /// GET /api/chat/unread-count
  @GET('/chat/unread-count')
  Future<ApiResponse<UnreadCountResponse>> getUnreadCount();
}

// Response wrappers
@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  ApiResponse({required this.success, this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}

@JsonSerializable()
class SimpleResponse {
  final bool success;
  final String message;

  SimpleResponse({required this.success, required this.message});

  factory SimpleResponse.fromJson(Map<String, dynamic> json) =>
      _$SimpleResponseFromJson(json);
}

@JsonSerializable()
class ConversationsListResponse {
  final List<ConversationResponse> conversations;
  final int total;
  final int limit;
  final int offset;

  ConversationsListResponse({
    required this.conversations,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ConversationsListResponse.fromJson(Map<String, dynamic> json) =>
      _$ConversationsListResponseFromJson(json);
}

@JsonSerializable()
class MessagesListResponse {
  final List<ChatMessageResponse> messages;
  @JsonKey(name: 'hasMore')
  final bool hasMore;

  MessagesListResponse({required this.messages, required this.hasMore});

  factory MessagesListResponse.fromJson(Map<String, dynamic> json) =>
      _$MessagesListResponseFromJson(json);
}

@JsonSerializable()
class UnreadCountResponse {
  @JsonKey(name: 'unreadCount')
  final int unreadCount;

  UnreadCountResponse({required this.unreadCount});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) =>
      _$UnreadCountResponseFromJson(json);
}
```

### Socket Service

**`services/chat_socket_service.dart`**

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import '../models/request/send_message_request.dart';
import '../models/response/chat_message_response.dart';

/// Socket.IO service for real-time chat
/// Manages 2 types of connections:
/// 1. Global connection: for new message notifications across all chats
/// 2. Room-specific events: for active chat room
class ChatSocketService extends GetxService {
  IO.Socket? _socket;
  final RxBool isConnected = false.obs;
  final RxString currentRoomId = ''.obs;
  
  // Callbacks for different events
  Function(ChatMessageResponse)? onNewMessage;
  Function(String roomId, ChatMessageResponse)? onNewMessageNotification;
  Function(String userId, bool isTyping)? onUserTyping;
  Function(String userId)? onUserJoined;
  Function(String userId)? onUserLeft;
  Function(String messageId)? onMessagesRead;

  /// Initialize and connect to Socket.IO server
  /// Call this once when app starts (or user logs in)
  Future<void> connect(String token) async {
    /**
     * TODO: Implement Socket.IO connection
     * 1. Create socket with URL from env config
     * 2. Set auth token in handshake
     * 3. Set transports: ['websocket', 'polling']
     * 4. Connect to namespace '/chat'
     * 5. Setup global event listeners (see below)
     * 6. Handle connection/disconnection events
     * 7. Set isConnected flag
     */
    
    if (_socket != null && _socket!.connected) {
      print('Socket already connected');
      return;
    }

    final socketUrl = 'YOUR_SOCKET_URL'; // From env config
    
    _socket = IO.io(
      '$socketUrl/chat',
      IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .setAuth({'token': token})
        .enableAutoConnect()
        .build(),
    );

    // Connection events
    _socket!.onConnect((_) {
      print('Socket connected');
      isConnected.value = true;
    });

    _socket!.onDisconnect((_) {
      print('Socket disconnected');
      isConnected.value = false;
      currentRoomId.value = '';
    });

    _socket!.onConnectError((error) {
      print('Socket connection error: $error');
    });

    // Setup global listeners
    _setupGlobalListeners();
  }

  /// Setup global event listeners (for all conversations)
  void _setupGlobalListeners() {
    /**
     * TODO: Setup listeners for global events
     * 1. 'new_message_notification': Fired when new message in ANY room
     *    - Show notification
     *    - Update conversation list (new message at top)
     *    - Increment unread count
     *    - Call onNewMessageNotification callback
     * 
     * 2. 'error': Handle socket errors
     *    - Log error
     *    - Show toast to user if needed
     */

    _socket!.on('new_message_notification', (data) {
      print('New message notification: $data');
      final roomId = data['roomId'] as String;
      final messageData = data['message'] as Map<String, dynamic>;
      final message = ChatMessageResponse.fromJson(messageData);
      
      onNewMessageNotification?.call(roomId, message);
    });

    _socket!.on('error', (data) {
      print('Socket error: $data');
      Get.snackbar('Error', data['message'] ?? 'Socket error occurred');
    });
  }

  /// Join a specific chat room
  /// Call this when user opens a chat conversation
  void joinRoom(String roomId) {
    /**
     * TODO: Emit 'join_room' event
     * 1. Emit event with roomId
     * 2. Setup room-specific listeners (see _setupRoomListeners)
     * 3. Set currentRoomId
     * 4. Wait for 'joined_room' confirmation
     */
    
    if (!isConnected.value) {
      print('Socket not connected, cannot join room');
      return;
    }

    if (currentRoomId.value == roomId) {
      print('Already in room $roomId');
      return;
    }

    print('Joining room: $roomId');
    _socket!.emit('join_room', {'roomId': roomId});
    
    currentRoomId.value = roomId;
    _setupRoomListeners(roomId);
    
    // Listen for join confirmation
    _socket!.once('joined_room', (data) {
      print('Successfully joined room: ${data['roomId']}');
    });
  }

  /// Setup room-specific event listeners
  void _setupRoomListeners(String roomId) {
    /**
     * TODO: Setup listeners for room-specific events
     * 1. 'new_message': New message in THIS room
     *    - Add message to messages list in controller
     *    - Scroll to bottom
     *    - Mark as read if room is active
     *    - Call onNewMessage callback
     * 
     * 2. 'user_typing': User is typing in THIS room
     *    - Show typing indicator
     *    - Call onUserTyping callback
     * 
     * 3. 'user_joined': User joined THIS room (came online)
     *    - Update user's online status
     *    - Call onUserJoined callback
     * 
     * 4. 'user_left': User left THIS room (went offline)
     *    - Update user's online status
     *    - Call onUserLeft callback
     * 
     * 5. 'messages_read': Other user read messages
     *    - Update read status on message bubbles
     *    - Call onMessagesRead callback
     * 
     * 6. 'message_sent': Confirmation that OUR message was sent
     *    - Replace temp message with real message from server
     *    - Update message ID
     */

    _socket!.on('new_message', (data) {
      print('New message in room $roomId: $data');
      final message = ChatMessageResponse.fromJson(data as Map<String, dynamic>);
      onNewMessage?.call(message);
    });

    _socket!.on('user_typing', (data) {
      final userId = data['userId'] as String;
      final isTyping = data['isTyping'] as bool;
      onUserTyping?.call(userId, isTyping);
    });

    _socket!.on('user_joined', (data) {
      final userId = data['userId'] as String;
      onUserJoined?.call(userId);
    });

    _socket!.on('user_left', (data) {
      final userId = data['userId'] as String;
      onUserLeft?.call(userId);
    });

    _socket!.on('messages_read', (data) {
      final lastMessageId = data['lastMessageId'] as String;
      onMessagesRead?.call(lastMessageId);
    });

    _socket!.on('message_sent', (data) {
      print('Message sent confirmation: $data');
      // Handle in controller to replace temp message
    });
  }

  /// Leave current room
  /// Call this when user exits chat screen
  void leaveRoom() {
    /**
     * TODO: Leave current room
     * 1. Emit 'leave_room' event with currentRoomId
     * 2. Remove room-specific listeners
     * 3. Clear currentRoomId
     * 4. Wait for 'left_room' confirmation
     */
    
    if (currentRoomId.value.isEmpty) return;

    print('Leaving room: ${currentRoomId.value}');
    _socket!.emit('leave_room', {'roomId': currentRoomId.value});
    
    // Remove all room-specific listeners
    _socket!.off('new_message');
    _socket!.off('user_typing');
    _socket!.off('user_joined');
    _socket!.off('user_left');
    _socket!.off('messages_read');
    _socket!.off('message_sent');
    
    currentRoomId.value = '';
  }

  /// Send message via socket
  void sendMessage(SendMessageRequest request) {
    /**
     * TODO: Emit 'send_message' event
     * 1. Validate socket is connected
     * 2. Validate we're in the room
     * 3. Emit event with message data
     * 4. Wait for 'message_sent' confirmation
     * 5. Handle errors
     */
    
    if (!isConnected.value) {
      Get.snackbar('Error', 'Not connected to chat server');
      return;
    }

    if (currentRoomId.value != request.roomId) {
      Get.snackbar('Error', 'Not in the correct room');
      return;
    }

    print('Sending message: ${request.toJson()}');
    _socket!.emit('send_message', request.toJson());
  }

  /// Send typing indicator
  void sendTypingIndicator(String roomId, bool isTyping) {
    /**
     * TODO: Emit 'typing' event
     * 1. Throttle events (don't send too frequently)
     * 2. Emit with roomId and isTyping status
     */
    
    if (!isConnected.value || currentRoomId.value != roomId) return;
    
    _socket!.emit('typing', {
      'roomId': roomId,
      'isTyping': isTyping,
    });
  }

  /// Mark messages as read via socket
  void markAsRead(String roomId, String lastMessageId) {
    /**
     * TODO: Emit 'mark_read' event
     * 1. Emit with roomId and lastMessageId
     * 2. This triggers real-time read status update for other users
     */
    
    if (!isConnected.value) return;
    
    _socket!.emit('mark_read', {
      'roomId': roomId,
      'lastMessageId': lastMessageId,
    });
  }

  /// Disconnect socket
  /// Call this when user logs out
  void disconnect() {
    /**
     * TODO: Disconnect socket
     * 1. Leave current room if any
     * 2. Disconnect socket
     * 3. Clear all listeners
     * 4. Reset state
     */
    
    if (currentRoomId.value.isNotEmpty) {
      leaveRoom();
    }

    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    isConnected.value = false;
    
    print('Socket disconnected and disposed');
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
```

### Controllers (GetX)

**`controllers/chat_list_controller.dart`**

```dart
import 'package:get/get.dart';
import '../../../data/models/response/conversation_response.dart';
import '../../../data/services/chat_api_service.dart';
import '../../../data/services/chat_socket_service.dart';

/// Controller for Chat List Page
/// Manages list of conversations
class ChatListController extends GetxController {
  final ChatApiService _chatApi;
  final ChatSocketService _socketService;
  
  ChatListController(this._chatApi, this._socketService);

  // State
  final conversations = <ConversationResponse>[].obs;
  final isLoading = false.obs;
  final totalUnreadCount = 0.obs;
  
  @override
  void onInit() {
    super.onInit();
    loadConversations();
    setupSocketListeners();
    loadUnreadCount();
  }

  /// Load conversations from API
  Future<void> loadConversations({bool refresh = false}) async {
    /**
     * TODO: Load conversations
     * 1. Call API to get conversations list
     * 2. Sort by updatedAt DESC (most recent first)
     * 3. Update conversations observable
     * 4. Handle errors
     */
    
    if (refresh) {
      conversations.clear();
    }
    
    isLoading.value = true;
    
    try {
      final response = await _chatApi.getConversations(limit: 50, offset: 0);
      
      if (response.data != null) {
        conversations.value = response.data!.conversations;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load conversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Setup socket listeners for real-time updates
  void setupSocketListeners() {
    /**
     * TODO: Setup socket listeners
     * 1. Listen to 'new_message_notification' from socket service
     * 2. When new message arrives:
     *    - Find conversation by roomId
     *    - Update lastMessage
     *    - Increment unreadCount
     *    - Move conversation to top of list
     *    - Update totalUnreadCount
     * 3. Show local notification (optional)
     */
    
    _socketService.onNewMessageNotification = (roomId, message) {
      // Find conversation
      final index = conversations.indexWhere((c) => c.roomId == roomId);
      
      if (index != -1) {
        // Update existing conversation
        final conv = conversations[index];
        final updated = ConversationResponse(
          roomId: conv.roomId,
          type: conv.type,
          name: conv.name,
          imageUrl: conv.imageUrl,
          otherUser: conv.otherUser,
          lastMessage: message,
          unreadCount: conv.unreadCount + 1,
          isMuted: conv.isMuted,
          updatedAt: message.createdAt,
        );
        
        // Remove from old position and add to top
        conversations.removeAt(index);
        conversations.insert(0, updated);
        
        totalUnreadCount.value++;
      } else {
        // New conversation, reload list
        loadConversations(refresh: true);
      }
    };
  }

  /// Load total unread count
  Future<void> loadUnreadCount() async {
    /**
     * TODO: Get total unread count from API
     * 1. Call API endpoint
     * 2. Update totalUnreadCount
     * 3. Use this for app badge
     */
    
    try {
      final response = await _chatApi.getUnreadCount();
      if (response.data != null) {
        totalUnreadCount.value = response.data!.unreadCount;
      }
    } catch (e) {
      print('Failed to load unread count: $e');
    }
  }

  /// Hide conversation
  Future<void> hideConversation(String roomId) async {
    /**
     * TODO: Hide conversation
     * 1. Show confirmation dialog
     * 2. Call API to hide
     * 3. Remove from list
     * 4. Show success message
     */
    
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Hide Conversation'),
        content: Text('This will hide the conversation from your list. Messages will not be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Hide'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      await _chatApi.hideConversation(roomId, {'isHidden': true});
      conversations.removeWhere((c) => c.roomId == roomId);
      Get.snackbar('Success', 'Conversation hidden');
    } catch (e) {
      Get.snackbar('Error', 'Failed to hide conversation: $e');
    }
  }

  /// Navigate to chat room
  void openChatRoom(ConversationResponse conversation) {
    /**
     * TODO: Navigate to chat room
     * 1. Pass roomId and conversation data as arguments
     * 2. Use Get.toNamed() with route
     * 3. When returning, refresh conversation if needed
     */
    
    Get.toNamed('/chat/room', arguments: {
      'roomId': conversation.roomId,
      'conversation': conversation,
    })?.then((_) {
      // Refresh when returning
      loadConversations(refresh: true);
    });
  }

  /// Navigate to new chat page
  void openNewChat() {
    /**
     * TODO: Navigate to new chat page (search users)
     * 1. Use Get.toNamed()
     * 2. When returning with selected user, load conversations
     */
    
    Get.toNamed('/chat/new')?.then((_) {
      loadConversations(refresh: true);
    });
  }

  @override
  void onClose() {
    // Don't disconnect socket here, it's managed globally
    super.onClose();
  }
}
```

**`controllers/chat_room_controller.dart`**

```dart
import 'package:get/get.dart';
import '../../../data/models/response/chat_message_response.dart';
import '../../../data/models/response/conversation_response.dart';
import '../../../data/models/request/send_message_request.dart';
import '../../../data/services/chat_api_service.dart';
import '../../../data/services/chat_socket_service.dart';

/// Controller for Chat Room Page
/// Manages messages, sending, real-time updates
class ChatRoomController extends GetxController {
  final ChatApiService _chatApi;
  final ChatSocketService _socketService;
  
  ChatRoomController(this._chatApi, this._socketService);

  // State
  final messages = <ChatMessageResponse>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final typingUsers = <String>[].obs; // User IDs currently typing
  
  // Room info
  late String roomId;
  late ConversationResponse conversation;
  final messageText = ''.obs;
  
  @override
  void onInit() {
    super.onInit();
    
    // Get arguments
    roomId = Get.arguments['roomId'];
    conversation = Get.arguments['conversation'];
    
    // Join room via socket
    _socketService.joinRoom(roomId);
    
    // Load initial messages
    loadMessages();
    
    // Setup socket listeners
    setupSocketListeners();
  }

  /// Load initial messages
  Future<void> loadMessages({bool refresh = false}) async {
    /**
     * TODO: Load messages from API
     * 1. Call API with roomId and limit
     * 2. Messages returned in DESC order (newest first)
     * 3. Reverse array to show oldest first in UI
     * 4. Update messages observable
     * 5. Scroll to bottom after loading
     * 6. Mark messages as read
     */
    
    if (refresh) {
      messages.clear();
      hasMore.value = true;
    }
    
    isLoading.value = true;
    
    try {
      final response = await _chatApi.getRoomMessages(
        roomId,
        limit: 50,
      );
      
      if (response.data != null) {
        // Reverse to show oldest first
        final msgs = response.data!.messages.reversed.toList();
        messages.value = msgs;
        hasMore.value = response.data!.hasMore;
        
        // Mark as read
        if (msgs.isNotEmpty) {
          await markAsRead(msgs.last.id);
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more older messages (pagination)
  Future<void> loadMoreMessages() async {
    /**
     * TODO: Load older messages for pagination
     * 1. Get oldest message ID from current list
     * 2. Call API with 'before' parameter
     * 3. Prepend to messages list (older messages go at top)
     * 4. Update hasMore flag
     */
    
    if (isLoadingMore.value || !hasMore.value || messages.isEmpty) return;
    
    isLoadingMore.value = true;
    
    try {
      final oldestMessageId = messages.first.id;
      
      final response = await _chatApi.getRoomMessages(
        roomId,
        limit: 30,
        before: oldestMessageId,
      );
      
      if (response.data != null) {
        final olderMsgs = response.data!.messages.reversed.toList();
        messages.insertAll(0, olderMsgs);
        hasMore.value = response.data!.hasMore;
      }
    } catch (e) {
      print('Failed to load more messages: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Setup socket listeners for real-time messages
  void setupSocketListeners() {
    /**
     * TODO: Setup socket event callbacks
     * 1. onNewMessage: Add message to list, scroll to bottom
     * 2. onUserTyping: Show/hide typing indicator
     * 3. onMessagesRead: Update read status on messages
     */
    
    _socketService.onNewMessage = (message) {
      // Add message to list
      messages.add(message);
      
      // Mark as read if it's from other user
      if (message.authorId != Get.find<AuthController>().currentUserId) {
        markAsRead(message.id);
      }
    };
    
    _socketService.onUserTyping = (userId, isTyping) {
      if (isTyping) {
        if (!typingUsers.contains(userId)) {
          typingUsers.add(userId);
        }
      } else {
        typingUsers.remove(userId);
      }
    };
    
    _socketService.onMessagesRead = (lastMessageId) {
      // Update read status on messages
      for (var msg in messages) {
        if (msg.id == lastMessageId) break;
        // Mark as read (update UI)
      }
    };
  }

  /// Send text message
  Future<void> sendMessage() async {
    /**
     * TODO: Send message via socket
     * 1. Validate messageText is not empty
     * 2. Create temporary message with client-side ID
     * 3. Add temp message to list immediately (optimistic UI)
     * 4. Send via socket
     * 5. Wait for 'message_sent' confirmation
     * 6. Replace temp message with real message from server
     * 7. Clear input
     * 8. Scroll to bottom
     */
    
    if (messageText.value.trim().isEmpty) return;
    
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final text = messageText.value.trim();
    
    // Create temp message
    final tempMessage = ChatMessageResponse(
      id: tempId,
      roomId: roomId,
      authorId: Get.find<AuthController>().currentUserId,
      text: text,
      type: 'text',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: 'sending', // Temp status
    );
    
    // Add to list
    messages.add(tempMessage);
    
    // Clear input
    messageText.value = '';
    
    // Send via socket
    _socketService.sendMessage(SendMessageRequest(
      roomId: roomId,
      text: text,
      type: 'text',
      tempId: tempId,
    ));
  }

  /// Send typing indicator
  void onTyping(bool isTyping) {
    /**
     * TODO: Send typing indicator
     * 1. Throttle events (use debounce)
     * 2. Send via socket
     * 3. Auto-stop after 3 seconds of no typing
     */
    
    _socketService.sendTypingIndicator(roomId, isTyping);
  }

  /// Mark messages as read
  Future<void> markAsRead(String lastMessageId) async {
    /**
     * TODO: Mark messages as read
     * 1. Call API endpoint
     * 2. Also send via socket for real-time update
     * 3. Handle errors silently
     */
    
    try {
      await _chatApi.markAsRead(roomId);
      _socketService.markAsRead(roomId, lastMessageId);
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  /// Send image message
  Future<void> sendImage(String imagePath) async {
    /**
     * TODO: Send image message
     * 1. Upload image to storage (separate API or storage service)
     * 2. Get image URL
     * 3. Get image dimensions
     * 4. Send message via socket with type='image', uri, width, height
     */
    
    // Implementation needed for file upload
    Get.snackbar('TODO', 'Image upload not yet implemented');
  }

  /// Send file message
  Future<void> sendFile(String filePath) async {
    /**
     * TODO: Send file message
     * 1. Upload file to storage
     * 2. Get file URL, name, size, mimeType
     * 3. Send message via socket with type='file', uri, name, size
     */
    
    // Implementation needed for file upload
    Get.snackbar('TODO', 'File upload not yet implemented');
  }

  @override
  void onClose() {
    // Leave room when exiting chat
    _socketService.leaveRoom();
    super.onClose();
  }
}
```

### Binding

**`bindings/chat_binding.dart`**

```dart
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../data/services/chat_api_service.dart';
import '../../../data/services/chat_socket_service.dart';
import '../controllers/chat_list_controller.dart';
import '../controllers/chat_room_controller.dart';
import '../controllers/new_chat_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    // Dio instance (reuse existing or create new)
    final dio = Get.find<Dio>(); // Assuming Dio is already registered
    
    // Register API service (lazy singleton)
    Get.lazyPut<ChatApiService>(
      () => ChatApiService(dio, baseUrl: 'YOUR_API_BASE_URL'),
      fenix: true,
    );
    
    // Register Socket service (singleton, keep alive)
    Get.put<ChatSocketService>(
      ChatSocketService(),
      permanent: true, // Keep alive across routes
    );
    
    // Register controllers (lazy)
    Get.lazyPut<ChatListController>(
      () => ChatListController(Get.find(), Get.find()),
    );
    
    Get.lazyPut<ChatRoomController>(
      () => ChatRoomController(Get.find(), Get.find()),
    );
    
    Get.lazyPut<NewChatController>(
      () => NewChatController(Get.find()),
    );
  }
}
```

### Routes

```dart
// In app_pages.dart
GetPage(
  name: '/chat',
  page: () => ChatListPage(),
  binding: ChatBinding(),
),
GetPage(
  name: '/chat/room',
  page: () => ChatRoomPage(),
  binding: ChatBinding(),
),
GetPage(
  name: '/chat/new',
  page: () => NewChatPage(),
  binding: ChatBinding(),
),
```

---

## ✅ IMPLEMENTATION CHECKLIST

### Database
- [ ] Run migration `002_update_chat_schema.sql`
- [ ] Verify all tables and indexes created
- [ ] Test SQL functions (get_or_create_direct_room, mark_messages_as_read)

### Backend
- [ ] Setup Socket.IO in server.js
- [ ] Implement socket authentication
- [ ] Implement all socket event handlers in chatSocket.js
- [ ] Implement REST API in chatController.js
- [ ] Setup routes in chatRoutes.js
- [ ] Test socket connections with Postman/Socket.IO client
- [ ] Test all REST endpoints

### Frontend
- [ ] Generate model code: `flutter pub run build_runner build`
- [ ] Create all request models
- [ ] Create all response models
- [ ] Implement ChatApiService (Retrofit)
- [ ] Implement ChatSocketService
- [ ] Implement ChatListController
- [ ] Implement ChatRoomController
- [ ] Build UI pages (ChatListPage, ChatRoomPage, NewChatPage)
- [ ] Build widgets (ConversationCard, MessageBubble, MessageInput, TypingIndicator)
- [ ] Test socket connection
- [ ] Test sending/receiving messages
- [ ] Test typing indicators
- [ ] Test read status
- [ ] TODO: Implement file/image upload logic

---

Đây là technical document đầy đủ với comments chi tiết cho Cursor AI. Bạn có muốn tôi thêm gì nữa không?