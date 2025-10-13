## Course API – Swagger-like Guide

Response envelope: `{ success, message?, data }` with camelCase fields.

Models: use JSDoc typedefs in `backend/src/types/course.type.js` (e.g., `CourseSummary`). Example comments below reference these typedef names explicitly.

### POST /api/courses
Body: { code, name, sessionCount, semesterId }
Response 201: `{ success, message, data: { course: /* JSDoc: CourseSummary */ } }`

### GET /api/courses
Query: page, limit, search, status, semesterId, sortBy, sortOrder
Response 200: `{ success, data: { courses: /* JSDoc: CourseSummary[] */, pagination } }`

### GET /api/courses/:courseId
Response 200: `{ success, data: { course: /* JSDoc: CourseSummary */ } }`

### PATCH /api/courses/:courseId
Response 200: `{ success, message, data: { course: /* JSDoc: CourseSummary */ } }`

### DELETE /api/courses/:courseId
Response 200: `{ success, message }`

### GET /api/semesters/:semesterId/courses
Response 200: `{ success, data: { courses: /* JSDoc: CourseSummary[] */, pagination } }`

### GET /api/courses/statistics
Response 200: `{ success, data: { totalCourses, activeCourses, inactiveCourses } }`



