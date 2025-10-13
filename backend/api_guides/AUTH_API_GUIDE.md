## Auth API – Swagger-like Guide

All responses are camelCase and follow:

```json
{ "success": true, "message": "optional", "data": { ... } }
```

Note on models: Use JSDoc typedefs from `backend/src/types/auth.type.js` and `backend/src/types/student.type.js`. In examples below, comments like `/* AuthUser */` or `/* StudentSummary */` refer to those typedefs.

### POST /api/auth/instructor/login
Body: { username, password }
Response 200:
```json
{ "success": true, "message": "Login successful", "data": { "user": { /* JSDoc: AuthUser */ }, "tokens": { "accessToken": "", "refreshToken": "" } } }
```

### POST /api/auth/student/login
Body: { username, password }
Response 200 same shape as instructor login.

### POST /api/auth/students
Create student (instructor only)
Body: { username, password, email, fullName, groupId?, courseId? }
Response 201:
```json
{ "success": true, "message": "Student account created successfully", "data": { "user": { /* JSDoc: StudentSummary (sanitized) */ }, "groupId": "string|null", "courseId": "string|null" } }
```

### GET /api/auth/me
Response 200: `{ success, data: { user: /* JSDoc: AuthUser */ } }`

### POST /api/auth/refresh
Body: { refreshToken }
Response 200: `{ success, message, data: { tokens } }`

### POST /api/auth/logout
Response 200: `{ success, message }`

### PATCH /api/auth/profile
Body: { email?, avatarUrl? }
Response 200: `{ success, message, data: { user } }`

### GET /api/auth/students
Query: page, limit, search, status, sortBy, sortOrder
Response 200: `{ success, data: { students: /* JSDoc: StudentSummary[] */, pagination } }`

### PATCH /api/auth/students/:studentId/status
Body: { isActive }
Response 200: `{ success, message, data: { student: /* JSDoc: StudentSummary */ } }`



