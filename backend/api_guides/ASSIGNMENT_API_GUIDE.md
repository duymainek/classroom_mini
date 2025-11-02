## Assignment API – Swagger-like Guide

This guide documents the Assignment-related endpoints with example requests and responses. All responses are camelCase and follow the standard shape:

```json
{
  "success": true,
  "message": "optional",
  "data": { ... },
  "meta": { ... }
}
```

### Models
Types are defined in `backend/src/types/assignment.type.js` and referenced below using their JSDoc typedef names. Treat object shapes in examples as instances of these typedefs.

```json
// JSDoc typedef: `AssignmentAttachment`
{
  "id": "string",
  "fileName": "string",
  "fileUrl": "string",
  "fileSize": 123,
  "fileType": "string",
  "createdAt": "ISO-8601"
}

// JSDoc typedef: `AssignmentSummary`
{
  "id": "string",
  "title": "string",
  "description": "string",
  "courseId": "string",
  "instructorId": "string",
  "startDate": "ISO-8601",
  "dueDate": "ISO-8601",
  "lateDueDate": "ISO-8601",
  "allowLateSubmission": true,
  "maxAttempts": 1,
  "fileFormats": ["pdf", "docx"],
  "maxFileSize": 10,
  "isActive": true,
  "createdAt": "ISO-8601",
  "updatedAt": "ISO-8601",
  "courses": { "code": "CS101", "name": "Intro" }
}

// JSDoc typedef: `AssignmentDetail` (extends AssignmentSummary)
{
  "id": "string",
  "title": "string",
  "description": "string",
  "courseId": "string",
  "instructorId": "string",
  "startDate": "ISO-8601",
  "dueDate": "ISO-8601",
  "lateDueDate": "ISO-8601",
  "allowLateSubmission": true,
  "maxAttempts": 1,
  "fileFormats": ["pdf", "docx"],
  "maxFileSize": 10,
  "isActive": true,
  "createdAt": "ISO-8601",
  "updatedAt": "ISO-8601",
  "courses": { "code": "CS101", "name": "Intro" },
  "assignmentAttachments": [AssignmentAttachment],
  "assignmentGroups": [ { "groups": { "id": "string", "name": "string" } } ]
}
```

---

### POST /api/assignments
Create a new assignment.

- Body: create schema as per backend validation (title, description, courseId, startDate, dueDate, lateDueDate, allowLateSubmission, maxAttempts, fileFormats, maxFileSize, groupIds, attachments[])

- Success 201
```json
{
  "success": true,
  "message": "Assignment created successfully",
  "data": {
    "assignment": { /* JSDoc: AssignmentDetail */ }
  }
}
```

---

### GET /api/assignments
List assignments with pagination and filters.

- Query: page, limit, search, courseId, semesterId, status, sortBy, sortOrder
- Success 200
```json
{
  "success": true,
  "data": {
    "assignments": [ /* JSDoc: AssignmentSummary[] */ ],
    "pagination": { "page": 1, "limit": 20, "total": 100, "pages": 5 }
  }
}
```

---

### GET /api/assignments/:assignmentId
Get assignment detail by id.

- Success 200
```json
{
  "success": true,
  "data": {
    "assignment": { /* JSDoc: AssignmentDetail */ }
  }
}
```

---

### PATCH /api/assignments/:assignmentId
Update an assignment and attachments.

- Body: partial update fields and optional attachments[] (replaces existing)
- Success 200
```json
{
  "success": true,
  "message": "Assignment updated successfully",
  "data": {
    "assignment": { /* JSDoc: AssignmentDetail */ }
  }
}
```

---

### DELETE /api/assignments/:assignmentId
Delete an assignment without submissions.

- Success 200
```json
{
  "success": true,
  "message": "Assignment deleted successfully"
}
```

---

### GET /api/assignments/:assignmentId/submissions
List submissions with tracking and pagination.

- Query: page, limit, search, status, sortBy, sortOrder
- Success 200
```json
{
  "success": true,
  "data": {
    "submissions": [
      {
        "studentId": "string",
        "username": "string",
        "fullName": "string",
        "email": "string",
        "totalSubmissions": 2,
        "latestSubmission": {
          "id": "string",
          "attemptNumber": 1,
          "submittedAt": "ISO-8601",
          "isLate": false,
          "grade": 95,
          "feedback": "string",
          "gradedAt": "ISO-8601"
        },
        "status": "submitted|late|not_submitted"
      }
    ],
    "pagination": { "page": 1, "limit": 20, "total": 10, "pages": 1 }
  }
}
```

---

### PATCH /api/submissions/:submissionId/grade
Grade a submission.

- Body: { grade: number (0-100), feedback: string }
- Success 200
```json
{
  "success": true,
  "message": "Submission graded successfully",
  "data": {
    "submission": {
      "id": "string",
      "grade": 90,
      "feedback": "Good work",
      "gradedAt": "ISO-8601",
      "gradedBy": "instructor-id",
      "users": { "fullName": "Instructor Name" }
    }
  }
}
```

---

### Notes
- All field names are camelCase on responses.
- Pagination object always includes page, limit, total, pages.
- Attachments replace existing on update when provided.

// moved from backend/ASSIGNMENT_API_GUIDE.md


