# 📋 Plan Implementation: Essay Question Review Feature

## 🎯 Mục tiêu
Implement chức năng review và grading cho các câu hỏi essay trong quiz submission.

## ✅ Database Migration (Đã hoàn thành)
- ✅ Thêm cột `review_status` (pending/approved/rejected) vào bảng `quiz_answers`
- ✅ Thêm cột `manual_score` (NUMERIC) vào bảng `quiz_answers`
- ✅ Set default `review_status = 'pending'` cho các essay answers hiện có

## 📝 Backend Implementation

### 1. API Endpoint: Review Essay Answer
**Endpoint**: `PUT /quizzes/submissions/{submissionId}/answers/{answerId}/review`

**Request Body**:
```json
{
  "action": "approve" | "reject",
  "manualScore": 1.0 | 0.0  // Optional, default: 1.0 for approve, 0.0 for reject
}
```

**Logic**:
- Verify instructor has access to the submission
- Verify answer belongs to essay question
- Update `review_status` và `manual_score` trong `quiz_answers`
- Recalculate `total_score` của submission (sum all scores including manual_score)
- Update `points_earned` = `manual_score`
- Update `is_correct` = true nếu approved, false nếu rejected

### 2. API Endpoint: Complete Grading
**Endpoint**: `POST /quizzes/submissions/{submissionId}/complete-grading`

**Request Body**: (empty)

**Logic**:
- Verify instructor has access
- Check tất cả essay answers đã được review (không còn pending)
- Set `is_graded = true` trong `quiz_submissions`
- Set `graded_at` và `graded_by`

### 3. Update getQuizSubmissionById
- Include `review_status` và `manual_score` trong response
- Map `manual_score` vào `score` field nếu có

## 🎨 Frontend Implementation

### 1. Update Models
**File**: `lib/app/data/models/response/quiz_response.dart`
- Thêm `reviewStatus` (String?) vào `QuizAnswerDetail`
- Thêm `manualScore` (double?) vào `QuizAnswerDetail`

### 2. Update API Service
**File**: `lib/app/data/services/quiz_api_service.dart`
- Thêm method `reviewAnswer(String submissionId, String answerId, String action, double? manualScore)`
- Thêm method `completeGrading(String submissionId)`

### 3. Update Controller
**File**: `lib/app/modules/quiz/controllers/quiz_controller.dart`
- Thêm method `reviewAnswer(String submissionId, String answerId, String action)`
- Thêm method `completeGrading(String submissionId)`
- Reload submission detail sau khi review/complete

### 4. Update View
**File**: `lib/app/modules/quiz/views/mobile/quiz_submission_detail_view.dart`

**Changes**:
- Hiển thị Approve/Reject buttons cho essay questions có `reviewStatus == 'pending'`
- Hiển thị review status badge (Pending/Approved/Rejected)
- Hiển thị button "Complete Grading" khi:
  - Có ít nhất 1 essay question
  - Tất cả essay questions đã được review (không còn pending)
  - `isGraded == false`
- Disable "Complete Grading" button nếu còn essay questions pending

**UI Components**:
- Approve button: Green, icon check_circle
- Reject button: Red, icon cancel
- Review status badge: Color theo status
- Complete Grading button: Primary color, ở cuối questions section

## 🔄 Flow Logic

### Review Flow:
1. Instructor mở submission detail
2. Thấy essay questions với status "Pending Review"
3. Click Approve → `review_status = 'approved'`, `manual_score = 1.0`, `points_earned = 1.0`
4. Click Reject → `review_status = 'rejected'`, `manual_score = 0.0`, `points_earned = 0.0`
5. Total score được recalculate tự động
6. Button "Complete Grading" enable khi tất cả essay đã được review

### Complete Grading Flow:
1. Instructor review tất cả essay questions
2. Click "Complete Grading"
3. Backend verify và set `is_graded = true`
4. UI update để hiển thị submission đã được graded

## 📊 Scoring Logic

- **Approve**: `manual_score = 1.0`, `points_earned = 1.0`, `is_correct = true`
- **Reject**: `manual_score = 0.0`, `points_earned = 0.0`, `is_correct = false`
- **Total Score**: Sum của tất cả `points_earned` từ tất cả answers (auto-graded + manual)

## 🧪 Test Cases

1. ✅ Approve essay answer → score = 1.0, status = approved
2. ✅ Reject essay answer → score = 0.0, status = rejected
3. ✅ Complete grading khi tất cả essay đã review → is_graded = true
4. ✅ Complete grading khi còn pending → Error
5. ✅ Total score được tính đúng sau mỗi review
6. ✅ UI hiển thị đúng status và buttons

## 📌 Notes

- Review status chỉ áp dụng cho essay questions
- Multiple choice và true/false vẫn auto-grade như cũ
- Manual score có thể override nếu cần (future enhancement)
- Complete grading chỉ set is_graded = true, không tự động review pending answers

