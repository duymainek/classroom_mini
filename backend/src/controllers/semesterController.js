const { supabase } = require('../services/supabaseClient');
const { validateSemesterCreation, validateSemesterUpdate } = require('../models/semester');
const { AppError, catchAsync } = require('../middleware/errorHandler');

class SemesterController {
  /**
   * Create new semester
   */
  createSemester = catchAsync(async (req, res) => {
    const { code, name } = req.body;

    // Validate input
    const validation = validateSemesterCreation({ code, name });
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if semester code already exists
    const { data: existingSemester } = await supabase
      .from('semesters')
      .select('id')
      .eq('code', code)
      .single();

    if (existingSemester) {
      return res.status(409).json({
        success: false,
        message: 'Semester code already exists',
        conflictField: 'code'
      });
    }

    // Create semester
    const { data: newSemester, error } = await supabase
      .from('semesters')
      .insert({
        code: code.trim(),
        name: name.trim(),
        is_active: true
      })
      .select()
      .single();

    if (error) {
      console.error('Semester creation error:', error);
      throw new AppError('Failed to create semester', 500, 'SEMESTER_CREATION_FAILED');
    }

    res.status(201).json({
      success: true,
      message: 'Semester created successfully',
      data: {
        semester: newSemester
      }
    });
  });

  /**
   * Get all semesters with pagination and search
   */
  getSemesters = catchAsync(async (req, res) => {
    const {
      page = 1,
      limit = 20,
      search = '',
      status = 'all', // all, active, inactive
      sortBy = 'created_at',
      sortOrder = 'desc'
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    // Build query
    let query = supabase
      .from('semesters')
      .select('*', { count: 'exact' });

    // Apply search filter
    if (search.trim()) {
      query = query.or(`
        code.ilike.%${search}%,
        name.ilike.%${search}%
      `);
    }

    // Apply status filter
    if (status === 'active') {
      query = query.eq('is_active', true);
    } else if (status === 'inactive') {
      query = query.eq('is_active', false);
    }

    // Apply sorting
    query = query.order(sortBy, { ascending: sortOrder === 'asc' });

    // Apply pagination
    query = query.range(offset, offset + parseInt(limit) - 1);

    const { data: semesters, error, count } = await query;

    if (error) {
      console.error('Get semesters error:', error);
      throw new AppError('Failed to fetch semesters', 500, 'GET_SEMESTERS_FAILED');
    }

    res.json({
      success: true,
      data: {
        semesters: semesters || [],
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count || 0,
          pages: Math.ceil((count || 0) / parseInt(limit))
        }
      }
    });
  });

  /**
   * Get semester by ID
   */
  getSemesterById = catchAsync(async (req, res) => {
    const { semesterId } = req.params;

    const { data: semester, error } = await supabase
      .from('semesters')
      .select('*')
      .eq('id', semesterId)
      .single();

    if (error || !semester) {
      throw new AppError('Semester not found', 404, 'SEMESTER_NOT_FOUND');
    }

    res.json({
      success: true,
      data: {
        semester
      }
    });
  });

  /**
   * Update semester
   */
  updateSemester = catchAsync(async (req, res) => {
    const { semesterId } = req.params;
    const { code, name, isActive } = req.body;

    // Validate input
    const validation = validateSemesterUpdate(req.body);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if semester exists
    const { data: existingSemester } = await supabase
      .from('semesters')
      .select('id, code')
      .eq('id', semesterId)
      .single();

    if (!existingSemester) {
      throw new AppError('Semester not found', 404, 'SEMESTER_NOT_FOUND');
    }

    // Check code uniqueness if changed
    if (code && code !== existingSemester.code) {
      const { data: codeExists } = await supabase
        .from('semesters')
        .select('id')
        .eq('code', code.trim())
        .neq('id', semesterId)
        .single();

      if (codeExists) {
        return res.status(409).json({
          success: false,
          message: 'Semester code already exists',
          conflictField: 'code'
        });
      }
    }

    // Update semester
    const updateData = {};
    if (code) updateData.code = code.trim();
    if (name) updateData.name = name.trim();
    if (typeof isActive === 'boolean') updateData.is_active = isActive;

    const { data: updatedSemester, error } = await supabase
      .from('semesters')
      .update(updateData)
      .eq('id', semesterId)
      .select()
      .single();

    if (error) {
      console.error('Update semester error:', error);
      throw new AppError('Failed to update semester', 500, 'UPDATE_SEMESTER_FAILED');
    }

    res.json({
      success: true,
      message: 'Semester updated successfully',
      data: {
        semester: updatedSemester
      }
    });
  });

  /**
   * Delete semester
   */
  deleteSemester = catchAsync(async (req, res) => {
    const { semesterId } = req.params;

    // Check if semester exists
    const { data: existingSemester } = await supabase
      .from('semesters')
      .select('id, code')
      .eq('id', semesterId)
      .single();

    if (!existingSemester) {  
      throw new AppError('Semester not found', 404, 'SEMESTER_NOT_FOUND');
    }

    // Check if semester has courses
    const { data: courses } = await supabase
      .from('courses')
      .select('id')
      .eq('semester_id', semesterId)
      .limit(1);

    if (courses && courses.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete semester with existing courses',
        code: 'SEMESTER_HAS_COURSES'
      });
    }

    // Delete semester
    const { error } = await supabase
      .from('semesters')
      .delete()
      .eq('id', semesterId);

    if (error) {
      console.error('Delete semester error:', error);
      throw new AppError('Failed to delete semester', 500, 'DELETE_SEMESTER_FAILED');
    }

    res.json({
      success: true,
      message: 'Semester deleted successfully'
    });
  });

  /**
   * Get semester statistics
   */
  getSemesterStatistics = catchAsync(async (req, res) => {
    try {
      // Get basic statistics
      const { count: totalCount, error: totalError } = await supabase
        .from('semesters')
        .select('*', { count: 'exact', head: true });

      const { count: activeCount, error: activeError } = await supabase
        .from('semesters')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', true);

      const { count: inactiveCount, error: inactiveError } = await supabase
        .from('semesters')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', false);

      if (totalError || activeError || inactiveError) {
        throw new AppError('Failed to get statistics', 500, 'STATISTICS_ERROR');
      }

      const statistics = {
        total_semesters: totalCount || 0,
        active_semesters: activeCount || 0,
        inactive_semesters: inactiveCount || 0
      };

      res.json({
        success: true,
        data: statistics
      });
    } catch (error) {
      console.error('Get semester statistics error:', error);
      throw new AppError('Failed to get statistics', 500, 'GET_STATISTICS_FAILED');
    }
  });
}

module.exports = new SemesterController();