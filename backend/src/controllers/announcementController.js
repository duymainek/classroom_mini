const { supabase } = require('../services/supabaseClient');
const { buildResponse } = require('../utils/response');
const { catchAsync } = require('../middleware/errorHandler');
const notificationController = require('./notificationController');

/**
 * Announcement Controller
 * Handles all announcement-related operations
 */
class AnnouncementController {
  /**
   * Create new announcement
   */
  createAnnouncement = catchAsync(async (req, res) => {
    const {
      title,
      content,
      courseId,
      scopeType,
      groupIds = [],
      attachmentIds = []
    } = req.body;

    const instructorId = req.user.id;

    // Validate scope type and group IDs
    if (scopeType === 'one_group' && (!groupIds || groupIds.length !== 1)) {
      return res.status(400).json(
        buildResponse(false, 'One group scope requires exactly one group ID')
      );
    }

    if (scopeType === 'multiple_groups' && (!groupIds || groupIds.length === 0)) {
      return res.status(400).json(
        buildResponse(false, 'Multiple groups scope requires at least one group ID')
      );
    }

    // Start transaction
    const { data: announcement, error: announcementError } = await supabase
      .from('announcements')
      .insert({
        title,
        content,
        course_id: courseId,
        instructor_id: instructorId,
        scope_type: scopeType,
        published_at: new Date().toISOString()
      })
      .select()
      .single();

    if (announcementError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to create announcement', null, announcementError.message)
      );
    }

    // Add group associations
    if (scopeType === 'all_groups') {
      // Get all groups for this course
      const { data: courseGroups, error: groupsFetchError } = await supabase
        .from('groups')
        .select('id')
        .eq('course_id', courseId)
        .eq('is_active', true);

      if (groupsFetchError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to fetch course groups', null, groupsFetchError.message)
        );
      }

      if (courseGroups && courseGroups.length > 0) {
        const groupAssociations = courseGroups.map(group => ({
          announcement_id: announcement.id,
          group_id: group.id
        }));

        const { error: groupsError } = await supabase
          .from('announcement_groups')
          .insert(groupAssociations);

        if (groupsError) {
          return res.status(400).json(
            buildResponse(false, 'Failed to associate all groups with announcement', null, groupsError.message)
          );
        }
      }
    } else if (scopeType !== 'all_groups' && groupIds.length > 0) {
      // For specific groups
      const groupAssociations = groupIds.map(groupId => ({
        announcement_id: announcement.id,
        group_id: groupId
      }));

      const { error: groupsError } = await supabase
        .from('announcement_groups')
        .insert(groupAssociations);

      if (groupsError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to associate groups with announcement', null, groupsError.message)
        );
      }
    }

    // Add file attachments if provided
    if (attachmentIds && attachmentIds.length > 0) {
      const { data: tempAttachments, error: tempError } = await supabase
        .from('temp_attachments')
        .select('*')
        .in('temp_id', attachmentIds)
        .eq('user_id', instructorId)
        .eq('is_finalized', false);

      if (tempError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to retrieve temp attachments', null, tempError.message)
        );
      }

      if (tempAttachments.length !== attachmentIds.length) {
        return res.status(400).json(
          buildResponse(false, 'Some temp attachments not found or already finalized')
        );
      }

      // Create announcement files
      const announcementFiles = tempAttachments.map(temp => ({
        announcement_id: announcement.id,
        file_name: temp.file_name,
        file_url: temp.file_url,
        file_size: temp.file_size,
        file_type: temp.file_type
      }));

      const { error: filesError } = await supabase
        .from('announcement_files')
        .insert(announcementFiles);

      if (filesError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to attach files to announcement', null, filesError.message)
        );
      }

      // Mark temp attachments as finalized
      const { error: finalizeError } = await supabase
        .from('temp_attachments')
        .update({ is_finalized: true })
        .in('temp_id', attachmentIds);

      if (finalizeError) {
        console.warn('Failed to finalize temp attachments:', finalizeError.message);
      }
    }

    // Fetch complete announcement with relations
    const completeAnnouncement = await this.getAnnouncementWithRelations(announcement.id);

    res.status(201).json(
      buildResponse(true, 'Announcement created successfully', completeAnnouncement)
    );
  });

  /**
   * Get announcements with filters and pagination
   * - Instructor: get all announcements they created
   * - Student: get announcements for their enrolled groups
   */
  getAnnouncements = catchAsync(async (req, res) => {
    const {
      page = 1,
      limit = 20,
      search = '',
      courseId,
      scopeType,
      sortBy = 'published_at',
      sortOrder = 'desc'
    } = req.query;

    const userId = req.user.id;
    const userRole = req.user.role;
    const offset = (page - 1) * limit;

    // If student, redirect to student-specific endpoint
    if (userRole === 'student') {
      return this.getStudentAnnouncements(req, res);
    }

    // Instructor: get their own announcements
    let query = supabase
      .from('announcements')
      .select(`
        *,
        courses!inner(id, code, name),
        users!announcements_instructor_id_fkey(id, full_name, email),
        announcement_groups(
          groups(id, name)
        ),
        announcement_files(id, file_name, file_url, file_size, file_type),
        announcement_comments(id),
        announcement_views(id)
      `)
      .eq('instructor_id', userId)
      .eq('is_deleted', false);

    // Apply filters
    if (courseId) {
      query = query.eq('course_id', courseId);
    }

    if (scopeType) {
      query = query.eq('scope_type', scopeType);
    }

    if (search) {
      query = query.or(`title.ilike.%${search}%,content.ilike.%${search}%`);
    }

    // Apply sorting
    query = query.order(sortBy, { ascending: sortOrder === 'asc' });

    // Apply pagination
    query = query.range(offset, offset + limit - 1);

    const { data: announcements, error, count } = await query;

    if (error) {
      return res.status(400).json(
        buildResponse(false, 'Failed to fetch announcements', null, error.message)
      );
    }

    // Get total count separately with same filters
    let countQuery = supabase
      .from('announcements')
      .select('*', { count: 'exact', head: true })
      .eq('instructor_id', userId)
      .eq('is_deleted', false);

    // Apply same filters for count
    if (courseId) {
      countQuery = countQuery.eq('course_id', courseId);
    }

    if (scopeType) {
      countQuery = countQuery.eq('scope_type', scopeType);
    }

    if (search) {
      countQuery = countQuery.or(`title.ilike.%${search}%,content.ilike.%${search}%`);
    }

    const { count: totalCount } = await countQuery;

    // Format response
    const formattedAnnouncements = announcements.map(ann => ({
      id: ann.id,
      title: ann.title,
      content: ann.content,
      scopeType: ann.scope_type,
      publishedAt: ann.published_at,
      updatedAt: ann.updated_at,
      course: {
        id: ann.courses.id,
        code: ann.courses.code,
        name: ann.courses.name
      },
      instructor: {
        id: ann.users.id,
        fullName: ann.users.full_name,
        email: ann.users.email
      },
      groups: ann.announcement_groups?.map(ag => ({
        id: ag.groups.id,
        name: ag.groups.name
      })) || [],
      files: ann.announcement_files || [],
      commentCount: ann.announcement_comments?.length || 0,
      viewCount: ann.announcement_views?.length || 0
    }));

    const totalPages = Math.ceil((totalCount || 0) / limit);

    res.json(
      buildResponse(true, 'Announcements fetched successfully', {
        announcements: formattedAnnouncements,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: totalCount || 0,
          pages: totalPages
        }
      })
    );
  });

  /**
   * Get announcement by ID
   */
  getAnnouncementById = catchAsync(async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    const announcement = await this.getAnnouncementWithRelations(id);

    if (!announcement) {
      return res.status(404).json(
        buildResponse(false, 'Announcement not found')
      );
    }

    // Check access based on role
    if (userRole === 'instructor') {
      // Instructor can only see their own announcements
      if (announcement.instructor.id !== userId) {
        return res.status(403).json(
          buildResponse(false, 'Access denied')
        );
      }
    } else if (userRole === 'student') {
      // Student can see announcements assigned to their groups
      const { data: studentAccess, error: accessError } = await supabase
        .from('announcements')
        .select(`
          id,
          announcement_groups!inner(
            groups!inner(
              student_enrollments!inner(student_id)
            )
          )
        `)
        .eq('id', id)
        .eq('announcement_groups.groups.student_enrollments.student_id', userId)
        .eq('is_deleted', false)
        .single();

      if (accessError || !studentAccess) {
        return res.status(403).json(
          buildResponse(false, 'Access denied')
        );
      }
    } else {
      return res.status(403).json(
        buildResponse(false, 'Access denied')
      );
    }

    res.json(
      buildResponse(true, 'Announcement fetched successfully', announcement)
    );
  });

  /**
   * Update announcement
   */
  updateAnnouncement = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { title, content, attachmentIds = [] } = req.body;
    const instructorId = req.user.id;

    // Check if announcement exists and belongs to instructor
    const { data: existingAnnouncement, error: fetchError } = await supabase
      .from('announcements')
      .select('*')
      .eq('id', id)
      .eq('instructor_id', instructorId)
      .eq('is_deleted', false)
      .single();

    if (fetchError || !existingAnnouncement) {
      return res.status(404).json(
        buildResponse(false, 'Announcement not found or access denied')
      );
    }

    // Update announcement
    const { data: updatedAnnouncement, error: updateError } = await supabase
      .from('announcements')
      .update({
        title,
        content,
        updated_at: new Date().toISOString()
      })
      .eq('id', id)
      .select()
      .single();

    if (updateError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to update announcement', null, updateError.message)
      );
    }

    // Handle file attachments if provided
    if (attachmentIds && attachmentIds.length > 0) {
      // Remove existing files
      const { error: deleteFilesError } = await supabase
        .from('announcement_files')
        .delete()
        .eq('announcement_id', id);

      if (deleteFilesError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to remove existing files', null, deleteFilesError.message)
        );
      }

      // Add new files
      const { data: tempAttachments, error: tempError } = await supabase
        .from('temp_attachments')
        .select('*')
        .in('temp_id', attachmentIds)
        .eq('user_id', instructorId)
        .eq('is_finalized', false);

      if (tempError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to retrieve temp attachments', null, tempError.message)
        );
      }

      const announcementFiles = tempAttachments.map(temp => ({
        announcement_id: id,
        file_name: temp.file_name,
        file_url: temp.file_url,
        file_size: temp.file_size,
        file_type: temp.file_type
      }));

      const { error: filesError } = await supabase
        .from('announcement_files')
        .insert(announcementFiles);

      if (filesError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to attach files to announcement', null, filesError.message)
        );
      }

      // Mark temp attachments as finalized
      const { error: finalizeError } = await supabase
        .from('temp_attachments')
        .update({ is_finalized: true })
        .in('temp_id', attachmentIds);

      if (finalizeError) {
        console.warn('Failed to finalize temp attachments:', finalizeError.message);
      }
    }

    // Fetch complete updated announcement
    const completeAnnouncement = await this.getAnnouncementWithRelations(id);

    res.json(
      buildResponse(true, 'Announcement updated successfully', completeAnnouncement)
    );
  });

  /**
   * Delete announcement (soft delete)
   */
  deleteAnnouncement = catchAsync(async (req, res) => {
    const { id } = req.params;
    const instructorId = req.user.id;

    // Check if announcement exists and belongs to instructor
    const { data: existingAnnouncement, error: fetchError } = await supabase
      .from('announcements')
      .select('*')
      .eq('id', id)
      .eq('instructor_id', instructorId)
      .eq('is_deleted', false)
      .single();

    if (fetchError || !existingAnnouncement) {
      return res.status(404).json(
        buildResponse(false, 'Announcement not found or access denied')
      );
    }

    // Soft delete announcement
    const { error: deleteError } = await supabase
      .from('announcements')
      .update({ is_deleted: true })
      .eq('id', id);

    if (deleteError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to delete announcement', null, deleteError.message)
      );
    }

    res.json(
      buildResponse(true, 'Announcement deleted successfully')
    );
  });

  /**
   * Get announcement comments
   */
  getAnnouncementComments = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const { data: comments, error, count } = await supabase
      .from('announcement_comments')
      .select(`
        *,
        users!announcement_comments_user_id_fkey(id, full_name, email, role, avatar_url)
      `)
      .eq('announcement_id', id)
      .eq('is_deleted', false)
      .order('created_at', { ascending: false })
      .range(offset, offset + limit - 1);

    if (error) {
      return res.status(400).json(
        buildResponse(false, 'Failed to fetch comments', null, error.message)
      );
    }

    // Get total count separately
    const { count: totalCount } = await supabase
      .from('announcement_comments')
      .select('*', { count: 'exact', head: true })
      .eq('announcement_id', id)
      .eq('is_deleted', false);

    const formattedComments = comments.map(comment => ({
      id: comment.id,
      commentText: comment.comment_text,
      createdAt: comment.created_at,
      user: {
        id: comment.users.id,
        fullName: comment.users.full_name,
        email: comment.users.email,
        role: comment.users.role,
        avatarUrl: comment.users.avatar_url
      },
      parentCommentId: comment.parent_comment_id
    }));

    const totalPages = Math.ceil((totalCount || 0) / limit);

    res.json(
      buildResponse(true, 'Comments fetched successfully', {
        comments: formattedComments,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: totalCount || 0,
          pages: totalPages
        }
      })
    );
  });

  /**
   * Add comment to announcement
   */
  addComment = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { commentText, parentCommentId } = req.body;
    const userId = req.user.id;
    const userRole = req.user.role;

    const { data: comment, error } = await supabase
      .from('announcement_comments')
      .insert({
        announcement_id: id,
        user_id: userId,
        comment_text: commentText,
        parent_comment_id: parentCommentId || null
      })
      .select(`
        *,
        users!announcement_comments_user_id_fkey(id, full_name, email, role, avatar_url)
      `)
      .single();

    if (error) {
      return res.status(400).json(
        buildResponse(false, 'Failed to add comment', null, error.message)
      );
    }

    const formattedComment = {
      id: comment.id,
      commentText: comment.comment_text,
      createdAt: comment.created_at,
      user: {
        id: comment.users.id,
        fullName: comment.users.full_name,
        email: comment.users.email,
        role: comment.users.role,
        avatarUrl: comment.users.avatar_url
      },
      parentCommentId: comment.parent_comment_id
    };

    // Create notification for instructor if student comments
    if (userRole === 'student') {
      try {
        console.log('[Announcement Comment] Creating notification for student comment');
        const { data: announcement, error: announcementError } = await supabase
          .from('announcements')
          .select('id, title, instructor_id')
          .eq('id', id)
          .single();

        if (announcementError) {
          console.error('[Announcement Comment] Error fetching announcement:', announcementError);
        } else if (!announcement) {
          console.error('[Announcement Comment] Announcement not found:', id);
        } else if (!announcement.instructor_id) {
          console.error('[Announcement Comment] Announcement has no instructor_id:', announcement);
        } else {
          console.log('[Announcement Comment] Creating notification for instructor:', announcement.instructor_id);
          const result = await notificationController.createNotification(announcement.instructor_id, {
            type: 'announcement_comment',
            title: 'New Comment on Announcement',
            body: `${comment.users.full_name} commented on "${announcement.title}"`,
            data: {
              announcement_id: id,
              announcement_title: announcement.title,
              comment_id: comment.id,
              commenter_id: userId,
              commenter_name: comment.users.full_name,
              action_url: `/student/announcements/${id}`
            }
          });
          console.log('[Announcement Comment] Notification creation result:', result);
        }
      } catch (notificationError) {
        console.error('[Announcement Comment] Error creating notification:', notificationError);
        console.error('[Announcement Comment] Error stack:', notificationError.stack);
      }
    } else {
      console.log('[Announcement Comment] Skipping notification - user is not student, role:', userRole);
    }

    res.status(201).json(
      buildResponse(true, 'Comment added successfully', {
        comments: [formattedComment]
      })
    );
  });

  /**
   * Track announcement view
   */
  trackView = catchAsync(async (req, res) => {
    const { id } = req.params;
    const userId = req.user.id;
    const userRole = req.user.role;

    // Check if view already exists
    const { data: existingView, error: fetchError } = await supabase
      .from('announcement_views')
      .select('*')
      .eq('announcement_id', id)
      .eq('student_id', userId)
      .single();

    if (existingView) {
      // Update view count
      const { error: updateError } = await supabase
        .from('announcement_views')
        .update({
          view_count: existingView.view_count + 1,
          viewed_at: new Date().toISOString()
        })
        .eq('id', existingView.id);

      if (updateError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to update view', null, updateError.message)
        );
      }
    } else {
      // Create new view
      const { error: createError } = await supabase
        .from('announcement_views')
        .insert({
          announcement_id: id,
          student_id: userId,
          viewed_at: new Date().toISOString(),
          view_count: 1
        });

      if (createError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to track view', null, createError.message)
        );
      }
    }

    res.json(
      buildResponse(true, 'View tracked successfully')
    );
  });

  /**
   * Track file download
   */
  trackDownload = catchAsync(async (req, res) => {
    const { fileId } = req.params;
    const studentId = req.user.id;

    // Check if download already exists
    const { data: existingDownload, error: fetchError } = await supabase
      .from('announcement_downloads')
      .select('*')
      .eq('file_id', fileId)
      .eq('student_id', studentId)
      .single();

    if (existingDownload) {
      // Update download count
      const { error: updateError } = await supabase
        .from('announcement_downloads')
        .update({
          download_count: existingDownload.download_count + 1,
          downloaded_at: new Date().toISOString()
        })
        .eq('id', existingDownload.id);

      if (updateError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to update download', null, updateError.message)
        );
      }
    } else {
      // Create new download
      const { error: createError } = await supabase
        .from('announcement_downloads')
        .insert({
          file_id: fileId,
          student_id: studentId,
          downloaded_at: new Date().toISOString(),
          download_count: 1
        });

      if (createError) {
        return res.status(400).json(
          buildResponse(false, 'Failed to track download', null, createError.message)
        );
      }
    }

    res.json(
      buildResponse(true, 'Download tracked successfully')
    );
  });

  /**
   * Get announcement tracking data
   */
  getAnnouncementTracking = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { groupId, status } = req.query;
    const instructorId = req.user.id;

    // Check if announcement belongs to instructor
    const { data: announcement, error: announcementError } = await supabase
      .from('announcements')
      .select('id, scope_type')
      .eq('id', id)
      .eq('instructor_id', instructorId)
      .eq('is_deleted', false)
      .single();

    if (announcementError || !announcement) {
      return res.status(404).json(
        buildResponse(false, 'Announcement not found or access denied')
      );
    }

    // Get students based on scope
    let studentsQuery = supabase
      .from('student_enrollments')
      .select(`
        users!student_enrollments_student_id_fkey(id, full_name, email),
        groups!student_enrollments_group_id_fkey(id, name)
      `);

    if (announcement.scope_type === 'all_groups') {
      // Get all students in the course
      const { data: courseData } = await supabase
        .from('announcements')
        .select('course_id')
        .eq('id', id)
        .single();

      studentsQuery = studentsQuery.eq('semester_id', req.user.current_semester_id);
    } else {
      // Get students from specific groups
      const { data: announcementGroups } = await supabase
        .from('announcement_groups')
        .select('group_id')
        .eq('announcement_id', id);

      if (announcementGroups && announcementGroups.length > 0) {
        const groupIds = announcementGroups.map(ag => ag.group_id);
        studentsQuery = studentsQuery.in('group_id', groupIds);
      }
    }

    if (groupId) {
      studentsQuery = studentsQuery.eq('group_id', groupId);
    }

    const { data: students, error: studentsError } = await studentsQuery;

    if (studentsError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to fetch students', null, studentsError.message)
      );
    }

    // Get view tracking data
    const { data: views, error: viewsError } = await supabase
      .from('announcement_views')
      .select('student_id, viewed_at, view_count')
      .eq('announcement_id', id);

    if (viewsError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to fetch view data', null, viewsError.message)
      );
    }

    // Combine data
    const trackingData = students.map(student => {
      const viewData = views.find(v => v.student_id === student.users.id);
      return {
        student: {
          id: student.users.id,
          fullName: student.users.full_name,
          email: student.users.email
        },
        group: {
          id: student.groups.id,
          name: student.groups.name
        },
        viewed: !!viewData,
        viewedAt: viewData?.viewed_at,
        viewCount: viewData?.view_count || 0
      };
    });

    // Apply status filter
    let filteredData = trackingData;
    if (status === 'viewed') {
      filteredData = trackingData.filter(item => item.viewed);
    } else if (status === 'not_viewed') {
      filteredData = trackingData.filter(item => !item.viewed);
    }

    res.json(
      buildResponse(true, 'Tracking data fetched successfully', {
        tracking: filteredData,
        summary: {
          total: trackingData.length,
          viewed: trackingData.filter(item => item.viewed).length,
          notViewed: trackingData.filter(item => !item.viewed).length
        }
      })
    );
  });

  /**
   * Get file download tracking data
   */
  getFileDownloadTracking = catchAsync(async (req, res) => {
    const { id } = req.params;
    const { fileId } = req.query;
    const instructorId = req.user.id;

    // Check if announcement belongs to instructor
    const { data: announcement, error: announcementError } = await supabase
      .from('announcements')
      .select('id, scope_type')
      .eq('id', id)
      .eq('instructor_id', instructorId)
      .eq('is_deleted', false)
      .single();

    if (announcementError || !announcement) {
      return res.status(404).json(
        buildResponse(false, 'Announcement not found or access denied')
      );
    }

    // Get files for this announcement
    let filesQuery = supabase
      .from('announcement_files')
      .select('*')
      .eq('announcement_id', id);

    if (fileId) {
      filesQuery = filesQuery.eq('id', fileId);
    }

    const { data: files, error: filesError } = await filesQuery;

    if (filesError) {
      return res.status(400).json(
        buildResponse(false, 'Failed to fetch files', null, filesError.message)
      );
    }

    // Get download tracking for each file
    const fileTrackingData = await Promise.all(
      files.map(async (file) => {
        const { data: downloads, error: downloadsError } = await supabase
          .from('announcement_downloads')
          .select(`
            student_id,
            downloaded_at,
            download_count,
            users!announcement_downloads_student_id_fkey(id, full_name, email)
          `)
          .eq('file_id', file.id);

        if (downloadsError) {
          console.error('Failed to fetch downloads for file:', file.id, downloadsError);
          return {
            file: {
              id: file.id,
              fileName: file.file_name,
              fileSize: file.file_size,
              fileType: file.file_type
            },
            downloads: [],
            totalDownloads: 0
          };
        }

        return {
          file: {
            id: file.id,
            fileName: file.file_name,
            fileSize: file.file_size,
            fileType: file.file_type
          },
          downloads: downloads.map(download => ({
            student: {
              id: download.users.id,
              fullName: download.users.full_name,
              email: download.users.email
            },
            downloadedAt: download.downloaded_at,
            downloadCount: download.download_count
          })),
          totalDownloads: downloads.reduce((sum, d) => sum + d.download_count, 0)
        };
      })
    );

    res.json(
      buildResponse(true, 'File download tracking fetched successfully', {
        files: fileTrackingData
      })
    );
  });

  /**
   * Helper method to get announcement with all relations
   */
  async getAnnouncementWithRelations(announcementId) {
    const { data: announcement, error } = await supabase
      .from('announcements')
      .select(`
        *,
        courses!inner(id, code, name),
        users!announcements_instructor_id_fkey(id, full_name, email),
        announcement_groups(
          groups(id, name)
        ),
        announcement_files(id, file_name, file_url, file_size, file_type),
        announcement_comments(id),
        announcement_views(id)
      `)
      .eq('id', announcementId)
      .eq('is_deleted', false)
      .single();

    if (error || !announcement) {
      return null;
    }

    return {
      id: announcement.id,
      title: announcement.title,
      content: announcement.content,
      scopeType: announcement.scope_type,
      publishedAt: announcement.published_at,
      updatedAt: announcement.updated_at,
      course: {
        id: announcement.courses.id,
        code: announcement.courses.code,
        name: announcement.courses.name
      },
      instructor: {
        id: announcement.users.id,
        fullName: announcement.users.full_name,
        email: announcement.users.email
      },
      groups: announcement.announcement_groups?.map(ag => ({
        id: ag.groups.id,
        name: ag.groups.name
      })) || [],
      files: announcement.announcement_files || [],
      commentCount: announcement.announcement_comments?.length || 0,
      viewCount: announcement.announcement_views?.length || 0
    };
  }

  /**
   * Get announcements for student (based on their enrolled groups)
   */
  getStudentAnnouncements = catchAsync(async (req, res) => {
    const studentId = req.user.id;
    const {
      page = 1,
      limit = 20,
      sortBy = 'published_at',
      sortOrder = 'desc'
    } = req.query;

    const offset = (page - 1) * limit;

    // Get student's enrolled groups with course information
    const { data: enrollments, error: enrollmentError } = await supabase
      .from('student_enrollments')
      .select(`
        group_id,
        groups!inner(
          id,
          name,
          course_id,
          courses!inner(
            id,
            semester_id
          )
        )
      `)
      .eq('student_id', studentId)
      .eq('is_active', true);

    if (enrollmentError) {
      console.error('Enrollment query error:', enrollmentError);
      return res.status(500).json(
        buildResponse(false, 'Failed to fetch student enrollments', null, enrollmentError.message)
      );
    }

    if (!enrollments || enrollments.length === 0) {
      return res.json(
        buildResponse(true, undefined, {
          announcements: [],
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total: 0,
            totalPages: 0
          }
        })
      );
    }

    const groupIds = enrollments.map(e => e.groups.id);
    const courseIds = [...new Set(enrollments.map(e => e.groups.courses.id))];

    // Get announcements for these groups only
    // Only show announcements that are assigned to groups the student is enrolled in
    // and belong to courses the student is enrolled in
    const { data: announcementGroups, error: announcementError } = await supabase
      .from('announcement_groups')
      .select(`
        announcement_id,
        group_id,
        announcements!inner(
          id,
          title,
          content,
          course_id,
          instructor_id,
          scope_type,
          published_at,
          created_at,
          updated_at,
          is_deleted,
          courses!inner(
            id,
            code,
            name
          ),
          users!announcements_instructor_id_fkey(id, full_name, email)
        )
      `)
      .in('group_id', groupIds)
      .in('announcements.course_id', courseIds)
      .eq('announcements.is_deleted', false);

    if (announcementError) {
      console.error('Announcement query error:', announcementError);
      return res.status(500).json(
        buildResponse(false, 'Failed to fetch announcements', null, announcementError.message)
      );
    }

    // Get unique announcements (avoid duplicates if student is in multiple groups)
    // Also collect groups for each announcement to show which groups it's assigned to
    const uniqueAnnouncements = [];
    const seenIds = new Set();
    const announcementGroupsMap = new Map(); // announcement_id -> [group_ids]

    for (const item of announcementGroups || []) {
      if (item.announcements && item.announcements.id) {
        const announcementId = item.announcements.id;
        
        // Track which groups this announcement is assigned to (for this student)
        if (!announcementGroupsMap.has(announcementId)) {
          announcementGroupsMap.set(announcementId, []);
        }
        if (item.group_id && !announcementGroupsMap.get(announcementId).includes(item.group_id)) {
          announcementGroupsMap.get(announcementId).push(item.group_id);
        }

        // Only add unique announcements
        if (!seenIds.has(announcementId)) {
          seenIds.add(announcementId);
          
          // Get groups for this announcement (only groups student is enrolled in)
          const assignedGroupIds = announcementGroupsMap.get(announcementId) || [];
          
          uniqueAnnouncements.push({
            id: item.announcements.id,
            title: item.announcements.title,
            content: item.announcements.content,
            courseId: item.announcements.course_id,
            instructorId: item.announcements.instructor_id,
            scopeType: item.announcements.scope_type,
            publishedAt: item.announcements.published_at,
            createdAt: item.announcements.created_at,
            updatedAt: item.announcements.updated_at,
            course: item.announcements.courses,
            instructor: item.announcements.users,
            // Only include groups that student is enrolled in
            groups: enrollments
              .filter(e => assignedGroupIds.includes(e.groups.id))
              .map(e => ({
                id: e.groups.id,
                name: e.groups.name || `Group ${e.groups.id}`,
                courseId: e.groups.course_id
              })),
            // Add required fields with default values
            files: [],
            commentCount: 0,
            viewCount: 0
          });
        }
      }
    }

    // Sort in memory
    const sortField = sortBy || 'published_at';
    const ascending = sortOrder === 'asc';
    uniqueAnnouncements.sort((a, b) => {
      let aVal = a[sortField];
      let bVal = b[sortField];
      
      // Handle date strings
      if (sortField.includes('At') || sortField.includes('at')) {
        aVal = new Date(aVal || 0).getTime();
        bVal = new Date(bVal || 0).getTime();
      }
      
      if (aVal < bVal) return ascending ? -1 : 1;
      if (aVal > bVal) return ascending ? 1 : -1;
      return 0;
    });

    // Apply pagination after sorting
    const paginatedAnnouncements = uniqueAnnouncements.slice(offset, offset + parseInt(limit));

    // Get total count (unique announcements)
    const total = uniqueAnnouncements.length;
    const pages = Math.ceil(total / parseInt(limit));

    res.json(
      buildResponse(true, undefined, {
        announcements: paginatedAnnouncements,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages
        }
      })
    );
  });
}

module.exports = new AnnouncementController();
