# FORUM MANAGEMENT - TECHNICAL IMPLEMENTATION GUIDE

## 📋 TABLE OF CONTENTS

1. [Database Schema & Migrations](#1-database-schema--migrations)
2. [Backend Implementation](#2-backend-implementation)
3. [Frontend Implementation](#3-frontend-implementation)

---

## 1. DATABASE SCHEMA & MIGRATIONS

### Migration File: `001_create_forum_tables.sql`

```sql
-- =====================================================
-- FORUM MANAGEMENT TABLES
-- =====================================================

-- Table: forum_topics (main posts/topics)
CREATE TABLE IF NOT EXISTS forum_topics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Content
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  
  -- Metadata
  reply_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Status
  is_deleted BOOLEAN DEFAULT FALSE,
  
  -- Constraints
  CONSTRAINT title_not_empty CHECK (LENGTH(TRIM(title)) > 0),
  CONSTRAINT content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

-- Table: forum_replies (comments/replies to topics or other replies)
CREATE TABLE IF NOT EXISTS forum_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID NOT NULL REFERENCES forum_topics(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  parent_reply_id UUID NULL REFERENCES forum_replies(id) ON DELETE CASCADE,
  
  -- Content
  content TEXT NOT NULL,
  
  -- Engagement
  like_count INTEGER DEFAULT 0,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Status
  is_deleted BOOLEAN DEFAULT FALSE,
  
  -- Constraints
  CONSTRAINT content_max_length CHECK (LENGTH(content) <= 500),
  CONSTRAINT content_not_empty CHECK (LENGTH(TRIM(content)) > 0)
);

-- Table: forum_attachments (files attached to topics or replies)
CREATE TABLE IF NOT EXISTS forum_attachments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID NULL REFERENCES forum_topics(id) ON DELETE CASCADE,
  reply_id UUID NULL REFERENCES forum_replies(id) ON DELETE CASCADE,
  
  -- File info
  file_name VARCHAR(255) NOT NULL,
  file_url TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  file_type VARCHAR(100) NOT NULL,
  storage_path TEXT NOT NULL,
  
  -- Timestamps
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT attachment_belongs_to_topic_or_reply CHECK (
    (topic_id IS NOT NULL AND reply_id IS NULL) OR
    (topic_id IS NULL AND reply_id IS NOT NULL)
  )
);

-- Table: forum_likes (track who liked which replies)
CREATE TABLE IF NOT EXISTS forum_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reply_id UUID NOT NULL REFERENCES forum_replies(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Timestamps
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Unique constraint: one like per user per reply
  UNIQUE(reply_id, user_id)
);

-- Table: forum_views (track who viewed which topics)
CREATE TABLE IF NOT EXISTS forum_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID NOT NULL REFERENCES forum_topics(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Tracking
  view_count INTEGER DEFAULT 1,
  last_viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Unique constraint: one row per user per topic
  UNIQUE(topic_id, user_id)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Forum topics indexes
CREATE INDEX idx_forum_topics_course ON forum_topics(course_id);
CREATE INDEX idx_forum_topics_user ON forum_topics(user_id);
CREATE INDEX idx_forum_topics_created ON forum_topics(created_at DESC);
CREATE INDEX idx_forum_topics_reply_count ON forum_topics(reply_count DESC);
CREATE INDEX idx_forum_topics_not_deleted ON forum_topics(is_deleted) WHERE is_deleted = FALSE;

-- Forum replies indexes
CREATE INDEX idx_forum_replies_topic ON forum_replies(topic_id);
CREATE INDEX idx_forum_replies_parent ON forum_replies(parent_reply_id);
CREATE INDEX idx_forum_replies_user ON forum_replies(user_id);
CREATE INDEX idx_forum_replies_created ON forum_replies(created_at DESC);
CREATE INDEX idx_forum_replies_not_deleted ON forum_replies(is_deleted) WHERE is_deleted = FALSE;

-- Forum attachments indexes
CREATE INDEX idx_forum_attachments_topic ON forum_attachments(topic_id);
CREATE INDEX idx_forum_attachments_reply ON forum_attachments(reply_id);

-- Forum likes indexes
CREATE INDEX idx_forum_likes_reply ON forum_likes(reply_id);
CREATE INDEX idx_forum_likes_user ON forum_likes(user_id);

-- Forum views indexes
CREATE INDEX idx_forum_views_topic ON forum_views(topic_id);
CREATE INDEX idx_forum_views_user ON forum_views(user_id);

-- =====================================================
-- TRIGGERS FOR AUTO-UPDATE
-- =====================================================

-- Trigger: Update topic reply_count when reply added/deleted
CREATE OR REPLACE FUNCTION update_topic_reply_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE forum_topics 
    SET reply_count = reply_count + 1 
    WHERE id = NEW.topic_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE forum_topics 
    SET reply_count = GREATEST(reply_count - 1, 0)
    WHERE id = OLD.topic_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_topic_reply_count
AFTER INSERT OR DELETE ON forum_replies
FOR EACH ROW
EXECUTE FUNCTION update_topic_reply_count();

-- Trigger: Update reply like_count when like added/deleted
CREATE OR REPLACE FUNCTION update_reply_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE forum_replies 
    SET like_count = like_count + 1 
    WHERE id = NEW.reply_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE forum_replies 
    SET like_count = GREATEST(like_count - 1, 0)
    WHERE id = OLD.reply_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_reply_like_count
AFTER INSERT OR DELETE ON forum_likes
FOR EACH ROW
EXECUTE FUNCTION update_reply_like_count();

-- Trigger: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_forum_topics_updated_at
BEFORE UPDATE ON forum_topics
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_forum_replies_updated_at
BEFORE UPDATE ON forum_replies
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE forum_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_views ENABLE ROW LEVEL SECURITY;

-- Policy: All authenticated users can view topics in their courses
CREATE POLICY "Users can view topics in their courses"
ON forum_topics FOR SELECT
TO authenticated
USING (
  course_id IN (
    SELECT course_id FROM student_course_enrollments WHERE student_id = auth.uid()
    UNION
    SELECT id FROM courses WHERE instructor_id = auth.uid()
  )
);

-- Policy: All authenticated users can create topics
CREATE POLICY "Users can create topics"
ON forum_topics FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

-- Policy: Users can update their own topics
CREATE POLICY "Users can update own topics"
ON forum_topics FOR UPDATE
TO authenticated
USING (user_id = auth.uid());

-- Policy: Users can delete their own topics
CREATE POLICY "Users can delete own topics"
ON forum_topics FOR DELETE
TO authenticated
USING (user_id = auth.uid());

-- Similar policies for replies, attachments, likes, views
-- (Add similar RLS policies for other tables)

COMMENT ON TABLE forum_topics IS 'Stores forum topics/posts created by instructors and students';
COMMENT ON TABLE forum_replies IS 'Stores replies/comments to topics, supports threading (max 2 levels)';
COMMENT ON TABLE forum_attachments IS 'Stores file attachments for topics and replies';
COMMENT ON TABLE forum_likes IS 'Tracks likes on replies';
COMMENT ON TABLE forum_views IS 'Tracks topic views by users';
```

### Storage Bucket Setup

```sql
-- Create storage bucket for forum attachments
INSERT INTO storage.buckets (id, name, public)
VALUES ('forum-attachments', 'forum-attachments', false);

-- Storage policies
CREATE POLICY "Authenticated users can upload forum attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'forum-attachments');

CREATE POLICY "Users can view forum attachments"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'forum-attachments');

CREATE POLICY "Users can delete own forum attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'forum-attachments' 
  AND owner = auth.uid()
);
```

---

## 2. BACKEND IMPLEMENTATION

### File Structure

```
backend/
├── controllers/
│   ├── forumController.js
│   └── forumFileController.js
├── routes/
│   └── forumRoutes.js
├── middleware/
│   └── auth.js (already exists)
└── utils/
    └── supabaseClient.js (already exists)
```

### 2.1 Routes: `routes/forumRoutes.js`

```javascript
const express = require('express');
const router = express.Router();
const forumController = require('../controllers/forumController');
const forumFileController = require('../controllers/forumFileController');
const { authenticateToken, requireRole } = require('../middleware/auth');

// All routes require authentication
router.use(authenticateToken);

// =====================================================
// TOPIC ROUTES
// =====================================================

// Create topic (all authenticated users)
router.post('/topics',
  forumController.createTopic
);

// Get topics list with filters
router.get('/topics',
  forumController.getTopics
);

// Get single topic by ID with replies
router.get('/topics/:id',
  forumController.getTopicById
);

// Update topic (own topics only)
router.put('/topics/:id',
  forumController.updateTopic
);

// Delete topic (own topics only)
router.delete('/topics/:id',
  forumController.deleteTopic
);

// Search topics
router.get('/topics/search',
  forumController.searchTopics
);

// Track topic view
router.post('/topics/:id/views',
  forumController.trackTopicView
);

// =====================================================
// REPLY ROUTES
// =====================================================

// Get replies for a topic
router.get('/topics/:topicId/replies',
  forumController.getTopicReplies
);

// Add reply to topic
router.post('/topics/:topicId/replies',
  forumController.addReply
);

// Update reply (own replies only)
router.put('/replies/:id',
  forumController.updateReply
);

// Delete reply (own replies only)
router.delete('/replies/:id',
  forumController.deleteReply
);

// Like/Unlike reply
router.post('/replies/:id/like',
  forumController.toggleLike
);

// =====================================================
// ATTACHMENT ROUTES
// =====================================================

// Upload temp attachment
router.post('/attachments/temp',
  forumFileController.uploadTempAttachment
);

// Finalize attachments for topic
router.post('/topics/:topicId/attachments/finalize',
  forumFileController.finalizeTopicAttachments
);

// Finalize attachments for reply
router.post('/replies/:replyId/attachments/finalize',
  forumFileController.finalizeReplyAttachments
);

// Get attachments for topic
router.get('/topics/:topicId/attachments',
  forumFileController.getTopicAttachments
);

// Get attachments for reply
router.get('/replies/:replyId/attachments',
  forumFileController.getReplyAttachments
);

// Delete attachment
router.delete('/attachments/:id',
  forumFileController.deleteAttachment
);

module.exports = router;
```

### 2.2 Controller: `controllers/forumController.js`

```javascript
const supabase = require('../utils/supabaseClient');

// =====================================================
// TOPIC CONTROLLERS
// =====================================================

/**
 * Create new topic
 * POST /api/forum/topics
 * Body: { course_id, title, content, attachment_ids?: [] }
 */
exports.createTopic = async (req, res) => {
  try {
    const { course_id, title, content } = req.body;
    const user_id = req.user.id;

    // Validation
    if (!course_id || !title || !content) {
      return res.status(400).json({
        success: false,
        message: 'Missing required fields: course_id, title, content'
      });
    }

    if (title.length > 200) {
      return res.status(400).json({
        success: false,
        message: 'Title must be 200 characters or less'
      });
    }

    // Verify user is enrolled in course (student) or owns course (instructor)
    const { data: enrollment, error: enrollmentError } = await supabase
      .from('student_course_enrollments')
      .select('id')
      .eq('student_id', user_id)
      .eq('course_id', course_id)
      .single();

    const { data: course, error: courseError } = await supabase
      .from('courses')
      .select('instructor_id')
      .eq('id', course_id)
      .single();

    const isEnrolled = enrollment || (course && course.instructor_id === user_id);

    if (!isEnrolled) {
      return res.status(403).json({
        success: false,
        message: 'You are not enrolled in this course'
      });
    }

    // Create topic
    const { data: topic, error: topicError } = await supabase
      .from('forum_topics')
      .insert({
        course_id,
        user_id,
        title,
        content
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

    if (topicError) throw topicError;

    res.status(201).json({
      success: true,
      message: 'Topic created successfully',
      data: topic
    });

  } catch (error) {
    console.error('Create topic error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create topic',
      error: error.message
    });
  }
};

/**
 * Get topics list with filters
 * GET /api/forum/topics?course_id=xxx&sort=latest&limit=20&offset=0
 */
exports.getTopics = async (req, res) => {
  try {
    const { 
      course_id, 
      sort = 'latest', // latest, popular, most_replied
      limit = 20, 
      offset = 0 
    } = req.query;
    const user_id = req.user.id;

    if (!course_id) {
      return res.status(400).json({
        success: false,
        message: 'course_id is required'
      });
    }

    // Build query
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
          file_type
        )
      `, { count: 'exact' })
      .eq('course_id', course_id)
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

    // Pagination
    query = query.range(offset, offset + limit - 1);

    const { data: topics, error, count } = await query;

    if (error) throw error;

    res.json({
      success: true,
      data: {
        topics,
        total: count,
        limit: parseInt(limit),
        offset: parseInt(offset)
      }
    });

  } catch (error) {
    console.error('Get topics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch topics',
      error: error.message
    });
  }
};

