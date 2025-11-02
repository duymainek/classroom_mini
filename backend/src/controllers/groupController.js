const { supabase } = require('../services/supabaseClient');
const { validate } = require('../utils/validators');
const { createGroupSchema, updateGroupSchema } = require('../schemas/groupSchema');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');
require('../types/group.type');

class GroupController {
  /**
   * Create new group
   */
  createGroup = catchAsync(async (req, res) => {
    const { name, courseId } = req.body;

    // Validate input
    const validation = validate(createGroupSchema, req.body);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if course exists and is active
    const { data: course } = await supabase
      .from('courses')
      .select(`
        id, code, name, 
        semesters!inner(id, code, name, is_active)
      `)
      .eq('id', courseId)
      .eq('is_active', true)
      .single();

    if (!course || !course.semesters.is_active) {
      return res.status(404).json({
        success: false,
        message: 'Course not found or inactive',
        code: 'COURSE_NOT_FOUND'
      });
    }

    // Create group
    const { data: newGroup, error } = await supabase
      .from('groups')
      .insert({
        name: name.trim(),
        course_id: courseId,
        is_active: true
      })
      .select(`
        id, name, course_id, is_active, created_at, updated_at,
        courses!inner(code, name, 
          semesters!inner(code, name)
        )
      `)
      .single();

    if (error) {
      console.error('Group creation error:', error);
      throw new AppError('Failed to create group', 500, 'GROUP_CREATION_FAILED');
    }

    // Transform group: rename courses to course, and semesters to semester
    const transformedGroup = {
      id: newGroup.id,
      name: newGroup.name,
      courseId: newGroup.course_id,
      isActive: newGroup.is_active,
      createdAt: newGroup.created_at,
      updatedAt: newGroup.updated_at,
      course: newGroup.courses ? {
        code: newGroup.courses.code,
        name: newGroup.courses.name,
        semester: newGroup.courses.semesters ? {
          code: newGroup.courses.semesters.code,
          name: newGroup.courses.semesters.name
        } : null
      } : null
    };

    res.status(201).json(
      buildResponse(true, 'Group created successfully', { group: transformedGroup })
    );
  });

  /**
   * Get all groups with pagination, search, and filters
   */
  getGroups = catchAsync(async (req, res) => {
    const {
      page = 1,
      limit = 20,
      search = '',
      status = 'all', // all, active, inactive
      courseId = '', // filter by course
      sortBy = 'created_at',
      sortOrder = 'desc'
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    // Build query
    let query = supabase
      .from('groups')
      .select(`
        id, name, course_id, is_active, created_at, updated_at,
        courses!inner(code, name, 
          semesters!inner(code, name)
        )
      `, { count: 'exact' });

    // Apply search filter
    if (search.trim()) {
      query = query.or(`
        name.ilike.%${search}%,
        courses.code.ilike.%${search}%,
        courses.name.ilike.%${search}%,
        courses.semesters.code.ilike.%${search}%,
        courses.semesters.name.ilike.%${search}%
      `);
    }

    // Apply status filter
    if (status === 'active') {
      query = query.eq('is_active', true);
    } else if (status === 'inactive') {
      query = query.eq('is_active', false);
    }

    // Apply course filter
    if (courseId) {
      query = query.eq('course_id', courseId);
    }

    // Apply sorting
    query = query.order(sortBy, { ascending: sortOrder === 'asc' });

    // Apply pagination
    query = query.range(offset, offset + parseInt(limit) - 1);

    const { data: groups, error, count } = await query;

    if (error) {
      console.error('Get groups error:', error);
      throw new AppError('Failed to fetch groups', 500, 'GET_GROUPS_FAILED');
    }

    // Transform groups: rename courses to course, and semesters to semester
    const transformedGroups = (groups || []).map(group => ({
      id: group.id,
      name: group.name,
      courseId: group.course_id,
      isActive: group.is_active,
      createdAt: group.created_at,
      updatedAt: group.updated_at,
      course: group.courses ? {
        code: group.courses.code,
        name: group.courses.name,
        semester: group.courses.semesters ? {
          code: group.courses.semesters.code,
          name: group.courses.semesters.name
        } : null
      } : null
    }));

    res.json(
      buildResponse(true, undefined, {
        groups: transformedGroups,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count || 0,
          pages: Math.ceil((count || 0) / parseInt(limit))
        }
      })
    );
  });

  /**
   * Get group by ID
   */
  getGroupById = catchAsync(async (req, res) => {
    const { groupId } = req.params;

    const { data: group, error } = await supabase
      .from('groups')
      .select(`
        id, name, course_id, is_active, created_at, updated_at,
        courses!inner(code, name, 
          semesters!inner(code, name)
        )
      `)
      .eq('id', groupId)
      .single();

    if (error || !group) {
      throw new AppError('Group not found', 404, 'GROUP_NOT_FOUND');
    }

    // Transform group: rename courses to course, and semesters to semester
    const transformedGroup = {
      id: group.id,
      name: group.name,
      courseId: group.course_id,
      isActive: group.is_active,
      createdAt: group.created_at,
      updatedAt: group.updated_at,
      course: group.courses ? {
        code: group.courses.code,
        name: group.courses.name,
        semester: group.courses.semesters ? {
          code: group.courses.semesters.code,
          name: group.courses.semesters.name
        } : null
      } : null
    };

    res.json(buildResponse(true, undefined, { group: transformedGroup }));
  });

