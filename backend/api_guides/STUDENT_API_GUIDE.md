## Student API – Swagger-like Guide

Envelope: `{ success, message?, data }` with camelCase fields.

Models: see `backend/src/types/student.type.js` (e.g., `StudentSummary`).

### POST /api/students
Create single student
Response 201: `{ success, message, data: { user: /* JSDoc: StudentSummary */, groupId, courseId } }`

### GET /api/students
Query: page, limit, search, status, sortBy, sortOrder
Response 200: `{ success, data: { students: /* JSDoc: StudentSummary[] */, pagination } }`

### PATCH /api/students/:studentId
Body: { email?, fullName?, isActive?, groupId?, courseId? }
Response 200: `{ success, message, data: { student: /* JSDoc: StudentSummary */, groupId?, courseId } }`

### DELETE /api/students/:studentId
Response 200: `{ success, message }`

### POST /api/students/bulk
Body: { studentIds: string[], action: 'activate'|'deactivate'|'delete' }
Response 200: `{ success, message }`

### GET /api/students/statistics
Response 200: `{ success, data: { totalStudents, activeStudents, inactiveStudents, studentsLoggedInLast7Days, studentsNeverLoggedIn } }`

### POST /api/students/:studentId/reset-password
Body: { newPassword }
Response 200: `{ success, message }`

### POST /api/students/export
Query: format=csv
Response 200: CSV download

### POST /api/students/import/preview
Body: { records: Array<{ fullName, email, username, initialPassword? }> }
Response 200: `{ success, summary, results }`

### POST /api/students/import
Body: { records: [...], globalCourseId?, globalGroupId?, assignments? }
Response 200: `{ success, summary, results }`



