const { supabase } = require('../services/supabaseClient');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');
require('../types/dashboard.type');

class DashboardController {
  /**
   * Get instructor dashboard statistics
   */
  getInstructorDashboard = catchAsync(async (req, res) => {
    try {
      const userId = req.user.id;

      // Get user's current semester preference first
      const { data: user } = await supabase
        .from('users')
        .select('current_semester_id')
        .eq('id', userId)
        .single();

      let currentSemester = null;

      if (user?.current_semester_id) {
        // Use user's preferred semester
        const { data: semester } = await supabase
          .from('semesters')
          .select('*')
          .eq('id', user.current_semester_id)
          .single();
        currentSemester = semester;
      }

      // Fallback to most recent active semester if no preference
      if (!currentSemester) {
        const { data: semester } = await supabase
          .from('semesters')
          .select('*')
          .eq('is_active', true)
          .order('created_at', { ascending: false })
          .limit(1)
          .single();
        currentSemester = semester;
      }

      if (!currentSemester) {
        return res.json(
          buildResponse(true, undefined, {
            currentSemester: null,
            statistics: {
              totalCourses: 0,
              totalGroups: 0,
              totalStudents: 0,
              totalAssignments: 0,
              totalQuizzes: 0
            },
            recentActivity: []
          })
        );
      }

      // Get statistics for current semester
      const [
        coursesResult,
        groupsResult,
        studentsResult,
        assignmentsResult,
        quizzesResult
      ] = await Promise.all([
        // Total courses in current semester
        supabase
          .from('courses')
          .select('*', { count: 'exact', head: true })
          .eq('semester_id', currentSemester.id),

        // Total groups in current semester
        supabase
          .from('groups')
          .select('*, courses!inner(*)', { count: 'exact', head: true })
          .eq('courses.semester_id', currentSemester.id),

        // Total students in database (role = student)
        supabase
          .from('users')
          .select('*', { count: 'exact', head: true })
          .eq('role', 'student'),

        // Total assignments in current semester
        supabase
          .from('assignments')
          .select('*, courses!inner(*)', { count: 'exact', head: true })
          .eq('courses.semester_id', currentSemester.id),

        // Total quizzes in current semester
        supabase
          .from('quizzes')
          .select('*, courses!inner(*)', { count: 'exact', head: true })
          .eq('courses.semester_id', currentSemester.id)
      ]);

      const statistics = {
        totalCourses: coursesResult.count || 0,
        totalGroups: groupsResult.count || 0,
        totalStudents: studentsResult.count || 0,
        totalAssignments: assignmentsResult.count || 0,
        totalQuizzes: quizzesResult.count || 0
      };

      // Get recent activity (last 10 activities)
      const { data: recentActivity } = await supabase
        .from('activity_logs')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false })
        .limit(10);

      res.json(
        buildResponse(true, undefined, {
          currentSemester,
          statistics,
          recentActivity: recentActivity || []
        })
      );
    } catch (error) {
      console.error('Get instructor dashboard error:', error);
      throw new AppError('Failed to get dashboard data', 500, 'DASHBOARD_ERROR');
    }
  });

  /**
   * Get student dashboard data
   */
  getStudentDashboard = catchAsync(async (req, res) => {
    try {
      const userId = req.user.id;

      // Get current semester
      const { data: currentSemester } = await supabase
        .from('semesters')
        .select('*')
        .eq('is_active', true)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (!currentSemester) {
        return res.json(
          buildResponse(true, undefined, {
            currentSemester: null,
            enrolledCourses: [],
            upcomingAssignments: [],
            recentSubmissions: []
          })
        );
      }

      // Get student's enrolled courses for current semester
      const { data: enrolledCourses } = await supabase
        .from('student_enrollments')
        .select(`
          *,
          courses!inner(
            *,
            semesters!inner(*)
          ),
          groups!inner(*)
        `)
        .eq('student_id', userId)
        .eq('semester_id', currentSemester.id);

      // Get upcoming assignments (next 7 days)
      const sevenDaysFromNow = new Date();
      sevenDaysFromNow.setDate(sevenDaysFromNow.getDate() + 7);

      const { data: upcomingAssignments } = await supabase
        .from('assignments')
        .select(`
          *,
          courses!inner(
            *,
            semesters!inner(*)
          )
        `)
        .eq('courses.semester_id', currentSemester.id)
        .gte('due_date', new Date().toISOString())
        .lte('due_date', sevenDaysFromNow.toISOString())
        .order('due_date', { ascending: true });

      // Get recent submissions (last 10)
      const { data: recentSubmissions } = await supabase
        .from('assignment_submissions')
        .select(`
          *,
          assignments!inner(
            *,
            courses!inner(*)
          )
        `)
        .eq('student_id', userId)
        .order('submitted_at', { ascending: false })
        .limit(10);

      res.json(
        buildResponse(true, undefined, {
          currentSemester,
          enrolledCourses: enrolledCourses || [],
          upcomingAssignments: upcomingAssignments || [],
          recentSubmissions: recentSubmissions || []
        })
      );
    } catch (error) {
      console.error('Get student dashboard error:', error);
      throw new AppError('Failed to get dashboard data', 500, 'DASHBOARD_ERROR');
    }
  });

  /**
   * Get current semester
   */
  getCurrentSemester = catchAsync(async (req, res) => {
    try {
      const { data: currentSemester } = await supabase
        .from('semesters')
        .select('*')
        .eq('is_active', true)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      res.json(buildResponse(true, undefined, { currentSemester }));
    } catch (error) {
      console.error('Get current semester error:', error);
      throw new AppError('Failed to get current semester', 500, 'CURRENT_SEMESTER_ERROR');
    }
  });

  /**
   * Switch semester context
   */
  switchSemester = catchAsync(async (req, res) => {
    try {
      const { semesterId } = req.params;
      const userId = req.user.id;

      // Verify semester exists and is accessible
      const { data: semester } = await supabase
        .from('semesters')
        .select('*')
        .eq('id', semesterId)
        .single();

      if (!semester) {
        throw new AppError('Semester not found', 404, 'SEMESTER_NOT_FOUND');
      }

      // Update user's current semester preference
      await supabase
        .from('users')
        .update({ current_semester_id: semesterId })
        .eq('id', userId);

      res.json(
        buildResponse(true, 'Semester context switched successfully', { semester })
      );
    } catch (error) {
      console.error('Switch semester error:', error);
      throw new AppError('Failed to switch semester', 500, 'SWITCH_SEMESTER_ERROR');
    }
  });
}

module.exports = new DashboardController();