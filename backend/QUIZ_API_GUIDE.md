# Quiz API Documentation

## Overview
Quiz API cho phép giảng viên tạo và quản lý quiz, sinh viên làm bài và nộp đáp án. Hệ thống hỗ trợ 3 loại câu hỏi: trắc nghiệm, đúng/sai, và tự luận.

## Database Schema

### Tables Created
- `quizzes` - Bảng chính chứa thông tin quiz
- `quiz_questions` - Bảng câu hỏi trong quiz
- `quiz_question_options` - Bảng lựa chọn cho câu hỏi trắc nghiệm
- `quiz_groups` - Liên kết quiz với nhóm sinh viên
- `quiz_submissions` - Bảng nộp bài quiz
- `quiz_answers` - Bảng câu trả lời của sinh viên

## API Endpoints

### 1. Quiz Management (Instructor only)

#### Create Quiz
```http
POST /api/quizzes
Authorization: Bearer <instructor_token>
Content-Type: application/json

{
  "title": "JavaScript Basics Quiz",
  "description": "Test your JavaScript knowledge",
  "courseId": "uuid",
  "startDate": "2024-01-01T00:00:00.000Z",
  "dueDate": "2024-01-02T23:59:59.000Z",
  "lateDueDate": "2024-01-03T23:59:59.000Z",
  "allowLateSubmission": true,
  "maxAttempts": 3,
  "timeLimit": 30,
  "shuffleQuestions": false,
  "shuffleOptions": false,
  "showCorrectAnswers": true,
  "groupIds": ["uuid1", "uuid2"]
}
```

#### Get Quizzes
```http
GET /api/quizzes?page=1&limit=20&search=&courseId=&semesterId=&status=all&sortBy=created_at&sortOrder=desc
Authorization: Bearer <token>
```

#### Get Quiz by ID
```http
GET /api/quizzes/:quizId
Authorization: Bearer <token>
```

#### Update Quiz
```http
PUT /api/quizzes/:quizId
Authorization: Bearer <instructor_token>
Content-Type: application/json

{
  "title": "Updated Quiz Title",
  "description": "Updated description",
  "timeLimit": 45
}
```

#### Delete Quiz
```http
DELETE /api/quizzes/:quizId
Authorization: Bearer <instructor_token>
```

### 2. Question Management (Instructor only)

#### Add Question
```http
POST /api/quizzes/:quizId/questions
Authorization: Bearer <instructor_token>
Content-Type: application/json

{
  "questionText": "What is the correct way to declare a variable?",
  "questionType": "multiple_choice",
  "points": 2,
  "orderIndex": 1,
  "isRequired": true,
  "options": [
    {"optionText": "var myVar = 5;", "isCorrect": true, "orderIndex": 1},
    {"optionText": "variable myVar = 5;", "isCorrect": false, "orderIndex": 2},
    {"optionText": "v myVar = 5;", "isCorrect": false, "orderIndex": 3}
  ]
}
```

#### Update Question
```http
PUT /api/quizzes/:quizId/questions/:questionId
Authorization: Bearer <instructor_token>
Content-Type: application/json

{
  "questionText": "Updated question text",
  "points": 3,
  "options": [
    {"optionText": "New option 1", "isCorrect": true, "orderIndex": 1},
    {"optionText": "New option 2", "isCorrect": false, "orderIndex": 2}
  ]
}
```

#### Delete Question
```http
DELETE /api/quizzes/:quizId/questions/:questionId
Authorization: Bearer <instructor_token>
```

### 3. Quiz Submission (Students)

#### Submit Quiz
```http
POST /api/quizzes/:quizId/submit
Authorization: Bearer <student_token>
Content-Type: application/json

{
  "answers": [
    {
      "questionId": "uuid",
      "selectedOptionId": "uuid"  // For multiple choice/true-false
    },
    {
      "questionId": "uuid",
      "answerText": "Essay answer text"  // For essay questions
    }
  ]
}
```

### 4. Quiz Tracking & Grading (Instructor only)

#### Get Quiz Submissions
```http
GET /api/quizzes/:quizId/submissions?page=1&limit=20&search=&status=all&sortBy=submitted_at&sortOrder=desc
Authorization: Bearer <instructor_token>
```

#### Grade Submission
```http
PUT /api/quizzes/submissions/:submissionId/grade
Authorization: Bearer <instructor_token>
Content-Type: application/json

{
  "grade": 85,
  "feedback": "Good work! You got most questions correct."
}
```

## Question Types

