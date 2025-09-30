/**
 * Quiz model and validation
 */

const Joi = require('joi');

/**
 * Calculate quiz submission status
 * @param {Date} submittedAt - Submission timestamp
 * @param {Date} dueDate - Quiz due date
 * @param {Date} lateDueDate - Late submission due date
 * @param {boolean} allowLateSubmission - Whether late submission is allowed
 * @returns {string} - Status: 'on_time', 'late', 'too_late'
 */
function calculateQuizSubmissionStatus(submittedAt, dueDate, lateDueDate, allowLateSubmission) {
  const submitted = new Date(submittedAt);
  const due = new Date(dueDate);
  
  if (submitted <= due) {
    return 'on_time';
  }
  
  if (allowLateSubmission && lateDueDate) {
    const lateDue = new Date(lateDueDate);
    if (submitted <= lateDue) {
      return 'late';
    }
  }
  
  return 'too_late';
}

/**
 * Format quiz data for response
 * @param {Object} quiz - Quiz data from database
 * @returns {Object} - Formatted quiz data
 */
function formatQuizResponse(quiz) {
  return {
    id: quiz.id,
    title: quiz.title,
    description: quiz.description,
    courseId: quiz.course_id,
    instructorId: quiz.instructor_id,
    startDate: quiz.start_date,
    dueDate: quiz.due_date,
    lateDueDate: quiz.late_due_date,
    allowLateSubmission: quiz.allow_late_submission,
    maxAttempts: quiz.max_attempts,
    timeLimit: quiz.time_limit,
    shuffleQuestions: quiz.shuffle_questions,
    shuffleOptions: quiz.shuffle_options,
    showCorrectAnswers: quiz.show_correct_answers,
    isActive: quiz.is_active,
    createdAt: quiz.created_at,
    updatedAt: quiz.updated_at,
    course: quiz.courses,
    instructor: quiz.users
  };
}

/**
 * Format question data for response
 * @param {Object} question - Question data from database
 * @returns {Object} - Formatted question data
 */
function formatQuestionResponse(question) {
  return {
    id: question.id,
    quizId: question.quiz_id,
    questionText: question.question_text,
    questionType: question.question_type,
    points: question.points,
    orderIndex: question.order_index,
    isRequired: question.is_required,
    createdAt: question.created_at,
    updatedAt: question.updated_at,
    options: question.options || []
  };
}

/**
 * Format quiz submission data for response
 * @param {Object} submission - Submission data from database
 * @returns {Object} - Formatted submission data
 */
function formatQuizSubmissionResponse(submission) {
  return {
    id: submission.id,
    quizId: submission.quiz_id,
    studentId: submission.student_id,
    attemptNumber: submission.attempt_number,
    startedAt: submission.started_at,
    submittedAt: submission.submitted_at,
    timeSpent: submission.time_spent,
    totalScore: submission.total_score,
    maxScore: submission.max_score,
    isLate: submission.is_late,
    isGraded: submission.is_graded,
    grade: submission.grade,
    feedback: submission.feedback,
    gradedAt: submission.graded_at,
    gradedBy: submission.graded_by,
    createdAt: submission.created_at,
    updatedAt: submission.updated_at,
    student: submission.users,
    answers: submission.answers || []
  };
}

module.exports = {
  calculateQuizSubmissionStatus
};