/**
 * Get single topic by ID with replies
 * GET /api/forum/topics/:id
 */
exports.getTopicById = async (req, res) => {
  try {
    const { id } = req.params;
    const user_id = req.user.id;

    // Get topic
    const { data: topic, error: topicError } = await supabase
      .from('forum_topics')
      .select(`
        *,
        user:users (
          id,
          full_name,
          avatar_url,
          role
        ),
        attachments:forum_attachments!topic_id (
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

    if (topicError) throw topicError;

    if (!topic) {
      return res.status(404).json({
        success: false,
        message: 'Topic not found'
      });
    }

    // Get replies (with nested structure)
    const { data: replies, error: repliesError } = await supabase
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
        user_liked:forum_likes!inner(user_id)
      `)
      .eq('topic_id', id)
      .eq('is_deleted', false)
      .order('created_at', { ascending: true });

    if (repliesError) throw repliesError;

    // Structure replies with nesting (parent -> child)
    const topLevelReplies = replies.filter(r => !r.parent_reply_id);
    const nestedReplies = replies.filter(r => r.parent_reply_id);

    const structuredReplies = topLevelReplies.map(parent => ({
      ...parent,
      is_liked: parent.user_liked?.some(like => like.user_id === user_id) || false,
      replies: nestedReplies
        .filter(child => child.parent_reply_id === parent.id)
        .map(child => ({
          ...child,
          is_liked: child.user_liked?.some(like => like.user_id === user_id) || false
        }))
    }));

    res.json({
      success: true,
      data: {
        topic,
        replies: structuredReplies
      }
    });

  } catch (error) {
    console.error('Get topic error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch topic',
      error: error.message
    });
  }
};

