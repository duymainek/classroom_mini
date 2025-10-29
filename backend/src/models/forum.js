const { supabase } = require('../services/supabaseClient');

/**
 * Forum Topic Model
 */
class ForumTopic {
  constructor(data) {
    this.id = data.id;
    this.userId = data.user_id;
    this.title = data.title;
    this.content = data.content;
    this.replyCount = data.reply_count || 0;
    this.viewCount = data.view_count || 0;
    this.isPinned = data.is_pinned || false;
    this.isLocked = data.is_locked || false;
    this.createdAt = data.created_at;
    this.updatedAt = data.updated_at;
    this.isDeleted = data.is_deleted || false;
    
    // Map user to author with correct field names
    this.author = data.user ? {
      id: data.user.id,
      fullName: data.user.full_name,
      avatarUrl: data.user.avatar_url,
      role: data.user.role
    } : null;
    
    this.attachments = data.attachments || [];
  }

  static async create(data) {
    const { data: topic, error } = await supabase
      .from('forum_topics')
      .insert({
        user_id: data.userId,
        title: data.title,
        content: data.content
      })
      .select(`
        *,
        user:users (
          id,
          full_name,
          avatar_url,
          role
        )
      `)
      .single();

    if (error) throw error;

    // If temp attachmentIds provided, move them into forum_attachments and link to topic
    if (data.attachmentIds && data.attachmentIds.length > 0) {
      // Fetch temp attachments
      const { data: tempList, error: tempFetchError } = await supabase
        .from('forum_temp_attachments')
        .select('*')
        .in('id', data.attachmentIds);

      if (tempFetchError) {
        console.error('Error fetching temp attachments:', tempFetchError);
      } else if (tempList && tempList.length > 0) {
        // Insert into forum_attachments with topic_id
        const toInsert = tempList.map(t => ({
          topic_id: topic.id,
          file_name: t.file_name,
          file_url: t.file_url,
          file_size: t.file_size,
          file_type: t.file_type,
          storage_path: t.storage_path,
        }));

        const { error: insErr } = await supabase
          .from('forum_attachments')
          .insert(toInsert);

        if (insErr) {
          console.error('Error moving temp attachments:', insErr);
        } else {
          // Cleanup temps
          const { error: delErr } = await supabase
            .from('forum_temp_attachments')
            .delete()
            .in('id', data.attachmentIds);
          if (delErr) {
            console.error('Error deleting temp attachments:', delErr);
          }
        }
      }
    }

    return new ForumTopic(topic);
  }

  static async findById(id) {
    const { data: topic, error } = await supabase
      .from('forum_topics')
      .select(`
        *,
        user:users (
          id,
          full_name,
          avatar_url,
          role
        ),
        attachments:forum_attachments (
          id,
          file_name,
          file_url,
          file_size,
          file_type
        )
      `)
      .eq('id', id)
      .eq('is_deleted', false)
      .single();

    if (error) throw error;
    return topic ? new ForumTopic(topic) : null;
  }

  static async findAll(options = {}) {
    const { sort = 'latest', limit = 20, offset = 0 } = options;
    
    let query = supabase
      .from('forum_topics')
      .select(`
        *,
        user:users (
          id,
          full_name,
          avatar_url,
          role
        ),
        attachments:forum_attachments (
          id,
          file_name,
          file_url,
          file_size,
          file_type
        )
      `, { count: 'exact' })
      .eq('is_deleted', false);

    // Sorting
    switch (sort) {
      case 'popular':
        query = query.order('view_count', { ascending: false });
        break;
      case 'most_replied':
        query = query.order('reply_count', { ascending: false });
        break;
      case 'latest':
      default:
        query = query.order('created_at', { ascending: false });
    }

    query = query.range(offset, offset + limit - 1);

    const { data: topics, error, count } = await query;
    if (error) throw error;

    return {
      topics: topics.map(topic => new ForumTopic(topic)),
      total: count,
      limit,
      offset
    };
  }

  static async search(query) {
    const { data: topics, error } = await supabase
      .from('forum_topics')
      .select(`
        *,
        user:users (
          id,
          full_name,
          avatar_url,
          role
        )
      `)
      .eq('is_deleted', false)
      .or(`title.ilike.%${query}%,content.ilike.%${query}%`)
      .order('created_at', { ascending: false })
      .limit(20);

    if (error) throw error;
    return topics.map(topic => new ForumTopic(topic));
  }

  async update(data) {
    const updates = {};
    if (data.title) updates.title = data.title;
    if (data.content) updates.content = data.content;

    const { data: topic, error } = await supabase
      .from('forum_topics')
      .update(updates)
      .eq('id', this.id)
      .select()
      .single();

    if (error) throw error;
    return new ForumTopic(topic);
  }

  async delete() {
    const { error } = await supabase
      .from('forum_topics')
      .update({ is_deleted: true })
      .eq('id', this.id);

    if (error) throw error;
    return true;
  }

  async trackView(userId) {
    const { error } = await supabase
      .from('forum_views')
      .upsert(
        {
          topic_id: this.id,
          user_id: userId,
          view_count: 1,
          last_viewed_at: new Date().toISOString()
        },
        {
          onConflict: 'topic_id,user_id',
          ignoreDuplicates: false
        }
      );

    if (error) throw error;

    // Update view count
    const { error: updateError } = await supabase
      .from('forum_topics')
      .update({ view_count: this.viewCount + 1 })
      .eq('id', this.id);

    if (updateError) throw updateError;
    this.viewCount += 1;
    return true;
  }
}

