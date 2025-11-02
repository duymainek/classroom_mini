## Quiz API – Swagger-like Guide

Envelope: `{ success, message?, data }` with camelCase fields.

Models: see `backend/src/types/quiz.type.js` (e.g., `QuizSummary`, `QuizQuestion`, `QuizOption`). Example comments below reference these JSDoc typedefs.

### POST /api/quizzes
Body: create quiz fields
Response 201: `{ success, message, data: { quiz: /* JSDoc: QuizSummary (with relations) */ } }`

### GET /api/quizzes
Query: page, limit, search, courseId, semesterId, status, sortBy, sortOrder
Response 200: `{ success, data: { quizzes: /* JSDoc: QuizSummary[] */ with questionCount, pagination } }`

### GET /api/quizzes/:quizId
Response 200: `{ success, data: { quiz: /* JSDoc: QuizSummary with questions: QuizQuestion[] */ } }`

### PATCH /api/quizzes/:quizId
Body: partial update, optional `questions` array to sync
Response 200: `{ success, message, data: { quiz: /* JSDoc: QuizSummary */ } }`

### DELETE /api/quizzes/:quizId
Response 200: `{ success, message }`

### POST /api/quizzes/:quizId/questions
Response 201: `{ success, message, data: { question: /* JSDoc: QuizQuestion */ } }`

### PATCH /api/quizzes/:quizId/questions/:questionId
Response 200: `{ success, message, data: { question: /* JSDoc: QuizQuestion */ } }`

### DELETE /api/quizzes/:quizId/questions/:questionId
Response 200: `{ success, message }`

### POST /api/quizzes/:quizId/submissions
Response 201: `{ success, message, data: { submissionId, attemptNumber, isLate, status } }`

### GET /api/quizzes/:quizId/submissions
Response 200: `{ success, data: { submissions, pagination } }`

### PATCH /api/quiz-submissions/:submissionId/grade
Response 200: `{ success, message, data: { submission } }`



