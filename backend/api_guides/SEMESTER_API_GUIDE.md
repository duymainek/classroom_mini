## Semester API – Swagger-like Guide

Envelope: `{ success, message?, data }` with camelCase fields.

Models: see `backend/src/types/semester.type.js` (e.g., `Semester`).

### POST /api/semesters
Body: { code, name }
Response 201: `{ success, message, data: { semester: /* JSDoc: Semester */ } }`

### GET /api/semesters
Query: page, limit, search, status, sortBy, sortOrder
Response 200: `{ success, data: { semesters: /* JSDoc: Semester[] */, pagination } }`

### GET /api/semesters/:semesterId
Response 200: `{ success, data: { semester: /* JSDoc: Semester */ } }`

### PATCH /api/semesters/:semesterId
Response 200: `{ success, message, data: { semester: /* JSDoc: Semester */ } }`

### DELETE /api/semesters/:semesterId
Response 200: `{ success, message }`

### GET /api/semesters/statistics
Response 200: `{ success, data: { totalSemesters, activeSemesters, inactiveSemesters } }`


