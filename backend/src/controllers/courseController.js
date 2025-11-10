const { supabase } = require('../services/supabaseClient');
const { validate } = require('../utils/validators');
const { createCourseSchema, updateCourseSchema } = require('../schemas/courseSchema');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');
require('../types/course.type');

class CourseController {
  /**
   * Create new course (instructor only)
   */
  createCourse = catchAsync(async (req, res) => {
    const { code, name, sessionCount, semesterId } = req.body;
    const userRole = req.user.role;

    // Check role
    if (userRole !== 'instructor') {
      return res.status(403).json({
        success: false,
        message: 'Access denied. Only instructors can create courses',
        code: 'INSUFFICIENT_PERMISSIONS'
      });
    }

    // Validate input
    const validation = validate(createCourseSchema, req.body);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if semester exists
    const { data: semester } = await supabase
      .from('semesters')
      .select('id, name')
      .eq('id', semesterId)
      .eq('is_active', true)
      .single();

    if (!semester) {
      return res.status(404).json({
        success: false,
        message: 'Semester not found or inactive',
        code: 'SEMESTER_NOT_FOUND'
      });
    }

    // Check if course code already exists
    const { data: existingCourse } = await supabase
      .from('courses')
      .select('id')
      .eq('code', code)
      .single();

    if (existingCourse) {
      return res.status(409).json({
        success: false,
        message: 'Course code already exists',
        conflictField: 'code'
      });
    }

    // Create course
    const { data: newCourse, error } = await supabase
      .from('courses')
      .insert({
        code: code.trim(),
        name: name.trim(),
        session_count: sessionCount,
        semester_id: semesterId,
        is_active: true
      })
      .select(`
        id, code, name, session_count, semester_id, is_active, 
        created_at, updated_at,
        semesters!inner(code, name)
      `)
      .single();

    if (error) {
      console.error('Course creation error:', error);
      throw new AppError('Failed to create course', 500, 'COURSE_CREATION_FAILED');
    }

    res.status(201).json(
      buildResponse(true, 'Course created successfully', {
        course: {
          id: newCourse.id,
          code: newCourse.code,
          name: newCourse.name,
          sessionCount: newCourse.session_count,
          semesterId: newCourse.semester_id,
          isActive: newCourse.is_active,
          createdAt: newCourse.created_at,
          updatedAt: newCourse.updated_at,
          semester: newCourse.semesters
        }
      })
    );
  });

