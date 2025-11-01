const { supabase } = require('../services/supabaseClient');

class ChatRoom {
  static async getConversationsForUser(userId, options = {}) {
    const { limit = 20, offset = 0 } = options;

    // First, get all room IDs for this user
    const { data: userMemberships, error: membershipError } = await supabase
      .from('chat_room_members')
      .select('room_id, unread_count, is_muted')
      .eq('user_id', userId)
      .eq('is_hidden', false);

    if (membershipError) throw membershipError;
    if (!userMemberships || userMemberships.length === 0) {
      return [];
    }

    const roomIds = userMemberships.map(m => m.room_id);
    const membershipMap = new Map(userMemberships.map(m => [m.room_id, m]));

    // Query rooms with ordering by last_message_at
    const { data: rooms, error: roomsError } = await supabase
      .from('chat_rooms')
      .select(`
        id,
        type,
        name,
        image_url,
        last_message_id,
        last_message_at,
        updated_at,
        user_ids,
        last_message:chat_messages!chat_rooms_last_message_id_fkey(
          id,
          text,
          type,
          created_at,
          author_id
        )
      `)
      .in('id', roomIds)
      .order('last_message_at', { ascending: false, nullsFirst: false })
      .order('updated_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (roomsError) throw roomsError;

    const conversations = await Promise.all(
      (rooms || []).map(async (room) => {
        const membership = membershipMap.get(room.id);
        if (!membership) return null;

        let otherUser = null;
        if (room.type === 'direct' && room.user_ids) {
          const otherUserId = room.user_ids.find(id => id !== userId);
          if (otherUserId) {
            const { data: user } = await supabase
              .from('users')
              .select('id, full_name, avatar_url, role')
              .eq('id', otherUserId)
              .single();

            const { data: chatUser } = await supabase
              .from('chat_users')
              .select('last_seen, metadata')
              .eq('id', otherUserId)
              .single();

            if (user) {
              otherUser = {
                id: user.id || '',
                fullName: user.full_name || 'Unknown User',
                avatarUrl: user.avatar_url || null,
                role: user.role || 'student',
                lastSeen: chatUser?.last_seen || null,
                metadata: chatUser?.metadata || null
              };
            }
          }
        }

        const lastMessage = room.last_message ? {
          id: room.last_message.id || '',
          text: room.last_message.text || null,
          type: room.last_message.type || 'text',
          createdAt: room.last_message.created_at || new Date().toISOString(),
          authorId: room.last_message.author_id || ''
        } : null;

        const updatedAt = room.updated_at || room.last_message_at || new Date().toISOString();

        return {
          roomId: room.id || '',
          type: room.type || 'direct',
          name: room.name || null,
          imageUrl: room.image_url || null,
          otherUser: otherUser || null,
          lastMessage: lastMessage || null,
          unreadCount: membership.unread_count || 0,
          isMuted: membership.is_muted || false,
          updatedAt: updatedAt
        };
      })
    );

    return conversations.filter(c => c !== null);
  }

  static async getOrCreateDirectRoom(userId, otherUserId) {
    const { data: roomId, error } = await supabase.rpc('get_or_create_direct_room', {
      user1_id: userId,
      user2_id: otherUserId
    });

    if (error) throw error;
    
    if (!roomId) {
      throw new Error('Failed to get or create direct room');
    }

    // Small delay to ensure memberships are committed
    await new Promise(resolve => setTimeout(resolve, 100));
    
    // Unhide room when user starts chatting again
    await this.unhideRoom(roomId, userId);
    
    return await this.getById(roomId, userId);
  }

  static async getById(roomId, userId) {
    const { data: room, error: roomError } = await supabase
      .from('chat_rooms')
      .select('*')
      .eq('id', roomId)
      .single();

    if (roomError) {
      console.error('Error fetching room:', roomError);
      throw roomError;
    }
    
    if (!room) {
      throw new Error('Room not found');
    }

    let membership = null;
    const { data: membershipData, error: memberError } = await supabase
      .from('chat_room_members')
      .select('*')
      .eq('room_id', roomId)
      .eq('user_id', userId)
      .single();

    if (memberError) {
      console.error('Error fetching membership:', memberError);
      // If membership doesn't exist, try to create it (in case of race condition)
      if (memberError.code === 'PGRST116') {
        const { error: insertError } = await supabase
          .from('chat_room_members')
          .insert({
            room_id: roomId,
            user_id: userId,
            unread_count: 0,
            is_muted: false,
            is_hidden: false
          });
        
        if (insertError) {
          console.error('Error creating membership:', insertError);
          throw new Error('Not a member of this room and failed to create membership');
        }
        
        // Retry getting membership
        const { data: newMembership, error: retryError } = await supabase
          .from('chat_room_members')
          .select('*')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .single();
        
        if (retryError || !newMembership) {
          throw new Error('Not a member of this room');
        }
        
        membership = newMembership;
      } else {
        throw new Error('Not a member of this room');
      }
    } else {
      membership = membershipData;
    }
    
    if (!membership) {
      throw new Error('Not a member of this room');
    }

    let otherUser = null;
    if (room.type === 'direct') {
      const otherUserId = room.user_ids.find(id => id !== userId);
      if (otherUserId) {
        const { data: user } = await supabase
          .from('users')
          .select('id, full_name, avatar_url, role')
          .eq('id', otherUserId)
          .single();

        const { data: chatUser } = await supabase
          .from('chat_users')
          .select('last_seen, metadata')
          .eq('id', otherUserId)
          .single();

        if (user) {
          otherUser = {
            id: user.id,
            fullName: user.full_name,
            avatarUrl: user.avatar_url,
            role: user.role,
            lastSeen: chatUser?.last_seen,
            metadata: chatUser?.metadata
          };
        }
      }
    }

    return {
      id: room.id,
      type: room.type,
      name: room.name,
      imageUrl: room.image_url,
      otherUser,
      isMuted: membership.is_muted,
      isArchived: membership.is_archived,
      unreadCount: membership.unread_count,
      updatedAt: room.updated_at
    };
  }

  static async updateMemberSettings(roomId, userId, settings) {
    const updateData = {};
    if (settings.isHidden !== undefined) updateData.is_hidden = settings.isHidden;
    if (settings.isMuted !== undefined) updateData.is_muted = settings.isMuted;
    if (settings.isArchived !== undefined) updateData.is_archived = settings.isArchived;

    const { error } = await supabase
      .from('chat_room_members')
      .update(updateData)
      .eq('room_id', roomId)
      .eq('user_id', userId);

    if (error) throw error;
  }

  static async unhideRoom(roomId, userId) {
    const { error } = await supabase
      .from('chat_room_members')
      .update({ is_hidden: false })
      .eq('room_id', roomId)
      .eq('user_id', userId);

    if (error) throw error;
  }

  static async markAsRead(roomId, userId) {
    const { data: lastMessage } = await supabase
      .from('chat_messages')
      .select('id')
      .eq('room_id', roomId)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (!lastMessage) return;

    const { error } = await supabase.rpc('mark_messages_as_read', {
      p_room_id: roomId,
      p_user_id: userId,
      p_last_message_id: lastMessage.id
    });

    if (error) throw error;
  }

  static async searchUsersForNewChat(userId, options = {}) {
    const { query, limit = 20 } = options;

    let queryBuilder = supabase
      .from('users')
      .select('id, full_name, avatar_url, role')
      .neq('id', userId)
      .eq('is_active', true)
      .order('role', { ascending: true })
      .order('full_name', { ascending: true })
      .limit(limit);

    if (query) {
      queryBuilder = queryBuilder.ilike('full_name', `%${query}%`);
    }

    const { data: users, error } = await queryBuilder;

    if (error) throw error;

    const usersWithRooms = await Promise.all(
      (users || []).map(async (user) => {
        const sortedIds = userId < user.id ? [userId, user.id] : [user.id, userId];
        
        const { data: rooms, error: roomError } = await supabase
          .from('chat_rooms')
          .select('id')
          .eq('type', 'direct');
        
        let room = null;
        if (!roomError && rooms) {
          room = rooms.find(r => {
            const roomData = r;
            if (!roomData) return false;
            const roomIds = Array.isArray(roomData.user_ids) ? roomData.user_ids : [];
            return roomIds.length === 2 &&
              ((roomIds[0] === sortedIds[0] && roomIds[1] === sortedIds[1]) ||
               (roomIds[0] === sortedIds[1] && roomIds[1] === sortedIds[0]));
          });
        }
        
        if (!room) {
          const { data: directRooms } = await supabase
            .from('chat_rooms')
            .select('id, user_ids')
            .eq('type', 'direct');
          
          if (directRooms) {
            const found = directRooms.find(r => {
              const roomIds = Array.isArray(r.user_ids) ? r.user_ids : [];
              return roomIds.includes(userId) && roomIds.includes(user.id) && roomIds.length === 2;
            });
            room = found ? { id: found.id } : null;
          }
        }

        return {
          id: user.id,
          fullName: user.full_name,
          avatarUrl: user.avatar_url,
          role: user.role,
          existingRoomId: room?.id || null
        };
      })
    );

    return usersWithRooms;
  }
}

module.exports = ChatRoom;

