const { supabase } = require('../services/supabaseClient');
const { AppError, catchAsync } = require('../middleware/errorHandler');
const { buildResponse } = require('../utils/response');
require('../types/dashboard.type');

class DashboardController {
  /**
   * Get student dashboard statistics
   */
  getStudentDashboard = catchAsync(async (req, res) => {
    try {
      const userId = req.user.id;
      const { semesterId } = req.query;

      let activeSemesterId = semesterId;
      if (!activeSemesterId) {
        const { data: user } = await supabase
          .from('users')
          .select('current_semester_id')
          .eq('id', userId)
          .single();
        
        activeSemesterId = user?.current_semester_id;
      }

      if (!activeSemesterId) {
        const { data: semester } = await supabase
          .from('semesters')
          .select('id')
          .eq('is_active', true)
          .order('created_at', { ascending: false })
          .limit(1)
          .single();
        
        activeSemesterId = semester?.id;
      }

      const [
        enrolledCoursesResult,
        assignmentsResult,
        quizzesResult,
        submissionsResult,
        quizSubmissionsResult,
        upcomingDeadlinesResult
      ] = await Promise.all([
        supabase
          .from('student_enrollments')
          .select('id', { count: 'exact', head: true })
          .eq('student_id', userId)
          .eq('is_active', true)
          .eq('semester_id', activeSemesterId || ''),

        supabase
          .from('assignments')
          .select('id, courses!inner(semester_id), assignment_groups!inner(group_id, groups!inner(student_enrollments(student_id)))', { count: 'exact', head: true })
          .eq('courses.semester_id', activeSemesterId || '')
          .eq('assignment_groups.groups.student_enrollments.student_id', userId),

        supabase
          .from('quizzes')
          .select('id, courses!inner(semester_id), quiz_groups!inner(group_id, groups!inner(student_enrollments(student_id)))', { count: 'exact', head: true })
          .eq('courses.semester_id', activeSemesterId || '')
          .eq('quiz_groups.groups.student_enrollments.student_id', userId),

        supabase
          .from('assignment_submissions')
          .select('id, grade', { count: 'exact' })
          .eq('student_id', userId),

        supabase
          .from('quiz_submissions')
          .select('id, grade', { count: 'exact' })
          .eq('student_id', userId),

        supabase.rpc('get_student_upcoming_deadlines', { 
          p_student_id: userId,
          p_limit: 5
        })
      ]);

      const totalAssignments = assignmentsResult.count || 0;
      const totalQuizzes = quizzesResult.count || 0;
      const submissions = submissionsResult.data || [];
      const quizSubmissions = quizSubmissionsResult.data || [];

      const submittedAssignments = submissions.length;
      const completedQuizzes = quizSubmissions.length;
      const pendingAssignments = Math.max(0, totalAssignments - submittedAssignments);
      const pendingQuizzes = Math.max(0, totalQuizzes - completedQuizzes);

      const gradedAssignments = submissions.filter(s => s.grade !== null);
      const gradedQuizzes = quizSubmissions.filter(s => s.grade !== null);
      
      const avgAssignmentGrade = gradedAssignments.length > 0
        ? gradedAssignments.reduce((sum, s) => sum + parseFloat(s.grade || 0), 0) / gradedAssignments.length
        : 0;
      
      const avgQuizGrade = gradedQuizzes.length > 0
        ? gradedQuizzes.reduce((sum, s) => sum + parseFloat(s.grade || 0), 0) / gradedQuizzes.length
        : 0;

      return res.json(buildResponse(true, undefined, {
        enrolledCourses: enrolledCoursesResult.count || 0,
        assignments: {
          total: totalAssignments,
          submitted: submittedAssignments,
          pending: pendingAssignments,
          graded: gradedAssignments.length,
          averageGrade: parseFloat(avgAssignmentGrade.toFixed(2))
        },
        quizzes: {
          total: totalQuizzes,
          completed: completedQuizzes,
          pending: pendingQuizzes,
          graded: gradedQuizzes.length,
          averageGrade: parseFloat(avgQuizGrade.toFixed(2))
        },
        upcomingDeadlines: upcomingDeadlinesResult.data || []
      }));
    } catch (error) {
      console.error('Student dashboard error:', error);
      throw new AppError('Failed to get student dashboard', 500, 'STUDENT_DASHBOARD_FAILED');
    }
  });

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
              totalQuizzes: 0,
              totalAnnouncements: 0
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
        quizzesResult,
        announcementsResult
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
          .eq('courses.semester_id', currentSemester.id),