  /**
   * Get all courses with pagination, search, and filters
   * - Instructor: get all courses
   * - Student: get only enrolled courses
   */
  getCourses = catchAsync(async (req, res) => {
    const {
      page = 1,
      limit = 20,
      search = '',
      status = 'all', // all, active, inactive
      semesterId = '', // filter by semester
      sortBy = 'created_at',
      sortOrder = 'desc'
    } = req.query;

    const userId = req.user.id;
    const userRole = req.user.role;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    // If student, get only their enrolled courses
    if (userRole === 'student') {
      const { data: enrollments, error: enrollError } = await supabase
        .from('student_enrollments')
        .select(`
          groups!inner(
            courses!inner(
              id, code, name, session_count, semester_id, is_active,
              created_at, updated_at,
              semesters(code, name)
            )
          )
        `)
        .eq('student_id', userId)
        .eq('is_active', true);

      if (enrollError) {
        throw new AppError('Failed to fetch enrolled courses', 500, 'GET_ENROLLED_COURSES_FAILED');
      }

      // Extract unique courses
      const coursesMap = new Map();
      for (const enrollment of enrollments || []) {
        if (enrollment.groups?.courses) {
          const course = enrollment.groups.courses;
          if (!coursesMap.has(course.id)) {
            // Apply filters
            if (semesterId && course.semester_id !== semesterId) continue;
            if (status === 'active' && !course.is_active) continue;
            if (status === 'inactive' && course.is_active) continue;
            if (search && !course.name.toLowerCase().includes(search.toLowerCase()) && 
                !course.code.toLowerCase().includes(search.toLowerCase())) continue;

            coursesMap.set(course.id, {
              id: course.id,
              code: course.code,
              name: course.name,
              sessionCount: course.session_count,
              semesterId: course.semester_id,
              isActive: course.is_active,
              createdAt: course.created_at,
              updatedAt: course.updated_at,
              semester: course.semesters
            });
          }
        }
      }

      const courses = Array.from(coursesMap.values());

      return res.json(
        buildResponse(true, undefined, {
          courses,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total: courses.length,
            pages: Math.ceil(courses.length / parseInt(limit))
          }
        })
      );
    }

    // Instructor: get all courses
    let query = supabase
      .from('courses')
      .select(`
        id, code, name, session_count, semester_id, is_active, 
        created_at, updated_at,
        semesters!inner(code, name)
      `, { count: 'exact' });

    // Apply search filter
    if (search.trim()) {
      query = query.or(`
        code.ilike.%${search}%,
        name.ilike.%${search}%,
        semesters.code.ilike.%${search}%,
        semesters.name.ilike.%${search}%
      `);
    }

    // Apply status filter
    if (status === 'active') {
      query = query.eq('is_active', true);
    } else if (status === 'inactive') {
      query = query.eq('is_active', false);
    }

    // Apply semester filter
    if (semesterId) {
      query = query.eq('semester_id', semesterId);
    }

    // Apply sorting
    query = query.order(sortBy, { ascending: sortOrder === 'asc' });

    // Apply pagination
    query = query.range(offset, offset + parseInt(limit) - 1);

    const { data: courses, error, count } = await query;

    if (error) {
      console.error('Get courses error:', error);
      throw new AppError('Failed to fetch courses', 500, 'GET_COURSES_FAILED');
    }

    // Transform courses: rename semesters to semester to match schema
    const transformedCourses = (courses || []).map(course => ({
      id: course.id,
      code: course.code,
      name: course.name,
      sessionCount: course.session_count,
      semesterId: course.semester_id,
      isActive: course.is_active,
      createdAt: course.created_at,
      updatedAt: course.updated_at,
      semester: course.semesters || null
    }));

    res.json(
      buildResponse(true, undefined, {
        courses: transformedCourses,
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
   * Get course by ID
   */
  getCourseById = catchAsync(async (req, res) => {
    const { courseId } = req.params;

    const { data: course, error } = await supabase
      .from('courses')
      .select(`
        id, code, name, session_count, semester_id, is_active, 
        created_at, updated_at,
        semesters!inner(code, name)
      `)
      .eq('id', courseId)
      .single();

    if (error || !course) {
      throw new AppError('Course not found', 404, 'COURSE_NOT_FOUND');
    }

    // Transform course: rename semesters to semester to match schema
    const transformedCourse = {
      id: course.id,
      code: course.code,
      name: course.name,
      sessionCount: course.session_count,
      semesterId: course.semester_id,
      isActive: course.is_active,
      createdAt: course.created_at,
      updatedAt: course.updated_at,
      semester: course.semesters || null
    };

    res.json(buildResponse(true, undefined, { course: transformedCourse }));
  });

  /**
   * Update course
   */
  updateCourse = catchAsync(async (req, res) => {
    const { courseId } = req.params;
    const { code, name, sessionCount, semesterId, isActive } = req.body;

    // Validate input
    const validation = validate(updateCourseSchema, req.body);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if course exists
    const { data: existingCourse } = await supabase
      .from('courses')
      .select('id, code, semester_id')
      .eq('id', courseId)
      .single();

    if (!existingCourse) {
      throw new AppError('Course not found', 404, 'COURSE_NOT_FOUND');
    }

    // Check semester if changed
    if (semesterId && semesterId !== existingCourse.semester_id) {
      const { data: semester } = await supabase
        .from('semesters')
        .select('id')
        .eq('id', semesterId)
        .eq('is_active', true)
        .single();

      if (!semester) {
        return res.status(404).json({
          success: false,
          message: 'Semester not found or inactive',
          code: 'SEMESTER_NOT_FOUND'
        });
      }
    }

    // Check code uniqueness if changed
    if (code && code !== existingCourse.code) {
      const { data: codeExists } = await supabase
        .from('courses')
        .select('id')
        .eq('code', code.trim())
        .neq('id', courseId)
        .single();

      if (codeExists) {
        return res.status(409).json({
          success: false,
          message: 'Course code already exists',
          conflictField: 'code'
        });
      }
    }

    // Update course
    const updateData = {};
    if (code) updateData.code = code.trim();
    if (name) updateData.name = name.trim();
    if (sessionCount) updateData.session_count = sessionCount;
    if (semesterId) updateData.semester_id = semesterId;
    if (typeof isActive === 'boolean') updateData.is_active = isActive;

    const { data: updatedCourse, error } = await supabase
      .from('courses')
      .update(updateData)
      .eq('id', courseId)
      .select(`
        id, code, name, session_count, semester_id, is_active, 
        created_at, updated_at,
        semesters!inner(code, name)
      `)
      .single();

    if (error) {
      console.error('Update course error:', error);
      throw new AppError('Failed to update course', 500, 'UPDATE_COURSE_FAILED');
    }

    // Transform course: rename semesters to semester to match schema
    const transformedCourse = {
      id: updatedCourse.id,
      code: updatedCourse.code,
      name: updatedCourse.name,
      sessionCount: updatedCourse.session_count,
      semesterId: updatedCourse.semester_id,
      isActive: updatedCourse.is_active,
      createdAt: updatedCourse.created_at,
      updatedAt: updatedCourse.updated_at,
      semester: updatedCourse.semesters || null
    };

    res.json(
      buildResponse(true, 'Course updated successfully', { course: transformedCourse })
    );
  });

  /**
   * Delete course
   */
  deleteCourse = catchAsync(async (req, res) => {
    const { courseId } = req.params;

    // Check if course exists
    const { data: existingCourse } = await supabase
      .from('courses')
      .select('id, code')
      .eq('id', courseId)
      .single();

    if (!existingCourse) {
      throw new AppError('Course not found', 404, 'COURSE_NOT_FOUND');
    }

    // Check if course has groups
    const { data: groups } = await supabase
      .from('groups')
      .select('id')
      .eq('course_id', courseId)
      .limit(1);

    if (groups && groups.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete course with existing groups',
        code: 'COURSE_HAS_GROUPS'
      });
    }

    // Delete course
    const { error } = await supabase
      .from('courses')
      .delete()
      .eq('id', courseId);

    if (error) {
      console.error('Delete course error:', error);
      throw new AppError('Failed to delete course', 500, 'DELETE_COURSE_FAILED');
    }

    res.json(buildResponse(true, 'Course deleted successfully'));
  });

  /**
   * Get courses by semester
   */
  getCoursesBySemester = catchAsync(async (req, res) => {
    const { semesterId } = req.params;
    const {
      page = 1,
      limit = 20,
      search = '',
      status = 'all'
    } = req.query;

    const offset = (parseInt(page) - 1) * parseInt(limit);

    // Build query
    let query = supabase
      .from('courses')
      .select(`
        id, code, name, session_count, is_active, 
        created_at, updated_at
      `, { count: 'exact' })
      .eq('semester_id', semesterId);

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

    // Apply pagination
    query = query.order('created_at', { ascending: false })
      .range(offset, offset + parseInt(limit) - 1);

    const { data: courses, error, count } = await query;

    if (error) {
      console.error('Get courses by semester error:', error);
      throw new AppError('Failed to fetch courses', 500, 'GET_COURSES_FAILED');
    }

    // Transform courses: convert snake_case to camelCase
    const transformedCourses = (courses || []).map(course => ({
      id: course.id,
      code: course.code,
      name: course.name,
      sessionCount: course.session_count,
      semesterId: semesterId,
      isActive: course.is_active,
      createdAt: course.created_at,
      updatedAt: course.updated_at
    }));

    res.json(
      buildResponse(true, undefined, {
        courses: transformedCourses,
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
   * Get course statistics
   */
  getCourseStatistics = catchAsync(async (req, res) => {
    try {
      // Get basic statistics
      const { count: totalCount, error: totalError } = await supabase
        .from('courses')
        .select('*', { count: 'exact', head: true });

      const { count: activeCount, error: activeError } = await supabase
        .from('courses')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', true);

      const { count: inactiveCount, error: inactiveError } = await supabase
        .from('courses')
        .select('*', { count: 'exact', head: true })
        .eq('is_active', false);

      if (totalError || activeError || inactiveError) {
        throw new AppError('Failed to get statistics', 500, 'STATISTICS_ERROR');
      }

      const statistics = {
        total_courses: totalCount || 0,
        active_courses: activeCount || 0,
        inactive_courses: inactiveCount || 0
      };

      res.json(buildResponse(true, undefined, statistics));
    } catch (error) {
      console.error('Get course statistics error:', error);
      throw new AppError('Failed to get statistics', 500, 'GET_STATISTICS_FAILED');
    }
  });
}

module.exports = new CourseController();