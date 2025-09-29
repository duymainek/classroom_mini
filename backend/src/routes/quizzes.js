const express = require('express');
const router = express.Router();
const quizController = require('../controllers/quizController');
const { authenticateToken, requireInstructor, requireAuthenticated } = require('../middleware/auth');

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

// Quiz tracking and grading (Instructor only)
router.get('/:quizId/submissions', authenticateToken, requireInstructor, quizController.getQuizSubmissions);
router.put('/submissions/:submissionId/grade', authenticateToken, requireInstructor, quizController.gradeQuizSubmission);

module.exports = router;
