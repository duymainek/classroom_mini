const { socketAuthMiddleware } = require('./socketAuth');
const { supabase } = require('../services/supabaseClient');
const ChatMessage = require('../models/ChatMessage');
const ChatRoom = require('../models/ChatRoom');

function initializeChatSocket(io) {
  io.use(socketAuthMiddleware);

  const chatNamespace = io.of('/chat');
  chatNamespace.use(socketAuthMiddleware);

  chatNamespace.on('connection', async (socket) => {
    const userId = socket.userId;
    console.log(`User ${userId} connected to chat namespace`);

    socket.join(`user:${userId}`);
    console.log(`User ${userId} joined global notification channel`);

    await updateUserOnlineStatus(userId, true);

    socket.on('join_room', async (data) => {
      try {
        const { roomId } = data;
        console.log(`User ${userId} joining room ${roomId}`);

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

        socket.join(`room:${roomId}`);
        console.log(`User ${userId} joined room ${roomId}`);

        // Unhide room when user joins (starts chatting again)
        await ChatRoom.unhideRoom(roomId, userId);

        await markRoomAsRead(roomId, userId);

        socket.emit('joined_room', { roomId });

        socket.to(`room:${roomId}`).emit('user_joined', {
          userId,
          timestamp: new Date().toISOString()
        });

      } catch (error) {
        console.error('Join room error:', error);
        socket.emit('error', { message: 'Failed to join room' });
      }
    });

    socket.on('leave_room', (data) => {
      try {
        const { roomId } = data;
        console.log(`User ${userId} leaving room ${roomId}`);

        socket.leave(`room:${roomId}`);

        socket.to(`room:${roomId}`).emit('user_left', {
          userId,
          timestamp: new Date().toISOString()
        });

        socket.emit('left_room', { roomId });

      } catch (error) {
        console.error('Leave room error:', error);
      }
    });

    socket.on('send_message', async (data) => {
      try {
        const { roomId, text, type, uri, name, size, mime_type, replied_message_id } = data;

        console.log(`User ${userId} sending message to room ${roomId}`);

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

        const { data: members } = await supabase
          .from('chat_room_members')
          .select('user_id')
          .eq('room_id', roomId);

        // Unhide room for all members when new message is sent
        if (members && members.length > 0) {
          const memberIds = members.map(m => m.user_id);
          await supabase
            .from('chat_room_members')
            .update({ is_hidden: false })
            .eq('room_id', roomId)
            .in('user_id', memberIds);
        }

        chatNamespace.to(`room:${roomId}`).emit('new_message', message);

        if (members) {
          members.forEach(member => {
            if (member.user_id !== userId) {
              chatNamespace.to(`user:${member.user_id}`).emit('new_message_notification', {
                roomId,
                message,
                timestamp: new Date().toISOString()
              });
            }
          });
        }

        socket.emit('message_sent', { 
          tempId: data.tempId,
          message 
        });

      } catch (error) {
        console.error('Send message error:', error);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    socket.on('typing', (data) => {
      try {
        const { roomId, isTyping } = data;

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

    socket.on('mark_read', async (data) => {
      try {
        const { roomId, lastMessageId } = data;

        await markRoomAsRead(roomId, userId, lastMessageId);

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

    socket.on('disconnect', async () => {
      console.log(`User ${userId} disconnected from chat`);

      await updateUserOnlineStatus(userId, false);

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

async function markRoomAsRead(roomId, userId, lastMessageId = null) {
  try {
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