  /**
   * Update group
   */
  updateGroup = catchAsync(async (req, res) => {
    const { groupId } = req.params;
    const { name, courseId, isActive } = req.body;

    // Validate input
    const validation = validate(updateGroupSchema, req.body);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if group exists
    const { data: existingGroup } = await supabase
      .from('groups')
      .select('id, name, course_id')
      .eq('id', groupId)
      .single();

    if (!existingGroup) {
      throw new AppError('Group not found', 404, 'GROUP_NOT_FOUND');
    }

    // Check course if changed
    if (courseId && courseId !== existingGroup.course_id) {
      const { data: course } = await supabase
        .from('courses')
        .select(`
          id, 
          semesters!inner(is_active)
        `)
        .eq('id', courseId)
        .eq('is_active', true)
        .single();

      if (!course || !course.semesters.is_active) {
        return res.status(404).json({
          success: false,
          message: 'Course not found or inactive',
          code: 'COURSE_NOT_FOUND'
        });
      }
    }

    // Update group
    const updateData = {};
    if (name) updateData.name = name.trim();
    if (courseId) updateData.course_id = courseId;
    if (typeof isActive === 'boolean') updateData.is_active = isActive;

    const { data: updatedGroup, error } = await supabase
      .from('groups')
      .update(updateData)
      .eq('id', groupId)
      .select(`
        id, name, course_id, is_active, created_at, updated_at,
        courses!inner(code, name, 
          semesters!inner(code, name)
        )
      `)
      .single();

    if (error) {
      console.error('Update group error:', error);
      throw new AppError('Failed to update group', 500, 'UPDATE_GROUP_FAILED');
    }

    // Transform group: rename courses to course, and semesters to semester
    const transformedGroup = {
      id: updatedGroup.id,
      name: updatedGroup.name,
      courseId: updatedGroup.course_id,
      isActive: updatedGroup.is_active,
      createdAt: updatedGroup.created_at,
      updatedAt: updatedGroup.updated_at,
      course: updatedGroup.courses ? {
        code: updatedGroup.courses.code,
        name: updatedGroup.courses.name,
        semester: updatedGroup.courses.semesters ? {
          code: updatedGroup.courses.semesters.code,
          name: updatedGroup.courses.semesters.name
        } : null
      } : null
    };

    res.json(
      buildResponse(true, 'Group updated successfully', { group: transformedGroup })
    );
  });

  /**
   * Delete group
   */
  deleteGroup = catchAsync(async (req, res) => {
    const { groupId } = req.params;

    // Check if group exists
    const { data: existingGroup } = await supabase
      .from('groups')
      .select('id, name')
      .eq('id', groupId)
      .single();

    if (!existingGroup) {
      throw new AppError('Group not found', 404, 'GROUP_NOT_FOUND');
    }

    // Delete group
    const { error } = await supabase
      .from('groups')
      .delete()
      .eq('id', groupId);

    if (error) {
      console.error('Delete group error:', error);
      throw new AppError('Failed to delete group', 500, 'DELETE_GROUP_FAILED');
    }

    res.json(buildResponse(true, 'Group deleted successfully'));
  });

  /**
   * Get groups by course
   */
  getGroupsByCourse = catchAsync(async (req, res) => {
    const { courseId } = req.params;
    const {
      page = 1,
      limit = 20,
      search = '',
      status = 'all'
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    // Build query
    let query = supabase
      .from('groups')
      .select(`
        id, name, is_active, created_at, updated_at
      `, { count: 'exact' })
      .eq('course_id', courseId);

    // Apply search filter
    if (search.trim()) {
      query = query.ilike('name', `%${search}%`);
    }

    // Apply status filter
    if (status === 'active') {
      query = query.eq('is_active', true);
    } else if (status === 'inactive') {
      query = query.eq('is_active', false);
    }

    // Apply pagination
    query = query.order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    const { data: groups, error, count } = await query;

    if (error) {
      console.error('Get groups by course error:', error);
      throw new AppError('Failed to fetch groups', 500, 'GET_GROUPS_FAILED');
    }

    res.json(
      buildResponse(true, undefined, {
        groups: groups || [],
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count || 0,
          pages: Math.ceil((count || 0) / parseInt(limit))
        }
      })
    );
  });

  /**
   * Get group statistics
   */
  getGroupStatistics = catchAsync(async (req, res) => {
    try {
      // Get basic statistics
      const { count: totalCount, error: totalError } = await supabase
        .from('groups')
        .select('*', { count: 'exact', head: true });

      const { count: activeCount, error: activeError } = await supabase
        .from('groups')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', true);

      const { count: inactiveCount, error: inactiveError } = await supabase
        .from('groups')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', false);

      if (totalError || activeError || inactiveError) {
        throw new AppError('Failed to get statistics', 500, 'STATISTICS_ERROR');
      }

      const statistics = {
        total_groups: totalCount || 0,
        active_groups: activeCount || 0,
        inactive_groups: inactiveCount || 0
      };

      res.json(buildResponse(true, undefined, statistics));
    } catch (error) {
      console.error('Get group statistics error:', error);
      throw new AppError('Failed to get statistics', 500, 'GET_STATISTICS_FAILED');
    }
  });
}

module.exports = new GroupController();