/**
 * Update topic (own topics only)
 * PUT /api/forum/topics/:id
 * Body: { title?, content? }
 */
exports.updateTopic = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, content } = req.body;
    const user_id = req.user.id;

    // Verify ownership
    const { data: topic, error: checkError } = await supabase
      .from('forum_topics')
      .select('user_id')
      .eq('id', id)
      .single();

    if (checkError) throw checkError;

    if (topic.user_id !== user_id) {
      return res.status(403).json({
        success: false,
        message: 'You can only edit your own topics'
      });
    }

    // Update
    const updates = {};
    if (title) updates.title = title;
    if (content) updates.content = content;

    const { data: updatedTopic, error: updateError } = await supabase
      .from('forum_topics')
      .update(updates)
      .eq('id', id)
      .select()
      .single();

    if (updateError) throw updateError;

    res.json({
      success: true,
      message: 'Topic updated successfully',
      data: updatedTopic
    });

  } catch (error) {
    console.error('Update topic error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update topic',
      error: error.message
    });
  }
};

/**
 * Delete topic (soft delete, own topics only)
 * DELETE /api/forum/topics/:id
 */
exports.deleteTopic = async (req, res) => {
  try {
    const { id } = req.params;
    const user_id = req.user.id;

    // Verify ownership
    const { data: topic, error: checkError } = await supabase
      .from('forum_topics')
      .select('user_id')
      .eq('id', id)
      .single();

    if (checkError) throw checkError;

    if (topic.user_id !== user_id) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own topics'
      });
    }

    // Soft delete
    const { error: deleteError } = await supabase
      .from('forum_topics')
      .update({ is_deleted: true })
      .eq('id', id);

    if (deleteError) throw deleteError;

    res.json({
      success: true,
      message: 'Topic deleted successfully'
    });

  } catch (error) {
    console.error('Delete topic error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete topic',
      error: error.message
    });
  }
};

/**
 * Track topic view
 * POST /api/forum/topics/:id/views
 */
exports.trackTopicView = async (req, res) => {
  try {
    const { id } = req.params;
    const user_id = req.user.id;

    // Upsert view tracking
    const { error } = await supabase
      .from('forum_views')
      .upsert(
        {
          topic_id: id,
          user_id,
          view_count: 1,
          last_viewed_at: new Date().toISOString()
        },
        {
          onConflict: 'topic_id,user_id',
          ignoreDuplicates: false
        }
      );

    if (error) throw error;

    // Update topic view_count
    await supabase.rpc('increment_topic_view_count', { topic_id: id });

    res.json({
      success: true,
      message: 'View tracked'
    });

  } catch (error) {
    console.error('Track view error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to track view',
      error: error.message
    });
  }
};

// =====================================================
// REPLY CONTROLLERS
// =====================================================

/**
 * Add reply to topic or reply
 * POST /api/forum/topics/:topicId/replies
 * Body: { content, parent_reply_id? }
 */
exports.addReply = async (req, res) => {
  try {
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
    const { data: reply, error: replyError } = await supabase
      .from('forum_replies')
      .insert({
        topic_id: topicId,
        user_id,
        parent_reply_id,
        content
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

    if (replyError) throw replyError;

    res.status(201).json({
      success: true,
      message: 'Reply added successfully',
      data: reply
    });

  } catch (error) {
    console.error('Add reply error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to add reply',
      error: error.message
    });
  }
};

/**
 * Get replies for a topic
 * GET /api/forum/topics/:topicId/replies
 */
exports.getTopicReplies = async (req, res) => {
  try {
    const { topicId } = req.params;
    const user_id = req.user.id;

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
      is_liked: reply.likes?.some(like => like.user_id === user_id) || false,
      likes: undefined // Remove likes array from response
    }));

    // Structure with nesting
    const topLevel = repliesWithLikeStatus.filter(r => !r.parent_reply_id);
    const nested = repliesWithLikeStatus.filter(r => r.parent_reply_id);

    const structured = topLevel.map(parent => ({
      ...parent,
      replies: nested.filter(child => child.parent_reply_id === parent.id)
    }));

    res.json({
      success: true,
      data: structured
    });

  } catch (error) {
    console.error('Get replies error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch replies',
      error: error.message
    });
  }
};