/**
 * Forum Reply Model
 */
class ForumReply {
  constructor(data) {
    this.id = data.id;
    this.topicId = data.topic_id;
    this.userId = data.user_id;
    this.parentReplyId = data.parent_reply_id;
    this.content = data.content;
    this.likeCount = data.like_count || 0;
    this.createdAt = data.created_at;
    this.updatedAt = data.updated_at;
    this.isDeleted = data.is_deleted || false;
    
    // Map user to author with correct field names
    this.author = data.user ? {
      id: data.user.id,
      fullName: data.user.full_name,
      avatarUrl: data.user.avatar_url,
      role: data.user.role
    } : null;
    
    this.attachments = data.attachments || [];
    this.replies = data.replies || [];
    this.isLiked = data.is_liked || false;
  }

  static async create(data) {
    const { data: reply, error } = await supabase
      .from('forum_replies')
      .insert({
        topic_id: data.topicId,
        user_id: data.userId,
        parent_reply_id: data.parentReplyId,
        content: data.content
      })
      .select(`
        *,
        user:users (
          id,
          full_name,
          avatar_url,
          role
        )
      `)
      .single();

    if (error) throw error;
    return new ForumReply(reply);
  }

  static async findByTopicId(topicId, userId) {
    const { data: replies, error } = await supabase
      .from('forum_replies')
      .select(`
        *,
        user:users (
          id,
          full_name,
          avatar_url,
          role
        ),
        attachments:forum_attachments!reply_id (
          id,
          file_name,
          file_url,
          file_size,
          file_type
        ),
        likes:forum_likes(user_id)
      `)
      .eq('topic_id', topicId)
      .eq('is_deleted', false)
      .order('created_at', { ascending: true });

    if (error) throw error;

    // Check if user liked each reply
    const repliesWithLikeStatus = replies.map(reply => ({
      ...reply,
      is_liked: reply.likes?.some(like => like.user_id === userId) || false,
      likes: undefined // Remove likes array from response
    }));

    // Structure with nesting
    const topLevel = repliesWithLikeStatus.filter(r => !r.parent_reply_id);
    const nested = repliesWithLikeStatus.filter(r => r.parent_reply_id);

    return topLevel.map(parent => ({
      ...parent,
      replies: nested.filter(child => child.parent_reply_id === parent.id).map(reply => new ForumReply(reply))
    })).map(reply => new ForumReply(reply));
  }

  async update(data) {
    const { data: reply, error } = await supabase
      .from('forum_replies')
      .update({ content: data.content })
      .eq('id', this.id)
      .select()
      .single();

    if (error) throw error;
    return new ForumReply(reply);
  }

  async delete() {
    const { error } = await supabase
      .from('forum_replies')
      .update({ is_deleted: true })
      .eq('id', this.id);

    if (error) throw error;
    return true;
  }

  async toggleLike(userId) {
    // Check if already liked
    const { data: existingLike, error: checkError } = await supabase
      .from('forum_likes')
      .select('id')
      .eq('reply_id', this.id)
      .eq('user_id', userId)
      .single();

    if (existingLike) {
      // Unlike
      const { error: deleteError } = await supabase
        .from('forum_likes')
        .delete()
        .eq('id', existingLike.id);

      if (deleteError) throw deleteError;
      return { isLiked: false };
    } else {
      // Like
      const { error: insertError } = await supabase
        .from('forum_likes')
        .insert({
          reply_id: this.id,
          user_id: userId
        });

      if (insertError) throw insertError;
      return { isLiked: true };
    }
  }
}

/**
 * Forum Attachment Model
 */
class ForumAttachment {
  constructor(data) {
    this.id = data.id;
    this.topicId = data.topic_id;
    this.replyId = data.reply_id;
    this.fileName = data.file_name;
    this.fileUrl = data.file_url;
    this.fileSize = data.file_size;
    this.fileType = data.file_type;
    this.storagePath = data.storage_path;
    this.uploadedAt = data.uploaded_at;
  }

  static async create(data) {
    const { data: attachment, error } = await supabase
      .from('forum_attachments')
      .insert({
        topic_id: data.topicId,
        reply_id: data.replyId,
        file_name: data.fileName,
        file_url: data.fileUrl,
        file_size: data.fileSize,
        file_type: data.fileType,
        storage_path: data.storagePath
      })
      .select()
      .single();

    if (error) throw error;
    return new ForumAttachment(attachment);
  }

  static async findByTopicId(topicId) {
    const { data: attachments, error } = await supabase
      .from('forum_attachments')
      .select('*')
      .eq('topic_id', topicId);

    if (error) throw error;
    return attachments.map(attachment => new ForumAttachment(attachment));
  }

  static async findByReplyId(replyId) {
    const { data: attachments, error } = await supabase
      .from('forum_attachments')
      .select('*')
      .eq('reply_id', replyId);

    if (error) throw error;
    return attachments.map(attachment => new ForumAttachment(attachment));
  }

  async delete() {
    // Delete from storage
    const { error: storageError } = await supabase
      .storage
      .from('forum-attachments')
      .remove([this.storagePath]);

    if (storageError) throw storageError;

    // Delete from database
    const { error: deleteError } = await supabase
      .from('forum_attachments')
      .delete()
      .eq('id', this.id);

    if (deleteError) throw deleteError;
    return true;
  }
}

module.exports = {
  ForumTopic,
  ForumReply,
  ForumAttachment
};