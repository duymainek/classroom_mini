const { supabase } = require('../services/supabaseClient');
const { hashPassword, verifyPassword } = require('../utils/passwordUtils');
const { generateTokenPair } = require('../utils/tokenUtils');
const { 
  validateLogin, 
  validateUserCreation, 
  validateRefreshToken,
  sanitizeUserData 
} = require('../utils/validators');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');
require('../types/auth.type');

class AuthController {
  /**
   * Instructor login endpoint
   */
  instructorLogin = catchAsync(async (req, res) => {
    const { username, password } = req.body;

    // Validate input
    const validation = validateLogin({ username, password });
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if admin credentials
    if (username !== 'admin') {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Get instructor from database
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('username', 'admin')
      .eq('role', 'instructor')
      .eq('is_active', true)
      .single();

    console.log(user);

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Verify password
    const isValidPassword = await verifyPassword(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate JWT tokens
    const tokens = generateTokenPair({
      userId: user.id,
      role: user.role,
      username: user.username
    });

    // Update last login
    await supabase
      .from('users')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', user.id);

    // Store session (optional - could be implemented later)
    // await this.createSession(user.id, tokens.accessToken, tokens.refreshToken, req);

    res.json(
      buildResponse(true, 'Login successful', {
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          full_name: user.full_name,
          is_active: user.is_active,
          last_login_at: user.last_login_at,
          created_at: user.created_at,
          role: user.role,
          avatar_url: user.avatar_url || null
        },
        tokens
      })
    );
  });

  /**
   * Student login endpoint
   */
  studentLogin = catchAsync(async (req, res) => {
    const { username, password } = req.body;

    // Validate input
    const validation = validateLogin({ username, password });
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Get student from database
    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('username', username)
      .eq('role', 'student')
      .eq('is_active', true)
      .single();

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Verify password
    const isValidPassword = await verifyPassword(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Generate JWT tokens
    const tokens = generateTokenPair({
      userId: user.id,
      role: user.role,
      username: user.username
    });

    // Update last login
    await supabase
      .from('users')
      .update({ last_login_at: new Date().toISOString() })
      .eq('id', user.id);

    res.json(
      buildResponse(true, 'Login successful', {
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          full_name: user.full_name,
          is_active: user.is_active,
          last_login_at: user.last_login_at,
          created_at: user.created_at,
          role: user.role,
          avatar_url: user.avatar_url || null
        },
        tokens
      })
    );
  });

  /**
   * Create student account (instructor only)
   */
  createStudent = catchAsync(async (req, res) => {
    const { username, password, email, fullName, groupId, courseId } = req.body;

    // Validate input
    const validation = validateUserCreation({ username, password, email, fullName });
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if username/email already exists
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .or(`username.eq.${username},email.eq.${email}`)
      .single();

    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'Username or email already exists'
      });
    }

    // Hash password
    const { hash: passwordHash, salt } = await hashPassword(password);

    // Create user
    const { data: newUser, error } = await supabase
      .from('users')
      .insert({
        username,
        email,
        password_hash: passwordHash,
        salt,
        full_name: fullName,
        role: 'student',
        is_active: true
      })
      .select()
      .single();

    if (error) {
      console.error('User creation error:', error);
      throw new AppError('Failed to create user account', 500, 'USER_CREATION_FAILED');
    }

    // Optional: create enrollment when groupId provided (and validate with courseId)
    let assignedGroupId = null;
    let resolvedCourseId = courseId || null;
    if (groupId) {
      // Validate group exists and resolve course
      const { data: group } = await supabase
        .from('groups')
        .select('id, course_id')
        .eq('id', groupId)
        .single();

      if (!group) {
        // Cleanup created user to avoid dangling account
        await supabase.from('users').delete().eq('id', newUser.id);
        throw new AppError('Group not found', 400, 'GROUP_NOT_FOUND');
      }

      if (resolvedCourseId && group.course_id && resolvedCourseId !== group.course_id) {
        await supabase.from('users').delete().eq('id', newUser.id);
        throw new AppError('Provided courseId does not match group course', 400, 'COURSE_GROUP_MISMATCH');
      }
      resolvedCourseId = group.course_id || resolvedCourseId;

      // Remove existing enrollments in same course (safety)
      if (resolvedCourseId) {
        const { data: existingEnrollments } = await supabase
          .from('student_enrollments')
          .select('id, groups(course_id)')
          .eq('student_id', newUser.id);
        const idsToRemove = (existingEnrollments || [])
          .filter(e => e.groups && e.groups.course_id === resolvedCourseId)
          .map(e => e.id);
        if (idsToRemove.length > 0) {
          await supabase
            .from('student_enrollments')
            .delete()
            .in('id', idsToRemove);
        }
      }

      // Resolve semester from course
      let semesterId = null;
      if (resolvedCourseId) {
        const { data: course } = await supabase
          .from('courses')
          .select('semester_id')
          .eq('id', resolvedCourseId)
          .single();
        semesterId = course ? course.semester_id : null;
      }

      const { error: enrollErr } = await supabase
        .from('student_enrollments')
        .insert({
          student_id: newUser.id,
          group_id: groupId,
          semester_id: semesterId,
          is_active: true
        });
      if (enrollErr) {
        console.error('Enrollment creation error (auth.createStudent):', enrollErr);
        // Best-effort cleanup user to keep data consistent
        await supabase.from('users').delete().eq('id', newUser.id);
        throw new AppError('Failed to create student enrollment', 500, 'ENROLLMENT_CREATION_FAILED');
      }
      assignedGroupId = groupId;
    }

