## Dashboard API – Swagger-like Guide

Envelope: `{ success, message?, data }` with camelCase fields.

Models: see `backend/src/types/dashboard.type.js` (e.g., `DashboardStatistics`, `ActivityLog`).

### GET /api/dashboard/instructor
Response 200: `{ success, data: { currentSemester, statistics: /* JSDoc: DashboardStatistics */, recentActivity: /* JSDoc: ActivityLog[] */ } }`

### GET /api/dashboard/student
Response 200: `{ success, data: { currentSemester, enrolledCourses, upcomingAssignments, recentSubmissions } }`

### GET /api/dashboard/semester
Response 200: `{ success, data: { currentSemester } }`

### PATCH /api/dashboard/semester/:semesterId
Response 200: `{ success, message, data: { semester } }`



