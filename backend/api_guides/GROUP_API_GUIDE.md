## Group API – Swagger-like Guide

Envelope: `{ success, message?, data }`, camelCase.

Models: see `backend/src/types/group.type.js` (e.g., `GroupSummary`). Comments below reference these JSDoc typedefs.

### POST /api/groups
Body: { name, courseId }
Response 201: `{ success, message, data: { group: /* JSDoc: GroupSummary */ } }`

### GET /api/groups
Query: page, limit, search, status, courseId, sortBy, sortOrder
Response 200: `{ success, data: { groups: /* JSDoc: GroupSummary[] */, pagination } }`

### GET /api/groups/:groupId
Response 200: `{ success, data: { group: /* JSDoc: GroupSummary */ } }`

### PATCH /api/groups/:groupId
Response 200: `{ success, message, data: { group: /* JSDoc: GroupSummary */ } }`

### DELETE /api/groups/:groupId
Response 200: `{ success, message }`

### GET /api/courses/:courseId/groups
Response 200: `{ success, data: { groups: /* JSDoc: GroupSummary[] */, pagination } }`

### GET /api/groups/statistics
Response 200: `{ success, data: { totalGroups, activeGroups, inactiveGroups } }`