/**
 * Update reply (own replies only)
 * PUT /api/forum/replies/:id
 * Body: { content }
 */
exports.updateReply = async (req, res) => {
  try {
    const { id } = req.params;
    const { content } = req.body;
    const user_id = req.user.id;

    // Verify ownership
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
    const { data: updatedReply, error: updateError } = await supabase
      .from('forum_replies')
      .update({ content })
      .eq('id', id)
      .select()
      .single();

    if (updateError) throw updateError;

    res.json({
      success: true,
      message: 'Reply updated successfully',
      data: updatedReply
    });

  } catch (error) {
    console.error('Update reply error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update reply',
      error: error.message
    });
  }
};

/**
 * Delete reply (soft delete, own replies only)
 * DELETE /api/forum/replies/:id
 */
exports.deleteReply = async (req, res) => {
  try {
    const { id } = req.params;
    const user_id = req.user.id;

    // Verify ownership
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
    const { error: deleteError } = await supabase
      .from('forum_replies')
      .update({ is_deleted: true })
      .eq('id', id);

    if (deleteError) throw deleteError;

    res.json({
      success: true,
      message: 'Reply deleted successfully'
    });

  } catch (error) {
    console.error('Delete reply error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete reply',
      error: error.message
    });
  }
};

/**
 * Toggle like on reply
 * POST /api/forum/replies/:id/like
 */
exports.toggleLike = async (req, res) => {
  try {
    const { id } = req.params;
    const user_id = req.user.id;

    // Check if already liked
    const { data: existingLike, error: checkError } = await supabase
      .from('forum_likes')
      .select('id')
      .eq('reply_id', id)
      .eq('user_id', user_id)
      .single();

    if (existingLike) {
      // Unlike
      const { error: deleteError } = await supabase
        .from('forum_likes')
        .delete()
        .eq('id', existingLike.id);

      if (deleteError) throw deleteError;

      res.json({
        success: true,
        message: 'Reply unliked',
        data: { is_liked: false }
      });
    } else {
      // Like
      const { error: insertError } = await supabase
        .from('forum_likes')
        .insert({
          reply_id: id,
          user_id
        });

      if (insertError) throw insertError;

      res.json({
        success: true,
        message: 'Reply liked',
        data: { is_liked: true }
      });
    }

  } catch (error) {
    console.error('Toggle like error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle like',
      error: error.message
    });
  }
};

/**
 * Search topics
 * GET /api/forum/topics/search?q=keyword&course_id=xxx
 */
exports.searchTopics = async (req, res) => {
  try {
    const { q, course_id } = req.query;

    if (!q || !course_id) {
      return res.status(400).json({
        success: false,
        message: 'Query (q) and course_id are required'
      });
    }

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
      .eq('course_id', course_id)
      .eq('is_deleted', false)
      .or(`title.ilike.%${q}%,content.ilike.%${q}%`)
      .order('created_at', { ascending: false })
      .limit(20);

    if (error) throw error;

    res.json({
      success: true,
      data: topics
    });

  } catch (error) {
    console.error('Search topics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search topics',
      error: error.message
    });
  }
};
```

### 2.3 File Controller: `controllers/forumFileController.js`

```javascript
const supabase = require('../utils/supabaseClient');
const { v4: uuidv4 } = require('uuid');

/**
 * Upload temporary attachment
 * POST /api/forum/attachments/temp
 * Multipart form-data: file
 */
exports.uploadTempAttachment = async (req, res) => {
  try {
    // TODO: Implement file upload logic
    // This will be handled by frontend multipart upload
    
    res.status(501).json({
      success: false,
      message: 'File upload to be implemented'
    });

  } catch (error) {
    console.error('Upload temp attachment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to upload attachment',
      error: error.message
    });
  }
};

/**
 * Finalize topic attachments
 * POST /api/forum/topics/:topicId/attachments/finalize
 * Body: { attachment_ids: [] }
 */
exports.finalizeTopicAttachments = async (req, res) => {
  try {
    // TODO: Link temp attachments to topic
    res.status(501).json({
      success: false,
      message: 'Finalize attachments to be implemented'
    });
  } catch (error) {
    console.error('Finalize topic attachments error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to finalize attachments',
      error: error.message
    });
  }
};

/**
 * Finalize reply attachments
 * POST /api/forum/replies/:replyId/attachments/finalize
 * Body: { attachment_ids: [] }
 */
exports.finalizeReplyAttachments = async (req, res) => {
  try {
    // TODO: Link temp attachments to reply
    res.status(501).json({
      success: false,
      message: 'Finalize attachments to be implemented'
    });
  } catch (error) {
    console.error('Finalize reply attachments error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to finalize attachments',
      error: error.message
    });
  }
};

/**
 * Get topic attachments
 * GET /api/forum/topics/:topicId/attachments
 */
exports.getTopicAttachments = async (req, res) => {
  try {
    const { topicId } = req.params;

    const { data: attachments, error } = await supabase
      .from('forum_attachments')
      .select('*')
      .eq('topic_id', topicId);

    if (error) throw error;

    res.json({
      success: true,
      data: attachments
    });

  } catch (error) {
    console.error('Get topic attachments error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch attachments',
      error: error.message
    });
  }
};

/**
 * Get reply attachments
 * GET /api/forum/replies/:replyId/attachments
 */
exports.getReplyAttachments = async (req, res) => {
  try {
    const { replyId } = req.params;

    const { data: attachments, error } = await supabase
      .from('forum_attachments')
      .select('*')
      .eq('reply_id', replyId);

    if (error) throw error;

    res.json({
      success: true,
      data: attachments
    });

  } catch (error) {
    console.error('Get reply attachments error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch attachments',
      error: error.message
    });
  }
};

/**
 * Delete attachment
 * DELETE /api/forum/attachments/:id
 */
