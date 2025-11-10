const express = require('express');
const studentController = require('../controllers/studentController');
const dashboardController = require('../controllers/dashboardController');
const announcementController = require('../controllers/announcementController');
const submissionController = require('../controllers/submissionController');
const submissionFileController = require('../controllers/submissionFileController');
const { authenticateToken } = require('../middleware/auth');

const router = express.Router();

router.use(authenticateToken);

// Student profile and courses
router.get('/enrolled-courses', studentController.getEnrolledCourses);
router.get('/dashboard', dashboardController.getStudentDashboard);
router.get('/announcements', announcementController.getStudentAnnouncements);
router.get('/courses', studentController.getStudentCourses);

// Assignment submissions
router.post('/assignments/:assignmentId/submit', submissionController.submitAssignment);
router.get('/assignments/:assignmentId/submissions', submissionController.getStudentSubmissions);
router.get('/submissions', submissionController.getStudentAllSubmissions);
router.put('/submissions/:submissionId', submissionController.updateSubmission);
router.delete('/submissions/:submissionId', submissionController.deleteSubmission);

// Submission file uploads
router.post('/submissions/upload', submissionFileController.uploadTempFile);
router.post('/submissions/:submissionId/finalize', submissionFileController.finalizeTempAttachments);

module.exports = router;