        // Total announcements in current semester
        supabase
          .from('announcements')
          .select('*, courses!inner(*)', { count: 'exact', head: true })
          .eq('courses.semester_id', currentSemester.id)
          .eq('is_deleted', false)
      ]);

      const statistics = {
        totalCourses: coursesResult.count || 0,
        totalGroups: groupsResult.count || 0,
        totalStudents: studentsResult.count || 0,
        totalAssignments: assignmentsResult.count || 0,
        totalQuizzes: quizzesResult.count || 0,
        totalAnnouncements: announcementsResult.count || 0
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
            recentSubmissions: [],
            studyProgress: {
              assignments: {
                total: 0,
                completed: 0,
                pending: 0
              },
              quizzes: {
                total: 0,
                completed: 0,
                pending: 0
              }
            }
          })
        );
      }

      // Get student's enrolled courses for current semester
      console.log('🔍 [DashboardController] Fetching enrollments for:', {
        userId,
        semesterId: currentSemester.id,
        semesterName: currentSemester.name
      });

      const { data: enrollments, error: enrollmentsError } = await supabase
        .from('student_enrollments')
        .select(`
          id,
          is_active,
          groups!inner(
            id,
            name,
            course_id,
            is_active,
            created_at,
            updated_at,
          courses!inner(
              id,
              code,
              name,
              session_count,
              is_active,
              semester_id,
              created_at,
              updated_at,
              semesters!inner(
                id,
                code,
                name,
                is_active,
                created_at,
                updated_at
              )
            )
          )
        `)
        .eq('student_id', userId)
        .eq('semester_id', currentSemester.id)
        .eq('is_active', true);

      console.log('📊 [DashboardController] Enrollments query result:', {
        count: enrollments?.length || 0,
        hasError: !!enrollmentsError,
        error: enrollmentsError
      });

      if (enrollmentsError) {
        console.error('❌ Error fetching enrollments:', enrollmentsError);
      }

      if (enrollments && enrollments.length > 0) {
        console.log('✅ First enrollment sample:', JSON.stringify(enrollments[0], null, 2));
      }

      // Transform enrollments to match expected format
      const enrolledCourses = (enrollments || []).map(enrollment => ({
        enrollmentId: enrollment.id,
        group: {
          id: enrollment.groups.id,
          name: enrollment.groups.name,
          courseId: enrollment.groups.course_id,
          isActive: enrollment.groups.is_active,
          createdAt: enrollment.groups.created_at,
          updatedAt: enrollment.groups.updated_at
        },
        course: {
          id: enrollment.groups.courses.id,
          code: enrollment.groups.courses.code,
          name: enrollment.groups.courses.name,
          sessionCount: enrollment.groups.courses.session_count,
          isActive: enrollment.groups.courses.is_active,
          semesterId: enrollment.groups.courses.semester_id,
          createdAt: enrollment.groups.courses.created_at,
          updatedAt: enrollment.groups.courses.updated_at,
          semester: {
            id: enrollment.groups.courses.semesters.id,
            code: enrollment.groups.courses.semesters.code,
            name: enrollment.groups.courses.semesters.name,
            isActive: enrollment.groups.courses.semesters.is_active,
            createdAt: enrollment.groups.courses.semesters.created_at,
            updatedAt: enrollment.groups.courses.semesters.updated_at
          }
        }
      }));

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

      // Get group IDs from enrollments
      const groupIds = enrolledCourses.map(ec => ec.group.id);

      let totalAssignments = 0;
      let totalQuizzes = 0;
      let allAssignments = [];
      let allQuizzes = [];

      if (groupIds.length > 0) {
        // Get all assignments assigned to student's groups
        const assignmentsResult = await supabase
          .from('assignments')
          .select(`
            id,
            courses!inner(
              semester_id
            ),
            assignment_groups!inner(
              group_id
            )
          `, { count: 'exact' })
          .eq('courses.semester_id', currentSemester.id)
          .in('assignment_groups.group_id', groupIds);

        allAssignments = assignmentsResult.data || [];
        totalAssignments = assignmentsResult.count || 0;

        // Get all quizzes assigned to student's groups
        const quizzesResult = await supabase
          .from('quizzes')
          .select(`
            id,
            courses!inner(
              semester_id
            ),
            quiz_groups!inner(
              group_id
            )
          `, { count: 'exact' })
          .eq('courses.semester_id', currentSemester.id)
          .in('quiz_groups.group_id', groupIds);

        allQuizzes = quizzesResult.data || [];
        totalQuizzes = quizzesResult.count || 0;
      }

      // Get completed assignments (submissions)
      const { data: completedAssignmentsData } = await supabase
        .from('assignment_submissions')
        .select('assignment_id')
        .eq('student_id', userId)
        .not('submitted_at', 'is', null);

      // Get completed quizzes (submissions)
      const { data: completedQuizzesData } = await supabase
        .from('quiz_submissions')
        .select('quiz_id')
        .eq('student_id', userId)
        .not('submitted_at', 'is', null);

      // Calculate unique completed assignments and quizzes
      const uniqueCompletedAssignmentIds = new Set(
        (completedAssignmentsData || []).map(s => s.assignment_id)
      );
      const uniqueCompletedQuizIds = new Set(
        (completedQuizzesData || []).map(s => s.quiz_id)
      );

      // Filter to only count assignments/quizzes that are assigned to student's groups
      const assignedAssignmentIds = new Set((allAssignments || []).map(a => a.id));
      const assignedQuizIds = new Set((allQuizzes || []).map(q => q.id));

      const completedAssignments = Array.from(uniqueCompletedAssignmentIds)
        .filter(id => assignedAssignmentIds.has(id)).length;
      const completedQuizzes = Array.from(uniqueCompletedQuizIds)
        .filter(id => assignedQuizIds.has(id)).length;

      res.json(
        buildResponse(true, undefined, {
          currentSemester,
          enrolledCourses,
          upcomingAssignments: upcomingAssignments || [],
          recentSubmissions: recentSubmissions || [],
          studyProgress: {
            assignments: {
              total: totalAssignments,
              completed: completedAssignments,
              pending: Math.max(0, totalAssignments - completedAssignments)
            },
            quizzes: {
              total: totalQuizzes,
              completed: completedQuizzes,
              pending: Math.max(0, totalQuizzes - completedQuizzes)
            }
          }
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