exports.deleteAttachment = async (req, res) => {
  try {
    const { id } = req.params;
    const user_id = req.user.id;

    // Get attachment and verify ownership through topic/reply
    const { data: attachment, error: fetchError } = await supabase
      .from('forum_attachments')
      .select(`
        *,
        topic:forum_topics!topic_id(user_id),
        reply:forum_replies!reply_id(user_id)
      `)
      .eq('id', id)
      .single();

    if (fetchError) throw fetchError;

    const owner_id = attachment.topic?.user_id || attachment.reply?.user_id;

    if (owner_id !== user_id) {
      return res.status(403).json({
        success: false,
        message: 'You can only delete your own attachments'
      });
    }

    // Delete from storage
    const { error: storageError } = await supabase
      .storage
      .from('forum-attachments')
      .remove([attachment.storage_path]);

    if (storageError) throw storageError;

    // Delete from database
    const { error: deleteError } = await supabase
      .from('forum_attachments')
      .delete()
      .eq('id', id);

    if (deleteError) throw deleteError;

    res.json({
      success: true,
      message: 'Attachment deleted successfully'
    });

  } catch (error) {
    console.error('Delete attachment error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete attachment',
      error: error.message
    });
  }
};
```

---

## 3. FRONTEND IMPLEMENTATION

### File Structure

```
lib/
├── data/
│   ├── models/
│   │   ├── request/
│   │   │   ├── create_topic_request.dart
│   │   │   ├── create_reply_request.dart
│   │   │   └── update_topic_request.dart
│   │   └── response/
│   │       ├── forum_topic_response.dart
│   │       ├── forum_reply_response.dart
│   │       ├── forum_attachment_response.dart
│   │       └── user_response.dart
│   ├── services/
│   │   └── forum_api.dart (Retrofit)
│   └── repositories/
│       └── forum_repository.dart
├── presentation/
│   ├── controllers/
│   │   ├── forum_controller.dart
│   │   └── forum_detail_controller.dart
│   ├── pages/
│   │   ├── forum_feed_page.dart
│   │   ├── forum_detail_page.dart
│   │   └── create_topic_page.dart
│   └── widgets/
│       ├── topic_card.dart
│       ├── reply_card.dart
│       └── reply_input.dart
└── bindings/
    └── forum_binding.dart
```

### 3.1 Models - Request

**`models/request/create_topic_request.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'create_topic_request.g.dart';

@JsonSerializable()
class CreateTopicRequest {
  @JsonKey(name: 'course_id')
  final String courseId;
  
  final String title;
  final String content;
  
  @JsonKey(name: 'attachment_ids')
  final List<String>? attachmentIds;

  CreateTopicRequest({
    required this.courseId,
    required this.title,
    required this.content,
    this.attachmentIds,
  });

  factory CreateTopicRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTopicRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTopicRequestToJson(this);
}
```

**`models/request/create_reply_request.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'create_reply_request.g.dart';

@JsonSerializable()
class CreateReplyRequest {
  final String content;
  
  @JsonKey(name: 'parent_reply_id')
  final String? parentReplyId;
  
  @JsonKey(name: 'attachment_ids')
  final List<String>? attachmentIds;

  CreateReplyRequest({
    required this.content,
    this.parentReplyId,
    this.attachmentIds,
  });

  factory CreateReplyRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateReplyRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateReplyRequestToJson(this);
}
```

**`models/request/update_topic_request.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'update_topic_request.g.dart';

@JsonSerializable()
class UpdateTopicRequest {
  final String? title;
  final String? content;

  UpdateTopicRequest({
    this.title,
    this.content,
  });

  factory UpdateTopicRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTopicRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateTopicRequestToJson(this);
}
```

### 3.2 Models - Response

**`models/response/user_response.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user_response.g.dart';

@JsonSerializable()
class UserResponse {
  final String id;
  
  @JsonKey(name: 'full_name')
  final String fullName;
  
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  
  final String role; // 'instructor' or 'student'

  UserResponse({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.role,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) =>
      _$UserResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserResponseToJson(this);
  
  bool get isInstructor => role == 'instructor';
}
```

**`models/response/forum_attachment_response.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';

part 'forum_attachment_response.g.dart';

@JsonSerializable()
class ForumAttachmentResponse {
  final String id;
  
  @JsonKey(name: 'file_name')
  final String fileName;
  
  @JsonKey(name: 'file_url')
  final String fileUrl;
  
  @JsonKey(name: 'file_size')
  final int fileSize;
  
  @JsonKey(name: 'file_type')
  final String fileType;

  ForumAttachmentResponse({
    required this.id,
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.fileType,
  });

  factory ForumAttachmentResponse.fromJson(Map<String, dynamic> json) =>
      _$ForumAttachmentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ForumAttachmentResponseToJson(this);
  
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

**`models/response/forum_reply_response.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';
import 'user_response.dart';
import 'forum_attachment_response.dart';

part 'forum_reply_response.g.dart';

@JsonSerializable()
class ForumReplyResponse {
  final String id;
  
  @JsonKey(name: 'topic_id')
  final String topicId;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  @JsonKey(name: 'parent_reply_id')
  final String? parentReplyId;
  
  final String content;
  
  @JsonKey(name: 'like_count')
  final int likeCount;
  
  @JsonKey(name: 'is_liked')
  final bool isLiked;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  final UserResponse user;
  
  final List<ForumAttachmentResponse>? attachments;
  
  final List<ForumReplyResponse>? replies; // Nested replies

  ForumReplyResponse({
    required this.id,
    required this.topicId,
    required this.userId,
    this.parentReplyId,
    required this.content,
    required this.likeCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    this.attachments,
    this.replies,
  });

  factory ForumReplyResponse.fromJson(Map<String, dynamic> json) =>
      _$ForumReplyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ForumReplyResponseToJson(this);
  
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;
  bool get hasReplies => replies != null && replies!.isNotEmpty;
  bool get isNested => parentReplyId != null;
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${(difference.inDays / 7).floor()}w';
  }
}
```

**`models/response/forum_topic_response.dart`**

```dart
import 'package:json_annotation/json_annotation.dart';
import 'user_response.dart';
import 'forum_attachment_response.dart';

part 'forum_topic_response.g.dart';

@JsonSerializable()
class ForumTopicResponse {
  final String id;
  
  @JsonKey(name: 'course_id')
  final String courseId;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  final String title;
  final String content;
  
  @JsonKey(name: 'reply_count')
  final int replyCount;
  
  @JsonKey(name: 'view_count')
  final int viewCount;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  
  final UserResponse user;
  
  final List<ForumAttachmentResponse>? attachments;

  ForumTopicResponse({
    required this.id,
    required this.courseId,
    required this.userId,
    required this.title,
    required this.content,
    required this.replyCount,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    this.attachments,
  });

  factory ForumTopicResponse.fromJson(Map<String, dynamic> json) =>
      _$ForumTopicResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ForumTopicResponseToJson(this);
  
  String get contentPreview {
    if (content.length <= 150) return content;
    return '${content.substring(0, 150)}...';
  }
  
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}
```

### 3.3 API Service (Retrofit)

**`services/forum_api.dart`**

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../models/request/create_topic_request.dart';
import '../models/request/create_reply_request.dart';
import '../models/request/update_topic_request.dart';
import '../models/response/forum_topic_response.dart';
import '../models/response/forum_reply_response.dart';

part 'forum_api.g.dart';

@RestApi()
abstract class ForumApi {
  factory ForumApi(Dio dio, {String baseUrl}) = _ForumApi;

