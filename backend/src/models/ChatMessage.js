const { supabase } = require('../services/supabaseClient');

class ChatMessage {
  static async create(messageData) {
    const { roomId, authorId, text, type = 'text', uri, name, size, mimeType, repliedMessageId } = messageData;

    const { data, error } = await supabase
      .from('chat_messages')
      .insert({
        room_id: roomId,
        author_id: authorId,
        text,
        type,
        uri,
        name,
        size,
        mime_type: mimeType,
        replied_message_id: repliedMessageId
      })
      .select()
      .single();

    if (error) throw error;

    return await this.getById(data.id);
  }

  static async getById(messageId) {
    const { data, error } = await supabase
      .from('chat_messages')
      .select(`
        *,
        author:chat_users!chat_messages_author_id_fkey(
          id,
          first_name,
          last_name,
          image_url,
          role,
          last_seen,
          metadata
        )
      `)
      .eq('id', messageId)
      .single();

    if (error) throw error;

    // Fetch replied message separately if exists
    if (data.replied_message_id) {
      const { data: repliedMsg } = await supabase
        .from('chat_messages')
        .select('id, text, type, author_id')
        .eq('id', data.replied_message_id)
        .single();
      
      if (repliedMsg) {
        data.replied_message = repliedMsg;
      }
    }

    return this.formatMessage(data);
  }

  static async getByRoomId(roomId, userId, options = {}) {
    const { limit = 50, before } = options;

    let queryBuilder = supabase
      .from('chat_messages')
      .select(`
        *,
        author:chat_users!chat_messages_author_id_fkey(
          id,
          first_name,
          last_name,
          image_url,
          role,
          last_seen,
          metadata
        ),
        read_by:chat_message_read_status(
          user_id
        )
      `)
      .eq('room_id', roomId)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (before) {
      const { data: beforeMessage } = await supabase
        .from('chat_messages')
        .select('created_at')
        .eq('id', before)
        .single();

      if (beforeMessage) {
        queryBuilder = queryBuilder.lt('created_at', beforeMessage.created_at);
      }
    }

    const { data, error } = await queryBuilder;

    if (error) throw error;

    // Fetch replied messages separately if needed
    const messagesWithReplies = await Promise.all(
      (data || []).map(async (msg) => {
        if (msg.replied_message_id) {
          const { data: repliedMsg } = await supabase
            .from('chat_messages')
            .select('id, text, type, author_id')
            .eq('id', msg.replied_message_id)
            .single();
          
          if (repliedMsg) {
            msg.replied_message = repliedMsg;
          }
        }
        return msg;
      })
    );

    return messagesWithReplies.map(msg => this.formatMessage(msg));
  }

  static async search(roomId, userId, searchQuery, limit = 20) {
    const { data: membership } = await supabase
      .from('chat_room_members')
      .select('id')
      .eq('room_id', roomId)
      .eq('user_id', userId)
      .single();

    if (!membership) {
      throw new Error('Not a member of this room');
    }

    const { data, error } = await supabase
      .from('chat_messages')
      .select(`
        *,
        author:chat_users!chat_messages_author_id_fkey(
          id,
          first_name,
          last_name,
          image_url,
          role
        )
      `)
      .eq('room_id', roomId)
      .ilike('text', `%${searchQuery}%`)
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) throw error;

    return (data || []).map(msg => this.formatMessage(msg));
  }

  static formatMessage(message) {
    return {
      id: message.id,
      roomId: message.room_id,
      authorId: message.author_id,
      text: message.text,
      type: message.type,
      uri: message.uri,
      name: message.name,
      size: message.size ? Number(message.size) : null,
      mimeType: message.mime_type,
      width: message.width ? Number(message.width) : null,
      height: message.height ? Number(message.height) : null,
      repliedMessageId: message.replied_message_id,
      repliedMessage: message.replied_message ? this.formatMessage(message.replied_message) : null,
      status: message.status,
      metadata: message.metadata,
      createdAt: message.created_at,
      updatedAt: message.updated_at,
      author: message.author ? {
        id: message.author.id || '',
        fullName: `${message.author.first_name || ''} ${message.author.last_name || ''}`.trim() || 'Unknown User',
        avatarUrl: message.author.image_url || null,
        role: message.author.role || 'student',
        lastSeen: message.author.last_seen || null,
        metadata: message.author.metadata || null
      } : null,
      readBy: message.read_by ? message.read_by.map(r => r.user_id) : []
    };
  }
}

module.exports = ChatMessage;

