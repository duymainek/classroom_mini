const express = require('express');
const router = express.Router();
const quizController = require('../controllers/quizController');
const { authenticateToken, requireInstructor, requireAuthenticated, requireStudent } = require('../middleware/auth');

// Quiz CRUD routes (Instructor only)
router.post('/', authenticateToken, requireInstructor, quizController.createQuiz);
router.get('/', authenticateToken, requireAuthenticated, quizController.getQuizzes);
router.get('/:quizId', authenticateToken, requireAuthenticated, quizController.getQuizById);
router.put('/:quizId', authenticateToken, requireInstructor, quizController.updateQuiz);
router.delete('/:quizId', authenticateToken, requireInstructor, quizController.deleteQuiz);

// Question management routes (Instructor only)
router.post('/:quizId/questions', authenticateToken, requireInstructor, quizController.addQuestion);
router.put('/:quizId/questions/:questionId', authenticateToken, requireInstructor, quizController.updateQuestion);
router.delete('/:quizId/questions/:questionId', authenticateToken, requireInstructor, quizController.deleteQuestion);

// Quiz submission routes
router.post('/:quizId/submit', authenticateToken, quizController.submitQuiz);
router.get('/:quizId/my-submissions', authenticateToken, requireStudent, quizController.getStudentQuizSubmissions);

// Quiz tracking and grading
router.get('/submissions/:submissionId', authenticateToken, requireAuthenticated, quizController.getQuizSubmissionById);
router.put('/submissions/:submissionId/grade', authenticateToken, requireInstructor, quizController.gradeQuizSubmission);
router.get('/:quizId/submissions', authenticateToken, requireInstructor, quizController.getQuizSubmissions);

// Essay review endpoints (Instructor only)
router.put('/submissions/:submissionId/answers/:answerId/review', authenticateToken, requireInstructor, quizController.reviewEssayAnswer);
router.post('/submissions/:submissionId/complete-grading', authenticateToken, requireInstructor, quizController.completeGrading);

module.exports = router;