  // =====================================================
  // TOPICS
  // =====================================================
  
  @POST('/forum/topics')
  Future<ApiResponse<ForumTopicResponse>> createTopic(
    @Body() CreateTopicRequest request,
  );
  
  @GET('/forum/topics')
  Future<ApiResponse<ForumTopicsListResponse>> getTopics(
    @Query('course_id') String courseId,
    @Query('sort') String? sort, // latest, popular, most_replied
    @Query('limit') int? limit,
    @Query('offset') int? offset,
  );
  
  @GET('/forum/topics/{id}')
  Future<ApiResponse<ForumTopicDetailResponse>> getTopicById(
    @Path('id') String id,
  );
  
  @PUT('/forum/topics/{id}')
  Future<ApiResponse<ForumTopicResponse>> updateTopic(
    @Path('id') String id,
    @Body() UpdateTopicRequest request,
  );
  
  @DELETE('/forum/topics/{id}')
  Future<ApiResponse<void>> deleteTopic(
    @Path('id') String id,
  );
  
  @POST('/forum/topics/{id}/views')
  Future<ApiResponse<void>> trackTopicView(
    @Path('id') String id,
  );
  
  @GET('/forum/topics/search')
  Future<ApiResponse<List<ForumTopicResponse>>> searchTopics(
    @Query('q') String query,
    @Query('course_id') String courseId,
  );

  // =====================================================
  // REPLIES
  // =====================================================
  
  @GET('/forum/topics/{topicId}/replies')
  Future<ApiResponse<List<ForumReplyResponse>>> getTopicReplies(
    @Path('topicId') String topicId,
  );
  
  @POST('/forum/topics/{topicId}/replies')
  Future<ApiResponse<ForumReplyResponse>> addReply(
    @Path('topicId') String topicId,
    @Body() CreateReplyRequest request,
  );
  
  @PUT('/forum/replies/{id}')
  Future<ApiResponse<ForumReplyResponse>> updateReply(
    @Path('id') String id,
    @Body() Map<String, dynamic> request, // { content: string }
  );
  
  @DELETE('/forum/replies/{id}')
  Future<ApiResponse<void>> deleteReply(
    @Path('id') String id,
  );
  
  @POST('/forum/replies/{id}/like')
  Future<ApiResponse<LikeResponse>> toggleLike(
    @Path('id') String id,
  );

  // =====================================================
  // ATTACHMENTS (TODO)
  // =====================================================
  
  @POST('/forum/attachments/temp')
  @MultiPart()
  Future<ApiResponse<AttachmentResponse>> uploadTempAttachment(
    @Part(name: 'file') File file,
  );
}

// Response wrapper models
@JsonSerializable()
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseFromJson(json, fromJsonT);
}

@JsonSerializable()
class ForumTopicsListResponse {
  final List<ForumTopicResponse> topics;
  final int total;
  final int limit;
  final int offset;

