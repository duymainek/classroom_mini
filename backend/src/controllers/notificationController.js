const supabase = require('../services/supabaseClient').supabase;

const notificationController = {
  async getAll(req, res) {
    try {
      const userId = req.user?.id;
      const { limit = 50, offset = 0, unreadOnly = false } = req.query;

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'User not authenticated'
        });
      }

      let query = supabase
        .from('notifications')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .range(offset, offset + limit - 1);

      if (unreadOnly === 'true') {
        query = query.eq('is_read', false);
      }

      const { data, error, count } = await query;

      if (error) throw error;

      return res.json({
        success: true,
        data: {
          notifications: data || [],
          total: count,
          limit: parseInt(limit),
          offset: parseInt(offset)
        }
      });
    } catch (error) {
      console.error('Error fetching notifications:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch notifications',
        error: error.message
      });
    }
  },

  async getUnreadCount(req, res) {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'User not authenticated'
        });
      }

      const { count, error } = await supabase
        .from('notifications')
        .select('id', { count: 'exact', head: true })
        .eq('user_id', userId)
        .eq('is_read', false);

      if (error) throw error;

      return res.json({
        success: true,
        data: {
          unreadCount: count || 0
        }
      });
    } catch (error) {
      console.error('Error fetching unread count:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to fetch unread count',
        error: error.message
      });
    }
  },

  async markAsRead(req, res) {
    try {
      const userId = req.user?.id;
      const { id } = req.params;

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'User not authenticated'
        });
      }

      const { data, error } = await supabase
        .from('notifications')
        .update({
          is_read: true,
          read_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('id', id)
        .eq('user_id', userId)
        .select()
        .single();

      if (error) throw error;

      return res.json({
        success: true,
        message: 'Notification marked as read',
        data: data
      });
    } catch (error) {
      console.error('Error marking notification as read:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to mark notification as read',
        error: error.message
      });
    }
  },

  async markAllAsRead(req, res) {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'User not authenticated'
        });
      }

      const { data, error } = await supabase
        .from('notifications')
        .update({
          is_read: true,
          read_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        })
        .eq('user_id', userId)
        .eq('is_read', false)
        .select();

      if (error) throw error;

      return res.json({
        success: true,
        message: `Marked ${data.length} notifications as read`,
        data: {
          updatedCount: data.length
        }
      });
    } catch (error) {
      console.error('Error marking all notifications as read:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to mark all notifications as read',
        error: error.message
      });
    }
  },

  async deleteNotification(req, res) {
    try {
      const userId = req.user?.id;
      const { id } = req.params;

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'User not authenticated'
        });
      }

      const { error } = await supabase
        .from('notifications')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);

      if (error) throw error;

      return res.json({
        success: true,
        message: 'Notification deleted successfully'
      });
    } catch (error) {
      console.error('Error deleting notification:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to delete notification',
        error: error.message
      });
    }
  },

  async deleteAllRead(req, res) {
    try {
      const userId = req.user?.id;

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'User not authenticated'
        });
      }

      const { data, error } = await supabase
        .from('notifications')
        .delete()
        .eq('user_id', userId)
        .eq('is_read', true)
        .select();

      if (error) throw error;

      return res.json({
        success: true,
        message: `Deleted ${data?.length || 0} read notifications`,
        data: {
          deletedCount: data?.length || 0
        }
      });
    } catch (error) {
      console.error('Error deleting all read notifications:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to delete all read notifications',
        error: error.message
      });
    }
  },

  async createNotification(userId, notificationData) {
    try {
      const { type, title, body, data = {} } = notificationData;

      const { data: notification, error } = await supabase
        .from('notifications')
        .insert({
          user_id: userId,
          type,
          title,
          body,
          data,
          is_read: false,
          created_at: new Date().toISOString()
        })
        .select()
        .single();

      if (error) throw error;

      return { success: true, data: notification };
    } catch (error) {
      console.error('Error creating notification:', error);
      return { success: false, error: error.message };
    }
  },

  async notifyStudentsInGroups(groupIds, notificationData) {
    try {
      const { data: enrollments, error: enrollmentError } = await supabase
        .from('student_enrollments')
        .select('student_id')
        .in('group_id', groupIds)
        .eq('is_active', true);

      if (enrollmentError) throw enrollmentError;

      const studentIds = [...new Set(enrollments.map(e => e.student_id))];

      const notifications = studentIds.map(studentId => ({
        user_id: studentId,
        type: notificationData.type,
        title: notificationData.title,
        body: notificationData.body,
        data: notificationData.data || {},
        is_read: false,
        created_at: new Date().toISOString()
      }));

      const { data, error } = await supabase
        .from('notifications')
        .insert(notifications)
        .select();

      if (error) throw error;

      return { success: true, data, count: notifications.length };
    } catch (error) {
      console.error('Error notifying students in groups:', error);
      return { success: false, error: error.message };
    }
  }
};

module.exports = notificationController;