### 1. Multiple Choice (`multiple_choice`)
- Có nhiều lựa chọn, chỉ một đáp án đúng
- Cần có ít nhất 2 options
- Sinh viên chọn bằng `selectedOptionId`

### 2. True/False (`true_false`)
- Có 2 lựa chọn: True/False
- Sinh viên chọn bằng `selectedOptionId`

### 3. Essay (`essay`)
- Câu hỏi tự luận
- Sinh viên trả lời bằng `answerText`
- Cần giảng viên chấm điểm thủ công

## Response Formats

### Quiz Response
```json
{
  "success": true,
  "data": {
    "quiz": {
      "id": "uuid",
      "title": "Quiz Title",
      "description": "Quiz description",
      "courseId": "uuid",
      "instructorId": "uuid",
      "startDate": "2024-01-01T00:00:00.000Z",
      "dueDate": "2024-01-02T23:59:59.000Z",
      "lateDueDate": "2024-01-03T23:59:59.000Z",
      "allowLateSubmission": true,
      "maxAttempts": 3,
      "timeLimit": 30,
      "shuffleQuestions": false,
      "shuffleOptions": false,
      "showCorrectAnswers": true,
      "isActive": true,
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-01-01T00:00:00.000Z",
      "course": {
        "code": "CS101",
        "name": "Computer Science"
      },
      "instructor": {
        "fullName": "John Doe"
      },
      "quiz_groups": [
        {
          "groups": {
            "id": "uuid",
            "name": "Group A"
          }
        }
      ],
      "quiz_questions": [
        {
          "id": "uuid",
          "questionText": "Question text",
          "questionType": "multiple_choice",
          "points": 2,
          "orderIndex": 1,
          "isRequired": true,
          "quiz_question_options": [
            {
              "id": "uuid",
              "optionText": "Option 1",
              "isCorrect": true,
              "orderIndex": 1
            }
          ]
        }
      ]
    }
  }
}
```

### Submission Response
```json
{
  "success": true,
  "data": {
    "submissionId": "uuid",
    "attemptNumber": 1,
    "isLate": false,
    "status": "on_time"
  }
}
```

## Error Handling

### Common Error Codes
- `QUIZ_NOT_FOUND` - Quiz không tồn tại hoặc không có quyền truy cập
- `QUESTION_NOT_FOUND` - Câu hỏi không tồn tại
- `SUBMISSION_NOT_FOUND` - Bài nộp không tồn tại
- `QUIZ_CLOSED` - Quiz đã hết hạn
- `MAX_ATTEMPTS_EXCEEDED` - Vượt quá số lần làm bài cho phép
- `VALIDATION_FAILED` - Dữ liệu đầu vào không hợp lệ

### Error Response Format
```json
{
  "success": false,
  "message": "Error description",
  "code": "ERROR_CODE",
  "errors": [
    {
      "field": "fieldName",
      "message": "Field-specific error message"
    }
  ]
}
```

## Testing

### Run Test Script
```bash
./test-quiz-api.sh
```

Script này sẽ test toàn bộ flow:
1. Tạo quiz với 3 loại câu hỏi
2. Sinh viên làm bài và nộp đáp án
3. Giảng viên chấm điểm
4. Xem kết quả

## Security Features

1. **Authentication**: Tất cả endpoints yêu cầu JWT token
2. **Authorization**: Phân quyền rõ ràng giữa instructor và student
3. **Validation**: Kiểm tra dữ liệu đầu vào nghiêm ngặt
4. **Time Limits**: Giới hạn thời gian làm bài
5. **Attempt Limits**: Giới hạn số lần làm bài
6. **Late Submission**: Kiểm soát nộp bài muộn

## Performance Considerations

1. **Indexing**: Database đã được index cho các truy vấn thường dùng
2. **Pagination**: Tất cả list endpoints đều có pagination
3. **Caching**: Có thể implement caching cho quiz details
4. **Batch Operations**: Hỗ trợ tạo nhiều câu hỏi cùng lúc

## Future Enhancements

1. **Auto-grading**: Tự động chấm điểm cho câu hỏi trắc nghiệm
2. **Question Bank**: Thư viện câu hỏi có thể tái sử dụng
3. **Analytics**: Thống kê chi tiết về kết quả quiz
4. **Time Tracking**: Theo dõi thời gian làm bài chi tiết
5. **Question Randomization**: Xáo trộn câu hỏi và đáp án
6. **Proctoring**: Tính năng giám sát khi làm bài