  ForumTopicsListResponse({
    required this.topics,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ForumTopicsListResponse.fromJson(Map<String, dynamic> json) =>
      _$ForumTopicsListResponseFromJson(json);
}

@JsonSerializable()
class ForumTopicDetailResponse {
  final ForumTopicResponse topic;
  final List<ForumReplyResponse> replies;

  ForumTopicDetailResponse({
    required this.topic,
    required this.replies,
  });

  factory ForumTopicDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$ForumTopicDetailResponseFromJson(json);
}

@JsonSerializable()
class LikeResponse {
  @JsonKey(name: 'is_liked')
  final bool isLiked;

  LikeResponse({required this.isLiked});

  factory LikeResponse.fromJson(Map<String, dynamic> json) =>
      _$LikeResponseFromJson(json);
}

// TODO: Attachment response model for file upload
@JsonSerializable()
class AttachmentResponse {
  final String id;
  @JsonKey(name: 'file_url')
  final String fileUrl;
  @JsonKey(name: 'file_name')
  final String fileName;

  AttachmentResponse({
    required this.id,
    required this.fileUrl,
    required this.fileName,
  });

  factory AttachmentResponse.fromJson(Map<String, dynamic> json) =>
      _$AttachmentResponseFromJson(json);
}
```

### 3.4 Controllers (GetX)

**`controllers/forum_controller.dart`**

```dart
import 'package:get/get.dart';
import '../data/models/response/forum_topic_response.dart';
import '../data/services/forum_api.dart';

class ForumController extends GetxController {
  final ForumApi _forumApi;
  
  ForumController(this._forumApi);

  // State
  final topics = <ForumTopicResponse>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  
  // Filters
  final selectedSort = 'latest'.obs; // latest, popular, most_replied
  final searchQuery = ''.obs;
  
  // Pagination
  final int _limit = 20;
  int _offset = 0;
  
  // Current course
  String? courseId;

  @override
  void onInit() {
    super.onInit();
    // Get courseId from arguments when navigating
    courseId = Get.arguments?['courseId'];
    if (courseId != null) {
      loadTopics();
    }
  }

  /// Load initial topics
  Future<void> loadTopics({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      hasMore.value = true;
    }
    
    isLoading.value = true;
    
    try {
      final response = await _forumApi.getTopics(
        courseId!,
        selectedSort.value,
        _limit,
        _offset,
      );

      if (response.data != null) {
        if (refresh) {
          topics.value = response.data!.topics;
        } else {
          topics.addAll(response.data!.topics);
        }
        
        hasMore.value = response.data!.topics.length >= _limit;
        _offset += response.data!.topics.length;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load topics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Load more topics (pagination)
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    
    isLoadingMore.value = true;
    
    try {
      final response = await _forumApi.getTopics(
        courseId!,
        selectedSort.value,
        _limit,
        _offset,
      );

      if (response.data != null) {
        topics.addAll(response.data!.topics);
        hasMore.value = response.data!.topics.length >= _limit;
        _offset += response.data!.topics.length;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load more topics: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  /// Change sort order
  void changeSort(String sort) {
    selectedSort.value = sort;
    loadTopics(refresh: true);
  }

  /// Search topics
  Future<void> searchTopics(String query) async {
    if (query.isEmpty) {
      loadTopics(refresh: true);
      return;
    }
    
    searchQuery.value = query;
    isLoading.value = true;
    
    try {
      final response = await _forumApi.searchTopics(query, courseId!);
      
      if (response.data != null) {
        topics.value = response.data!;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to search topics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete topic
  Future<void> deleteTopic(String topicId) async {
    try {
      await _forumApi.deleteTopic(topicId);
      topics.removeWhere((topic) => topic.id == topicId);
      Get.snackbar('Success', 'Topic deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete topic: $e');
    }
  }

  /// Navigate to create topic page
  void goToCreateTopic() {
    Get.toNamed('/forum/create', arguments: {'courseId': courseId});
  }

  /// Navigate to topic detail
  void goToTopicDetail(String topicId) {
    Get.toNamed('/forum/topic/$topicId');
  }
}
```

**`controllers/forum_detail_controller.dart`**

```dart
import 'package:get/get.dart';
import '../data/models/response/forum_topic_response.dart';
import '../data/models/response/forum_reply_response.dart';
import '../data/models/request/create_reply_request.dart';
import '../data/services/forum_api.dart';

class ForumDetailController extends GetxController {
  final ForumApi _forumApi;
  
  ForumDetailController(this._forumApi);

  // State
  final Rxn<ForumTopicResponse> topic = Rxn<ForumTopicResponse>();
  final replies = <ForumReplyResponse>[].obs;
  final isLoading = false.obs;
  final isPostingReply = false.obs;
  
  // Reply input
  final replyContent = ''.obs;
  final replyingTo = Rxn<ForumReplyResponse>(); // For nested replies
  
  String? topicId;

  @override
  void onInit() {
    super.onInit();
    topicId = Get.parameters['id'] ?? Get.arguments?['topicId'];
    if (topicId != null) {
      loadTopicDetail();
    }
  }

  /// Load topic with replies
  Future<void> loadTopicDetail() async {
    isLoading.value = true;
    
    try {
      // Track view
      await _forumApi.trackTopicView(topicId!);
      
      // Get topic detail
      final response = await _forumApi.getTopicById(topicId!);
      
      if (response.data != null) {
        topic.value = response.data!.topic;
        replies.value = response.data!.replies;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load topic: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Post reply
  Future<void> postReply() async {
    if (replyContent.value.trim().isEmpty) {
      Get.snackbar('Error', 'Reply cannot be empty');
      return;
    }
    
    if (replyContent.value.length > 500) {
      Get.snackbar('Error', 'Reply must be 500 characters or less');
      return;
    }
    
    isPostingReply.value = true;
    
    try {
      final request = CreateReplyRequest(
        content: replyContent.value.trim(),
        parentReplyId: replyingTo.value?.id,
      );
      
      final response = await _forumApi.addReply(topicId!, request);
      
      if (response.data != null) {
        // Add reply to list
        if (replyingTo.value != null) {
          // Nested reply - find parent and add to its replies
          final parentIndex = replies.indexWhere((r) => r.id == replyingTo.value!.id);
          if (parentIndex != -1) {
            final updatedParent = replies[parentIndex];
            final updatedReplies = List<ForumReplyResponse>.from(updatedParent.replies ?? []);
            updatedReplies.add(response.data!);
            
            // Update parent with new nested reply
            replies[parentIndex] = ForumReplyResponse(
              id: updatedParent.id,
              topicId: updatedParent.topicId,
              userId: updatedParent.userId,
              parentReplyId: updatedParent.parentReplyId,
              content: updatedParent.content,
              likeCount: updatedParent.likeCount,
              isLiked: updatedParent.isLiked,
              createdAt: updatedParent.createdAt,
              updatedAt: updatedParent.updatedAt,
              user: updatedParent.user,
              attachments: updatedParent.attachments,
              replies: updatedReplies,
            );
          }
        } else {
          // Top-level reply
          replies.add(response.data!);
        }
        
        // Clear input
        replyContent.value = '';
        replyingTo.value = null;
        
        // Update reply count
        if (topic.value != null) {
          topic.value = ForumTopicResponse(
            id: topic.value!.id,
            courseId: topic.value!.courseId,
            userId: topic.value!.userId,
            title: topic.value!.title,
            content: topic.value!.content,
            replyCount: topic.value!.replyCount + 1,
            viewCount: topic.value!.viewCount,
            createdAt: topic.value!.createdAt,
            updatedAt: topic.value!.updatedAt,
            user: topic.value!.user,
            attachments: topic.value!.attachments,
          );
        }
        
        Get.snackbar('Success', 'Reply posted successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to post reply: $e');
    } finally {
      isPostingReply.value = false;
    }
  }

  /// Set replying to (for nested replies)
  void setReplyingTo(ForumReplyResponse reply) {
    replyingTo.value = reply;
  }

  /// Cancel replying to
  void cancelReplyingTo() {
    replyingTo.value = null;
    replyContent.value = '';
  }

  /// Toggle like on reply
  Future<void> toggleLike(String replyId) async {
    try {
      final response = await _forumApi.toggleLike(replyId);
      
      if (response.data != null) {
        // Update reply in list
        final index = replies.indexWhere((r) => r.id == replyId);
        if (index != -1) {
          final reply = replies[index];
          final newLikeCount = response.data!.isLiked 
              ? reply.likeCount + 1 
              : reply.likeCount - 1;
          
          replies[index] = ForumReplyResponse(
            id: reply.id,
            topicId: reply.topicId,
            userId: reply.userId,
            parentReplyId: reply.parentReplyId,
            content: reply.content,
            likeCount: newLikeCount,
            isLiked: response.data!.isLiked,
            createdAt: reply.createdAt,
            updatedAt: reply.updatedAt,
            user: reply.user,
            attachments: reply.attachments,
            replies: reply.replies,
          );
        } else {
          // Check nested replies
          for (var i = 0; i < replies.length; i++) {
            final nestedIndex = replies[i].replies?.indexWhere((r) => r.id == replyId) ?? -1;
            if (nestedIndex != -1) {
              final parent = replies[i];
              final nested = parent.replies![nestedIndex];
              final newLikeCount = response.data!.isLiked 
                  ? nested.likeCount + 1 
                  : nested.likeCount - 1;
              
              final updatedNested = ForumReplyResponse(
                id: nested.id,
                topicId: nested.topicId,
                userId: nested.userId,
                parentReplyId: nested.parentReplyId,
                content: nested.content,
                likeCount: newLikeCount,
                isLiked: response.data!.isLiked,
                createdAt: nested.createdAt,
                updatedAt: nested.updatedAt,
                user: nested.user,
                attachments: nested.attachments,
                replies: nested.replies,
              );
              
              final updatedRepliesList = List<ForumReplyResponse>.from(parent.replies!);
              updatedRepliesList[nestedIndex] = updatedNested;
              
              replies[i] = ForumReplyResponse(
                id: parent.id,
                topicId: parent.topicId,
                userId: parent.userId,
                parentReplyId: parent.parentReplyId,
                content: parent.content,
                likeCount: parent.likeCount,
                isLiked: parent.isLiked,
                createdAt: parent.createdAt,
                updatedAt: parent.updatedAt,
                user: parent.user,
                attachments: parent.attachments,
                replies: updatedRepliesList,
              );
              break;
            }
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to like reply: $e');
    }
  }

  /// Delete reply
  Future<void> deleteReply(String replyId) async {
    try {
      await _forumApi.deleteReply(replyId);
      
      // Remove from list
      replies.removeWhere((r) => r.id == replyId);
      
      // Also check nested replies
      for (var i = 0; i < replies.length; i++) {
        if (replies[i].replies != null) {
          replies[i].replies!.removeWhere((r) => r.id == replyId);
        }
      }
      
      Get.snackbar('Success', 'Reply deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete reply: $e');
    }
  }

  /// Update topic
  Future<void> updateTopic(String newTitle, String newContent) async {
    try {
      final request = UpdateTopicRequest(
        title: newTitle,
        content: newContent,
      );
      
      final response = await _forumApi.updateTopic(topicId!, request);
      
      if (response.data != null) {
        topic.value = response.data!;
        Get.snackbar('Success', 'Topic updated successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update topic: $e');
    }
  }

  /// Delete topic
  Future<void> deleteTopic() async {
    try {
      await _forumApi.deleteTopic(topicId!);
      Get.back(); // Go back to forum feed
      Get.snackbar('Success', 'Topic deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete topic: $e');
    }
  }
}
```

### 3.5 Binding

**`bindings/forum_binding.dart`**

```dart
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../data/services/forum_api.dart';
import '../presentation/controllers/forum_controller.dart';
import '../presentation/controllers/forum_detail_controller.dart';

class ForumBinding extends Bindings {
  @override
  void dependencies() {
    // Create Dio instance with base configuration
    final dio = Dio(BaseOptions(
      baseUrl: 'YOUR_API_BASE_URL', // Replace with actual base URL
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add auth interceptor
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get token from storage (e.g., GetStorage, SharedPreferences)
        final token = 'YOUR_AUTH_TOKEN'; // Replace with actual token retrieval
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
    
    // Register ForumApi
    Get.lazyPut<ForumApi>(() => ForumApi(dio));
    
    // Register controllers
    Get.lazyPut<ForumController>(() => ForumController(Get.find()));
    Get.lazyPut<ForumDetailController>(() => ForumDetailController(Get.find()));
  }
}
```

### 3.6 Routes Configuration

Add to your `app_routes.dart`:

```dart
class AppRoutes {
  static const forum = '/forum';
  static const forumCreate = '/forum/create';
  static const forumTopic = '/forum/topic/:id';
}

// In your GetPages:
GetPage(
  name: AppRoutes.forum,
  page: () => ForumFeedPage(),
  binding: ForumBinding(),
),
GetPage(
  name: AppRoutes.forumCreate,
  page: () => CreateTopicPage(),
  binding: ForumBinding(),
),
GetPage(
  name: AppRoutes.forumTopic,
  page: () => ForumDetailPage(),
  binding: ForumBinding(),
),
```

---

## 📝 IMPLEMENTATION CHECKLIST

### Backend
- [ ] Run database migration `001_create_forum_tables.sql`
- [ ] Setup storage bucket for forum attachments
- [ ] Implement `forumController.js` with all endpoints
- [ ] Implement `forumFileController.js` (TODO: file upload logic)
- [ ] Setup routes in `forumRoutes.js`
- [ ] Test all API endpoints with Postman/Insomnia

### Frontend
- [ ] Generate JSON serialization code: `flutter pub run build_runner build`
- [ ] Create all request models
- [ ] Create all response models
- [ ] Setup Retrofit API service
- [ ] Implement ForumController (GetX)
- [ ] Implement ForumDetailController (GetX)
- [ ] Setup ForumBinding
- [ ] Configure routes
- [ ] TODO: Implement file picker logic for attachments
- [ ] TODO: Implement attachment upload flow

### UI (Next Phase)
- [ ] Build ForumFeedPage (list of topics)
- [ ] Build TopicCard widget
- [ ] Build CreateTopicPage (bottom sheet)
- [ ] Build ForumDetailPage (topic with replies)
- [ ] Build ReplyCard widget (with threading)
- [ ] Build ReplyInput widget
---

## 🎯 NEXT STEPS FOR AI

1. **Run database migration** on Supabase
2. **Implement backend controllers** following the provided structure
3. **Generate Dart models** using `build_runner`
4. **Setup Retrofit API** with proper authentication
5. **Implement GetX controllers** for state management
6. **Build UI pages** following Threads-inspired design from previous doc
