const { supabase } = require('../services/supabaseClient');
const { hashPassword } = require('../utils/passwordUtils');
const { 
  validateStudentCreation, 
  validateStudentUpdate,
  validateBulkOperation 
} = require('../utils/validators');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');
require('../types/student.type');

class StudentController {
  /**
   * Create single student
   */
  createStudent = catchAsync(async (req, res) => {
    const { username, password, email, fullName, groupId, courseId } = req.body;

    // Enhanced validation
    const validation = validateStudentCreation(req.body);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check for duplicates
    const { data: existingUser } = await supabase
      .from('users')
      .select('id, username, email')
      .or(`username.eq.${username},email.eq.${email}`)
      .single();

    if (existingUser) {
      const conflictField = existingUser.username === username ? 'username' : 'email';
      return res.status(409).json({
        success: false,
        message: `${conflictField.charAt(0).toUpperCase() + conflictField.slice(1)} already exists`,
        conflictField
      });
    }

    // Hash password with enhanced security
    const { hash: passwordHash, salt } = await hashPassword(password, 12);

    // Create student with transaction
    const { data: newStudent, error } = await supabase
      .from('users')
      .insert({
        username: username.toLowerCase().trim(),
        email: email.toLowerCase().trim(),
        password_hash: passwordHash,
        salt,
        full_name: fullName.trim(),
        role: 'student',
        is_active: true
      })
      .select(`
        id, username, email, full_name, role, 
        is_active, created_at
      `)
      .single();

    if (error) {
      console.error('Student creation error:', error);
      throw new AppError('Failed to create student account', 500, 'STUDENT_CREATION_FAILED');
    }

    // Optionally assign to group (and validate with course if provided)
    let assignedGroupId = null;
    let resolvedCourseId = courseId || null;
    if (groupId) {
      const { data: group } = await supabase
        .from('groups')
        .select('id, course_id')
        .eq('id', groupId)
        .single();

      if (!group) {
        return res.status(400).json({
          success: false,
          message: 'Group not found',
          errors: ['GROUP_NOT_FOUND']
        });
      }
      if (resolvedCourseId && group.course_id && resolvedCourseId !== group.course_id) {
        return res.status(400).json({
          success: false,
          message: 'Provided courseId does not match group course',
          errors: ['COURSE_GROUP_MISMATCH']
        });
      }
      resolvedCourseId = group.course_id || resolvedCourseId;

      // Ensure single active enrollment per course: remove enrollments in same course, then insert
        if (resolvedCourseId) {
          const { data: enrollmentsInCourse } = await supabase
            .from('student_enrollments')
            .select('id, group_id, groups(course_id)')
            .eq('student_id', newStudent.id);

          const enrollmentIdsToDelete = (enrollmentsInCourse || [])
            .filter((e) => e.groups && e.groups.course_id === resolvedCourseId)
            .map((e) => e.id);
          if (enrollmentIdsToDelete.length > 0) {
            await supabase
              .from('student_enrollments')
              .delete()
              .in('id', enrollmentIdsToDelete);
          }
        }

        // Resolve semester for the course
        const { data: courseInfo } = await supabase
          .from('courses')
          .select('semester_id')
          .eq('id', resolvedCourseId)
          .single();

        const { error: enrollErr } = await supabase
          .from('student_enrollments')
          .insert({ 
            student_id: newStudent.id, 
            group_id: groupId,
            semester_id: courseInfo ? courseInfo.semester_id : null,
            is_active: true
          });
        if (enrollErr) {
          console.error('Create enrollment error:', enrollErr);
          throw new AppError('Failed to create student enrollment', 500, 'ENROLLMENT_CREATION_FAILED');
        }
        assignedGroupId = groupId;
      
    }

    res.status(201).json(
      buildResponse(true, 'Student account created successfully', {
        user: newStudent,
        group_id: assignedGroupId,
        course_id: resolvedCourseId || null
      })
    );
  });

