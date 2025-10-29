const { ForumTopic, ForumReply, ForumAttachment } = require('../models/forum');
const { catchAsync } = require('../middleware/errorHandler');
const { supabase } = require('../services/supabaseClient');

/**
 * Forum Controller
 * Handles forum topics, replies, and interactions
 */
class ForumController {
  /**
   * Create new topic
   * POST /api/forum/topics
   * Body: { title, content, attachment_ids?: [] }
   */
  createTopic = catchAsync(async (req, res) => {
    const { title, content, attachment_ids } = req.body;
    const user_id = req.user.id;

    // Validation
    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: title, content'
      });
    }

    if (title.length > 200) {
      return res.status(400).json({
        success: false,
        message: 'Title must be 200 characters or less'
      });
    }

    // Create topic
    const topic = await ForumTopic.create({
      userId: user_id,
      title,
      content,
      attachmentIds: attachment_ids
    });

    res.status(201).json({
      success: true,
      message: 'Topic created successfully',
      data: topic
    });
  });

  /**
   * Get topics list with filters
   * GET /api/forum/topics?sort=latest&limit=20&offset=0
   */
  getTopics = catchAsync(async (req, res) => {
    const { 
      sort = 'latest', // latest, popular, most_replied
      limit = 20, 
      offset = 0 
    } = req.query;

    const result = await ForumTopic.findAll({
      sort,
      limit: parseInt(limit),
      offset: parseInt(offset)
    });

    res.json({
      success: true,
      data: result.topics
    });
  });

  /**
   * Get single topic by ID with replies
   * GET /api/forum/topics/:id
   */
  getTopicById = catchAsync(async (req, res) => {
    const { id } = req.params;
    const user_id = req.user.id;

    // Get topic
    const topic = await ForumTopic.findById(id);

    if (!topic) {
      return res.status(404).json({
        success: false,
        message: 'Topic not found'
      });
    }

    // Track view
    await topic.trackView(user_id);

    // Get replies (with nested structure)
    const replies = await ForumReply.findByTopicId(id, user_id);

    res.json({
      success: true,
      data: {
        topic,
        replies
      }
    });
  });

  /**
   * Update topic (own topics only)
   * PUT /api/forum/topics/:id
   * Body: { title?, content? }
   */
  updateTopic = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { title, content } = req.body;
    const user_id = req.user.id;

    // Get topic and verify ownership
    const topic = await ForumTopic.findById(id);
    if (!topic) {
      return res.status(404).json({
        success: false,
        message: 'Topic not found'
      });
    }

    if (topic.userId !== user_id) {
      return res.status(403).json({
        success: false,
        message: 'You can only edit your own topics'
      });
    }

    // Update
    const updatedTopic = await topic.update({ title, content });

    res.json({
      success: true,
      message: 'Topic updated successfully',
      data: updatedTopic
    });
  });

  /**
   * Delete topic (soft delete, own topics only)
   * DELETE /api/forum/topics/:id
   */
  deleteTopic = catchAsync(async (req, res) => {
    const { id } = req.params;
    const user_id = req.user.id;

    // Get topic and verify ownership
    const topic = await ForumTopic.findById(id);
    if (!topic) {
      return res.status(404).json({
        success: false,
        message: 'Topic not found'
      });
    }

    if (topic.userId !== user_id) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own topics'
      });
    }

    // Soft delete
    await topic.delete();

    res.json({
      success: true,
      message: 'Topic deleted successfully'
    });
  });

  /**
   * Search topics
   * GET /api/forum/topics/search?q=keyword
   */
  searchTopics = catchAsync(async (req, res) => {
    const { q } = req.query;

    if (!q) {
      return res.status(400).json({
        success: false,
        message: 'Query (q) is required'
      });
    }

    const topics = await ForumTopic.search(q);

    res.json({
      success: true,
      data: topics
    });
  });

  /**
   * Track topic view
   * POST /api/forum/topics/:id/views
   */
  trackTopicView = catchAsync(async (req, res) => {
    const { id } = req.params;
    const user_id = req.user.id;

    const topic = await ForumTopic.findById(id);
    if (!topic) {
      return res.status(404).json({
        success: false,
        message: 'Topic not found'
      });
    }

    await topic.trackView(user_id);

    res.json({
      success: true,
      message: 'View tracked'
    });
  });

  /**
   * Upload attachment for forum
   * POST /api/forum/attachments/upload
   * Body: FormData with file
   */
  uploadAttachment = catchAsync(async (req, res) => {
    const user_id = req.user.id;
    
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const file = req.file;
    
    // Validate file type
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
    
    if (!allowedTypes.includes(file.mimetype)) {
      return res.status(400).json({
        success: false,
        message: 'File type not supported. Allowed: Images, PDF, DOC, DOCX, TXT, XLS, XLSX, CSV, PPT, PPTX, ZIP, RAR, Python, JS, TS, HTML, CSS, JSON'
      });
    }

    // Validate file size (10MB max)
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSize) {
      return res.status(400).json({
        success: false,
        message: 'File size must be less than 10MB'
      });
    }

    try {
      // Sanitize file name to avoid invalid storage keys (spaces, brackets, etc.)
      const sanitizeFileName = (name) => {
        const lastDot = name.lastIndexOf('.');
        const base = lastDot !== -1 ? name.substring(0, lastDot) : name;
        const ext = lastDot !== -1 ? name.substring(lastDot + 1) : '';
        const sanitizedBase = base
          .toLowerCase()
          .replace(/\s+/g, '_')
          .replace(/[^a-z0-9._-]/g, '');
        const sanitizedExt = ext.toLowerCase().replace(/[^a-z0-9]/g, '');
        return sanitizedExt ? `${sanitizedBase}.${sanitizedExt}` : sanitizedBase;
      };

      const safeOriginal = sanitizeFileName(file.originalname);
      const fileName = `forum_${user_id}_${Date.now()}_${safeOriginal}`;
      const filePath = `${user_id}/${fileName}`;
      
      const { data, error } = await supabase.storage
        .from('forum-attachments')
        .upload(filePath, file.buffer, {
          contentType: file.mimetype,
          cacheControl: '3600',
          upsert: false
        });

      if (error) {
        console.error('Supabase upload error:', error);
        return res.status(500).json({
          success: false,
          message: 'Failed to upload file to storage'
        });
      }

      // Get public URL
      const { data: urlData } = supabase.storage
        .from('forum-attachments')
        .getPublicUrl(filePath);

      // Create TEMP attachment record (no topic/reply yet)
      const { data: tempAttachment, error: tempError } = await supabase
        .from('forum_temp_attachments')
        .insert({
          user_id: user_id,
          file_name: safeOriginal,
          file_url: urlData.publicUrl,
          file_size: file.size,
          file_type: file.mimetype,
          storage_path: filePath
        })
        .select('*')
        .single();

      if (tempError) {
        console.error('Temp attachment insert error:', tempError);
        return res.status(500).json({
          success: false,
          message: 'Failed to create temp attachment'
        });
      }

      res.status(201).json({
        success: true,
        message: 'File uploaded successfully',
        data: tempAttachment
      });

    } catch (error) {
      console.error('Upload error:', error);
      res.status(500).json({
        success: false,
        message: 'Failed to upload file'
      });
    }
  });

  // =====================================================
  // REPLY CONTROLLERS
  // =====================================================

  /**
   * Add reply to topic or reply
   * POST /api/forum/topics/:topicId/replies
   * Body: { content, parent_reply_id? }
   */
  addReply = catchAsync(async (req, res) => {
    const { topicId } = req.params;
    const { content, parent_reply_id } = req.body;
    const user_id = req.user.id;

    // Validation
    if (!content || content.trim().length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Content is required'
      });
    }

    if (content.length > 500) {
      return res.status(400).json({
        success: false,
        message: 'Content must be 500 characters or less'
      });
    }

    // If replying to a reply, verify max nesting level (1 level only)
    if (parent_reply_id) {
      const { data: parentReply, error: parentError } = await supabase
        .from('forum_replies')
        .select('parent_reply_id')
        .eq('id', parent_reply_id)
        .single();

      if (parentError) throw parentError;

      if (parentReply.parent_reply_id) {
        return res.status(400).json({
          success: false,
          message: 'Maximum nesting level reached. You can only reply to top-level comments.'
        });
      }
    }

    // Create reply
    const reply = await ForumReply.create({
      topicId,
      userId: user_id,
      parentReplyId: parent_reply_id,
      content
    });

    res.status(201).json({
      success: true,
      message: 'Reply added successfully',
      data: reply
    });
  });

  /**
   * Get replies for a topic
   * GET /api/forum/topics/:topicId/replies
   */
  getTopicReplies = catchAsync(async (req, res) => {
    const { topicId } = req.params;
    const user_id = req.user.id;

    const replies = await ForumReply.findByTopicId(topicId, user_id);

    res.json({
      success: true,
      data: replies
    });
  });

  /**
   * Update reply (own replies only)
   * PUT /api/forum/replies/:id
   * Body: { content }
   */
  updateReply = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { content } = req.body;
    const user_id = req.user.id;

    // Get reply and verify ownership
    const { data: reply, error: checkError } = await supabase
      .from('forum_replies')
      .select('user_id')
      .eq('id', id)
      .single();

    if (checkError) throw checkError;

    if (reply.user_id !== user_id) {
      return res.status(403).json({
        success: false,
        message: 'You can only edit your own replies'
      });
    }

    // Update
    const replyObj = new ForumReply({ id, user_id: reply.user_id });
    const updatedReply = await replyObj.update({ content });

    res.json({
      success: true,
      message: 'Reply updated successfully',
      data: updatedReply
    });
  });

  /**
   * Delete reply (soft delete, own replies only)
   * DELETE /api/forum/replies/:id
   */
  deleteReply = catchAsync(async (req, res) => {
    const { id } = req.params;
    const user_id = req.user.id;

    // Get reply and verify ownership
    const { data: reply, error: checkError } = await supabase
      .from('forum_replies')
      .select('user_id')
      .eq('id', id)
      .single();

    if (checkError) throw checkError;

    if (reply.user_id !== user_id) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own replies'
      });
    }

    // Soft delete
    const replyObj = new ForumReply({ id, user_id: reply.user_id });
    await replyObj.delete();

    res.json({
      success: true,
      message: 'Reply deleted successfully'
    });
  });

  /**
   * Toggle like on reply
   * POST /api/forum/replies/:id/like
   */
  toggleLike = catchAsync(async (req, res) => {
    const { id } = req.params;
    const user_id = req.user.id;

    const reply = new ForumReply({ id });
    const result = await reply.toggleLike(user_id);

    res.json({
      success: true,
      message: result.isLiked ? 'Reply liked' : 'Reply unliked',
      data: result
    });
  });
}

module.exports = new ForumController();