    res.status(201).json(
      buildResponse(true, 'Student account created successfully', {
        user: sanitizeUserData(newUser),
        group_id: assignedGroupId,
        course_id: resolvedCourseId || null
      })
    );
  });

  /**
   * Get current user information
   */
  getCurrentUser = catchAsync(async (req, res) => {
    const userId = req.user.id;

    const { data: user, error } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .eq('is_active', true)
      .single();

    if (error || !user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    res.json(
      buildResponse(true, undefined, {
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          full_name: user.full_name,
          is_active: user.is_active,
          last_login_at: user.last_login_at,
          created_at: user.created_at,
          role: user.role,
          avatar_url: user.avatar_url || null
        }
      })
    );
  });

  /**
   * Refresh access token
   */
  refreshToken = catchAsync(async (req, res) => {
    const { refreshToken } = req.body;

    // Validate input
    const validation = validateRefreshToken({ refreshToken });
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Verify refresh token
    let decoded;
    try {
      const { verifyRefreshToken } = require('../utils/tokenUtils');
      decoded = verifyRefreshToken(refreshToken);
    } catch (error) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or expired refresh token'
      });
    }

    // Get user from database
    const { data: user, error } = await supabase
      .from('users')
      .select('id, username, role, is_active')
      .eq('id', decoded.userId)
      .eq('is_active', true)
      .single();

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'User not found or inactive'
      });
    }

    // Generate new token pair
    const tokens = generateTokenPair({
      userId: user.id,
      role: user.role,
      username: user.username
    });

    res.json(buildResponse(true, 'Tokens refreshed successfully', { tokens }));
  });

  /**
   * Logout endpoint
   */
  logout = catchAsync(async (req, res) => {
    // In a more complete implementation, you would:
    // 1. Invalidate the refresh token in the database
    // 2. Add the access token to a blacklist
    // 3. Clear any server-side sessions

    // For now, we'll just return success
    // The client should clear tokens from local storage
    res.json(buildResponse(true, 'Logged out successfully'));
  });

  /**
   * Update user profile
   */
  updateProfile = catchAsync(async (req, res) => {
    const userId = req.user.id;
    const { email, avatarUrl } = req.body;

    // Build update object
    const updateData = {};
    if (email) updateData.email = email;
    if (avatarUrl) updateData.avatar_url = avatarUrl;

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No valid fields provided for update'
      });
    }

    updateData.updated_at = new Date().toISOString();

    // Update user
    const { data: updatedUser, error } = await supabase
      .from('users')
      .update(updateData)
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      console.error('Profile update error:', error);
      throw new AppError('Failed to update profile', 500, 'PROFILE_UPDATE_FAILED');
    }

    res.json(
      buildResponse(true, 'Profile updated successfully', { user: sanitizeUserData(updatedUser) })
    );
  });

  /**
   * Get all students (instructor only)
   */
  getStudents = catchAsync(async (req, res) => {
    const { data: students, error } = await supabase
      .from('users')
      .select('id, username, email, full_name, is_active, created_at, last_login_at')
      .eq('role', 'student')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Get students error:', error);
      throw new AppError('Failed to retrieve students', 500, 'GET_STUDENTS_FAILED');
    }

    res.json(
      buildResponse(true, undefined, { students: students.map(student => sanitizeUserData(student)) })
    );
  });

  /**
   * Toggle student active status (instructor only)
   */
  toggleStudentStatus = catchAsync(async (req, res) => {
    const { studentId } = req.params;
    const { isActive } = req.body;

    // Update student status
    const { data: updatedStudent, error } = await supabase
      .from('users')
      .update({ 
        is_active: isActive,
        updated_at: new Date().toISOString()
      })
      .eq('id', studentId)
      .eq('role', 'student')
      .select()
      .single();

    if (error || !updatedStudent) {
      throw new AppError('Student not found or update failed', 404, 'STUDENT_NOT_FOUND');
    }

    res.json(
      buildResponse(true, `Student ${isActive ? 'activated' : 'deactivated'} successfully`, {
        student: sanitizeUserData(updatedStudent)
      })
    );
  });
}

module.exports = new AuthController();