  /**
   * Get students list with pagination, search, and filters
   */
  getStudents = catchAsync(async (req, res) => {
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
      .from('users')
      .select(`
        id, username, email, full_name, is_active,
        last_login_at, created_at,
        student_enrollments(
          group_id,
          groups(id, course_id)
        )
      `, { count: 'exact' })
      .eq('role', 'student');

    // Apply search filter
    if (search.trim()) {
      query = query.or(`
        full_name.ilike.%${search}%,
        username.ilike.%${search}%,
        email.ilike.%${search}%
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

    const { data: rawStudents, error, count } = await query;

    if (error) {
      console.error('Get students error:', error);
      throw new AppError('Failed to fetch students', 500, 'GET_STUDENTS_FAILED');
    }

    // Enrich with enrollment, group, and course details via dedicated queries
    const userIds = (rawStudents || []).map(s => s.id);
    let enrollMap = new Map();
    let groupMap = new Map();
    let courseMap = new Map();
    
    if (userIds.length > 0) {
      // Get enrollments with group and course details
      const { data: enrollments } = await supabase
        .from('student_enrollments')
        .select(`
          student_id, 
          group_id, 
          groups(
            id,
            name,
            course_id,
            courses(
              id,
              code,
              name,
              session_count,
              is_active
            )
          )
        `) 
        .in('student_id', userIds)
        .order('created_at', { ascending: false });
        
      if (Array.isArray(enrollments)) {
        for (const e of enrollments) {
          if (!enrollMap.has(e.student_id)) {
            enrollMap.set(e.student_id, e);
          }
          
          // Store group details
          if (e.groups) {
            groupMap.set(e.groups.id, {
              id: e.groups.id,
              name: e.groups.name,
              course_id: e.groups.course_id
            });
            
            // Store course details
            if (e.groups.courses) {
              courseMap.set(e.groups.courses.id, {
                id: e.groups.courses.id,
                code: e.groups.courses.code,
                name: e.groups.courses.name,
                session_count: e.groups.courses.session_count,
                is_active: e.groups.courses.is_active
              });
            }
          }
        }
      }
    }

    const students = (rawStudents || []).map((s) => {
      const enroll = enrollMap.get(s.id);
      const groupId = enroll ? enroll.group_id || null : null;
      const courseId = enroll && enroll.groups ? enroll.groups.course_id || null : null;
      
      // Get full group and course objects
      const group = groupId ? groupMap.get(groupId) : null;
      const course = courseId ? courseMap.get(courseId) : null;
      
      const { student_enrollments, ...rest } = s;
      return { 
        ...rest, 
        group_id: groupId, 
        course_id: courseId,
        group: group,
        course: course
      };
    });

    res.json(
      buildResponse(true, undefined, {
        students: students,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: count,
          pages: Math.ceil(count / parseInt(limit))
        }
      })
    );
  });

  /**
   * Update student information
   */
  updateStudent = catchAsync(async (req, res) => {
    const { studentId } = req.params;
    const { email, fullName, isActive, groupId, courseId } = req.body;

    // Validate input
    const validation = validateStudentUpdate(req.body);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    // Check if student exists
    const { data: existingStudent } = await supabase
      .from('users')
      .select('id, email')
      .eq('id', studentId)
      .eq('role', 'student')
      .single();

    if (!existingStudent) {
      throw new AppError('Student not found', 404, 'STUDENT_NOT_FOUND');
    }

    // Check email uniqueness if changed
    if (email && email !== existingStudent.email) {
      const { data: emailExists } = await supabase
        .from('users')
        .select('id')
        .eq('email', email.toLowerCase().trim())
        .neq('id', studentId)
        .single();

      if (emailExists) {
        return res.status(409).json({
          success: false,
          message: 'Email already exists',
          conflictField: 'email'
        });
      }
    }

    // Update student
    const updateData = {};
    if (email) updateData.email = email.toLowerCase().trim();
    if (fullName) updateData.full_name = fullName.trim();
    if (typeof isActive === 'boolean') updateData.is_active = isActive;
    updateData.updated_at = new Date().toISOString();

    const { data: updatedStudent, error } = await supabase
      .from('users')
      .update(updateData)
      .eq('id', studentId)
      .select(`
        id, username, email, full_name, is_active, 
        last_login_at, created_at, updated_at
      `)
      .single();

    if (error) {
      console.error('Update student error:', error);
      throw new AppError('Failed to update student', 500, 'UPDATE_STUDENT_FAILED');
    }

    // Optionally update group membership
    let newGroupId = null;
    let resolvedCourseId = courseId || null;
    if (typeof groupId !== 'undefined') {
        if (groupId === null) {
          // remove enrollments for this student (or by course if provided)
          if (resolvedCourseId) {
            const { data: enrollments } = await supabase
              .from('student_enrollments')
              .select('id, groups(course_id)')
              .eq('student_id', studentId);
            const idsToRemove = (enrollments || [])
              .filter((m) => m.groups && m.groups.course_id === resolvedCourseId)
              .map((m) => m.id);
            if (idsToRemove.length > 0) {
              await supabase
                .from('student_enrollments')
                .delete()
                .in('id', idsToRemove);
            }
          } else {
            await supabase
              .from('student_enrollments')
              .delete()
              .eq('student_id', studentId);
          }
        } else if (groupId) {
          const { data: group } = await supabase
            .from('groups')
            .select('id, course_id')
            .eq('id', groupId)
            .single();
          if (!group) {
            return res.status(400).json({
              success: false,
              message: 'Group not found',
              errors: ['GROUP_NOT_FOUND']
            });
          }
          if (resolvedCourseId && group.course_id && resolvedCourseId !== group.course_id) {
            return res.status(400).json({
              success: false,
              message: 'Provided courseId does not match group course',
              errors: ['COURSE_GROUP_MISMATCH']
            });
          }
          resolvedCourseId = group.course_id || resolvedCourseId;

          // remove existing enrollments in same course
          if (resolvedCourseId) {
            const { data: enrollments } = await supabase
              .from('student_enrollments')
              .select('id, groups(course_id)')
              .eq('student_id', studentId);
            const idsToRemove = (enrollments || [])
              .filter((m) => m.groups && m.groups.course_id === resolvedCourseId)
              .map((m) => m.id);
            if (idsToRemove.length > 0) {
              await supabase
                .from('student_enrollments')
                .delete()
                .in('id', idsToRemove);
            }
          }
          const { data: courseInfo } = await supabase
            .from('courses')
            .select('semester_id')
            .eq('id', resolvedCourseId)
            .single();
          const { error: enrollErr } = await supabase
            .from('student_enrollments')
            .insert({ 
              student_id: studentId, 
              group_id: groupId,
              semester_id: courseInfo ? courseInfo.semester_id : null,
              is_active: true
            });
          if (enrollErr) {
            console.error('Update enrollment error:', enrollErr);
            throw new AppError('Failed to update student enrollment', 500, 'ENROLLMENT_UPDATE_FAILED');
          }
          newGroupId = groupId;
        }
    }

    res.json(
      buildResponse(true, 'Student updated successfully', {
        student: updatedStudent,
        groupId: typeof groupId !== 'undefined' ? newGroupId : undefined,
        courseId: resolvedCourseId || null
      })
    );
  });

  /**
   * Delete student
   */
  deleteStudent = catchAsync(async (req, res) => {
    const { studentId } = req.params;

    // Check if student exists
    const { data: existingStudent } = await supabase
      .from('users')
      .select('id, username')
      .eq('id', studentId)
      .eq('role', 'student')
      .single();

    if (!existingStudent) {
      throw new AppError('Student not found', 404, 'STUDENT_NOT_FOUND');
    }

    // Delete student
    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', studentId);

    if (error) {
      console.error('Delete student error:', error);
      throw new AppError('Failed to delete student', 500, 'DELETE_STUDENT_FAILED');
    }

    res.json(buildResponse(true, 'Student deleted successfully'));
  });

  /**
   * Bulk operations
   */
  bulkUpdateStudents = catchAsync(async (req, res) => {
    const { studentIds, action } = req.body;

    // Validate bulk operation
    const validation = validateBulkOperation(req.body);
    if (!validation.isValid) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: validation.errors
      });
    }

    let result;
    switch (action) {
      case 'activate':
        result = await supabase
          .from('users')
          .update({ is_active: true, updated_at: new Date().toISOString() })
          .in('id', studentIds)
          .eq('role', 'student');
        break;

      case 'deactivate':
        result = await supabase
          .from('users')
          .update({ is_active: false, updated_at: new Date().toISOString() })
          .in('id', studentIds)
          .eq('role', 'student');
        break;

      case 'delete':
        result = await supabase
          .from('users')
          .delete()
          .in('id', studentIds)
          .eq('role', 'student');
        break;

      default:
        throw new AppError('Invalid bulk action', 400, 'INVALID_BULK_ACTION');
    }

    if (result.error) {
      console.error('Bulk operation error:', result.error);
      throw new AppError('Failed to perform bulk operation', 500, 'BULK_OPERATION_FAILED');
    }

    res.json(
      buildResponse(true, `Bulk ${action} completed successfully`, undefined, { affectedCount: result.count || studentIds.length })
    );
  });

  /**
   * Get student statistics
   */
  getStudentStatistics = catchAsync(async (req, res) => {
    try {
      // Get basic statistics
      const { count: totalCount, error: totalError } = await supabase
        .from('users')
        .select('*', { count: 'exact', head: true })
        .eq('role', 'student');

      const { count: activeCount, error: activeError } = await supabase
        .from('users')
        .select('*', { count: 'exact', head: true })
        .eq('role', 'student')
        .eq('is_active', true);

      const { count: inactiveCount, error: inactiveError } = await supabase
        .from('users')
        .select('*', { count: 'exact', head: true })
        .eq('role', 'student')
        .eq('is_active', false);

      // Get students who logged in last 7 days
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      
      const { count: recentLoginsCount, error: recentError } = await supabase
        .from('users')
        .select('*', { count: 'exact', head: true })
        .eq('role', 'student')
        .gte('last_login_at', sevenDaysAgo.toISOString());

      // Get students who never logged in
      const { count: neverLoggedInCount, error: neverError } = await supabase
        .from('users')
        .select('*', { count: 'exact', head: true })
        .eq('role', 'student')
        .is('last_login_at', null);

      if (totalError || activeError || inactiveError || recentError || neverError) {
        throw new AppError('Failed to get statistics', 500, 'STATISTICS_ERROR');
      }

      const statistics = {
        total_students: totalCount || 0,
        active_students: activeCount || 0,
        inactive_students: inactiveCount || 0,
        students_logged_in_last_7_days: recentLoginsCount || 0,
        students_never_logged_in: neverLoggedInCount || 0
      };

    res.json(buildResponse(true, undefined, statistics));
    } catch (error) {
      console.error('Get statistics error:', error);
      throw new AppError('Failed to get statistics', 500, 'GET_STATISTICS_FAILED');
    }
  });

  /**
   * Reset student password
   */
  resetStudentPassword = catchAsync(async (req, res) => {
    const { studentId } = req.params;
    const { newPassword } = req.body;

    // Validate password
    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters long'
      });
    }

    // Check if student exists
    const { data: student } = await supabase
      .from('users')
      .select('id')
      .eq('id', studentId)
      .eq('role', 'student')
      .single();

    if (!student) {
      throw new AppError('Student not found', 404, 'STUDENT_NOT_FOUND');
    }

    // Hash new password
    const { hash: passwordHash, salt } = await hashPassword(newPassword, 12);

    // Update password
    const { error } = await supabase
      .from('users')
      .update({
        password_hash: passwordHash,
        salt,
        updated_at: new Date().toISOString()
      })
      .eq('id', studentId);

    if (error) {
      console.error('Password reset error:', error);
      throw new AppError('Failed to reset password', 500, 'PASSWORD_RESET_FAILED');
    }

    // Note: Session invalidation will be implemented when user_sessions table is added

    res.json(buildResponse(true, 'Password reset successfully'));
  });

  /**
   * Export students as CSV file download
   */
  exportStudents = catchAsync(async (req, res) => {
    const { format = 'csv' } = req.query;

    // Only csv supported for now
    if (String(format).toLowerCase() !== 'csv') {
      return res.status(400).json({ success: false, message: 'Unsupported format' });
    }

    // Get all students
    const { data: students, error } = await supabase
      .from('users')
      .select('id, username, email, full_name, is_active, created_at, last_login_at')
      .eq('role', 'student')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Export students error:', error);
      throw new AppError('Failed to export students', 500, 'EXPORT_FAILED');
    }

    const jsoncsv = require('json-csv');
    const fields = [
      { name: 'id', label: 'ID' },
      { name: 'username', label: 'username' },
      { name: 'email', label: 'email' },
      { name: 'full_name', label: 'fullName' },
      { name: 'is_active', label: 'isActive', transform: (v) => (v ? 'true' : 'false') },
      { name: 'created_at', label: 'createdAt' },
      { name: 'last_login_at', label: 'lastLoginAt' }
    ];
    const csv = await jsoncsv.buffered(students || [], { fields, encoding: 'utf8', ignoreHeader: false });

    const filename = `students_${new Date().toISOString().slice(0,19).replace(/[:T]/g, '-')}.csv`;
    // Add BOM for Excel compatibility
    const bom = Buffer.from([0xEF, 0xBB, 0xBF]);
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.status(200).send(Buffer.concat([bom, Buffer.from(csv, 'utf8')]));
  });

  /**
   * Preview CSV import: validate and check conflicts, return per-row status
   */
  previewImport = catchAsync(async (req, res) => {
    const { records } = req.body || {};
    if (!Array.isArray(records) || records.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payload: records must be a non-empty array'
      });
    }

    // Normalize inputs
    const normalized = records.map((r, idx) => ({
      rowNumber: idx + 1,
      fullName: (r.fullName || '').toString().trim(),
      email: (r.email || '').toString().toLowerCase().trim(),
      username: (r.username || '').toString().toLowerCase().trim(),
      initialPassword: (r.initialPassword || '').toString()
    }));

    // Detect duplicates inside file
    const seenUsernames = new Set();
    const seenEmails = new Set();
    const inFileDuplicateUsername = new Set();
    const inFileDuplicateEmail = new Set();
    for (const r of normalized) {
      if (seenUsernames.has(r.username)) inFileDuplicateUsername.add(r.username);
      seenUsernames.add(r.username);
      if (seenEmails.has(r.email)) inFileDuplicateEmail.add(r.email);
      seenEmails.add(r.email);
    }

    // Check existing in DB (role=student)
    const usernames = normalized.map(r => r.username).filter(Boolean);
    const emails = normalized.map(r => r.email).filter(Boolean);

    let existingByUsername = new Set();
    let existingByEmail = new Set();
    if (usernames.length > 0) {
      const { data } = await supabase
        .from('users')
        .select('username')
        .eq('role', 'student')
        .in('username', Array.from(new Set(usernames)));
      if (Array.isArray(data)) existingByUsername = new Set(data.map(d => (d.username || '').toLowerCase()));
    }
    if (emails.length > 0) {
      const { data } = await supabase
        .from('users')
        .select('email')
        .eq('role', 'student')
        .in('email', Array.from(new Set(emails)));
      if (Array.isArray(data)) existingByEmail = new Set(data.map(d => (d.email || '').toLowerCase()));
    }

    const results = [];
    let created = 0, existing = 0, errors = 0;
    for (const r of normalized) {
      const rowErrors = [];
      // Basic field validations (reuse creation rules loosely)
      if (!r.fullName || r.fullName.length < 2 || r.fullName.length > 50) rowErrors.push('invalid fullName');
      if (!r.email) rowErrors.push('email required');
      if (!r.username) rowErrors.push('username required');

      if (inFileDuplicateUsername.has(r.username)) rowErrors.push('duplicate username in file');
      if (inFileDuplicateEmail.has(r.email)) rowErrors.push('duplicate email in file');
      if (existingByUsername.has(r.username)) rowErrors.push('username already exists');
      if (existingByEmail.has(r.email)) rowErrors.push('email already exists');

      if (rowErrors.length > 0) {
        results.push({ rowNumber: r.rowNumber, status: 'ERROR', errors: rowErrors });
        errors++;
      } else {
        results.push({ rowNumber: r.rowNumber, status: 'READY' });
        created++; // "potentially creatable"
      }
    }

    return res.json({
      success: true,
      summary: { ready: created, existing, errors, total: normalized.length },
      results
    });
  });

  /**
   * Import students: create accounts for valid rows, return per-row results
   */
  importStudents = catchAsync(async (req, res) => {
    const { records, globalCourseId, globalGroupId, assignments } = req.body || {};
    if (!Array.isArray(records) || records.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payload: records must be a non-empty array'
      });
    }

    // Normalize
    const normalized = records.map((r, idx) => ({
      rowNumber: idx + 1,
      fullName: (r.fullName || '').toString().trim(),
      email: (r.email || '').toString().toLowerCase().trim(),
      username: (r.username || '').toString().toLowerCase().trim(),
      initialPassword: (r.initialPassword || '').toString()
    }));

    // Pre-check duplicates/file conflicts as in preview
    const seenUsernames = new Set();
    const seenEmails = new Set();
    const inFileDuplicateUsername = new Set();
    const inFileDuplicateEmail = new Set();
    for (const r of normalized) {
      if (seenUsernames.has(r.username)) inFileDuplicateUsername.add(r.username);
      seenUsernames.add(r.username);
      if (seenEmails.has(r.email)) inFileDuplicateEmail.add(r.email);
      seenEmails.add(r.email);
    }

    // Existing checks
    const usernames = normalized.map(r => r.username).filter(Boolean);
    const emails = normalized.map(r => r.email).filter(Boolean);
    let existingByUsername = new Set();
    let existingByEmail = new Set();
    if (usernames.length > 0) {
      const { data } = await supabase
        .from('users')
        .select('username')
        .eq('role', 'student')
        .in('username', Array.from(new Set(usernames)));
      if (Array.isArray(data)) existingByUsername = new Set(data.map(d => (d.username || '').toLowerCase()));
    }
    if (emails.length > 0) {
      const { data } = await supabase
        .from('users')
        .select('email')
        .eq('role', 'student')
        .in('email', Array.from(new Set(emails)));
      if (Array.isArray(data)) existingByEmail = new Set(data.map(d => (d.email || '').toLowerCase()));
    }

    const results = [];
    let created = 0, existing = 0, errors = 0;

    // Batch insert with small chunks to keep isolation
    const chunkSize = 100;
    for (let i = 0; i < normalized.length; i += chunkSize) {
      const chunk = normalized.slice(i, i + chunkSize);
      // Prepare rows to insert
      const rowsToInsert = [];
      const chunkIndexMap = new Map();
      for (const r of chunk) {
        const rowErrors = [];
        if (!r.fullName || r.fullName.length < 2 || r.fullName.length > 50) rowErrors.push('invalid fullName');
        if (!r.email) rowErrors.push('email required');
        if (!r.username) rowErrors.push('username required');
        if (inFileDuplicateUsername.has(r.username)) rowErrors.push('duplicate username in file');
        if (inFileDuplicateEmail.has(r.email)) rowErrors.push('duplicate email in file');
        if (existingByUsername.has(r.username)) rowErrors.push('username already exists');
        if (existingByEmail.has(r.email)) rowErrors.push('email already exists');

        if (rowErrors.length > 0) {
          results.push({ rowNumber: r.rowNumber, status: 'ERROR', errors: rowErrors });
          errors++;
          continue;
        }

        const passwordPlain = r.initialPassword && r.initialPassword.length >= 6
          ? r.initialPassword
          : Math.random().toString(36).slice(-10);
        const { hash: password_hash, salt } = await hashPassword(passwordPlain, 12);

        rowsToInsert.push({
          username: r.username,
          email: r.email,
          password_hash,
          salt,
          full_name: r.fullName,
          role: 'student',
          is_active: true
        });
        chunkIndexMap.set(rowsToInsert.length - 1, r.rowNumber);
      }

      if (rowsToInsert.length === 0) continue;

      // Try batch insert
      const { data: inserted, error } = await supabase
        .from('users')
        .insert(rowsToInsert)
        .select('id, username');

      if (!error && Array.isArray(inserted)) {
        // Mark as CREATED
        created += inserted.length;
        for (let k = 0; k < inserted.length; k++) {
          const rowNumber = chunkIndexMap.get(k);
          results.push({ rowNumber, status: 'CREATED', studentId: inserted[k].id });
        }
        
        // Handle course/group assignments for created students
        await this.handleStudentAssignments(inserted, chunkIndexMap, globalCourseId, globalGroupId, assignments);
      } else {
        // Fallback per-row to isolate errors
        for (let k = 0; k < rowsToInsert.length; k++) {
          const payload = rowsToInsert[k];
          const rowNumber = chunkIndexMap.get(k);
          const { data: single, error: singleError } = await supabase
            .from('users')
            .insert(payload)
            .select('id')
            .single();
          if (singleError) {
            results.push({ rowNumber, status: 'ERROR', errors: ['insert failed'] });
            errors++;
          } else {
            results.push({ rowNumber, status: 'CREATED', studentId: single.id });
            created++;
            
            // Handle course/group assignment for single student
            await this.handleStudentAssignments([single], new Map([[0, rowNumber]]), globalCourseId, globalGroupId, assignments);
          }
        }
      }
    }

    res.json({
      success: true,
      summary: { created, existing, errors, total: normalized.length },
      results
    });
  });

  /**
   * Get CSV template content
   */
  getImportTemplate = catchAsync(async (req, res) => {
    const csv = 'full_name,email,username,initial_password\n' +
      'Nguyễn Văn A,a@classroom.edu,nguyenvana,student123\n' +
      'Trần Thị B,b@classroom.edu,tranthib,\n';
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="student_template.csv"');
    res.send(csv);
  });

  /**
   * Handle course/group assignments for imported students
   */
  handleStudentAssignments = async (students, chunkIndexMap, globalCourseId, globalGroupId, assignments) => {
    if (!students || students.length === 0) return;

    for (let i = 0; i < students.length; i++) {
      const student = students[i];
      const rowNumber = chunkIndexMap.get(i);
      
      // Determine course and group for this student
      let courseId = globalCourseId;
      let groupId = globalGroupId;
      
      // Check for individual assignment
      if (assignments && assignments[rowNumber]) {
        const assignment = assignments[rowNumber];
        if (assignment.courseId) courseId = assignment.courseId;
        if (assignment.groupId) groupId = assignment.groupId;
      }
      
      // Skip if no assignment provided
      if (!courseId && !groupId) continue;
      
      try {
        // If only courseId provided, we need to find a default group or create one
        if (courseId && !groupId) {
          const { data: defaultGroup } = await supabase
            .from('groups')
            .select('id')
            .eq('course_id', courseId)
            .eq('is_active', true)
            .limit(1)
            .single();
          
          if (defaultGroup) {
            groupId = defaultGroup.id;
          }
        }
        
        // If only groupId provided, get courseId from group
        if (groupId && !courseId) {
          const { data: group } = await supabase
            .from('groups')
            .select('course_id')
            .eq('id', groupId)
            .single();
          
          if (group) {
            courseId = group.course_id;
          }
        }
        
        // Create enrollment if we have both courseId and groupId
        if (courseId && groupId) {
          // Get semester_id from course
          const { data: courseInfo } = await supabase
            .from('courses')
            .select('semester_id')
            .eq('id', courseId)
            .single();
          
          // Remove existing enrollments in same course
          const { data: existingEnrollments } = await supabase
            .from('student_enrollments')
            .select('id, groups(course_id)')
            .eq('student_id', student.id);
          
          const enrollmentIdsToDelete = (existingEnrollments || [])
            .filter((e) => e.groups && e.groups.course_id === courseId)
            .map((e) => e.id);
          
          if (enrollmentIdsToDelete.length > 0) {
            await supabase
              .from('student_enrollments')
              .delete()
              .in('id', enrollmentIdsToDelete);
          }
          
          // Create new enrollment
          const { error: enrollError } = await supabase
            .from('student_enrollments')
            .insert({
              student_id: student.id,
              group_id: groupId,
              semester_id: courseInfo ? courseInfo.semester_id : null,
              is_active: true
            });
          
          if (enrollError) {
            console.error('Enrollment creation error for student', student.id, ':', enrollError);
          }
        }
      } catch (error) {
        console.error('Assignment error for student', student.id, ':', error);
      }
    }
  };
}

module.exports = new StudentController();