# STUDENT ASSIGNMENT SUBMISSION - IMPLEMENTATION PLAN

## 📋 PHÂN TÍCH DATABASE & EXISTING CODE

### ✅ Database Schema Đã Có (Ready)

**Table: `assignment_submissions`**
- ✅ Support multiple attempts (`attempt_number`)
- ✅ Late submission tracking (`is_late`, `late_due_date`)
- ✅ Grading fields (`grade`, `feedback`, `graded_at`, `graded_by`)
- ✅ Text submission (`submission_text`)
- ✅ Timestamps (`submitted_at`, `created_at`, `updated_at`)

**Table: `submission_attachments`**
- ✅ File metadata (`file_name`, `file_url`, `file_size`, `file_type`)
- ✅ Link to submission (`submission_id`)

**Table: `assignments`**
- ✅ Validation rules (`max_attempts`, `file_formats`, `max_file_size`)
- ✅ Deadline rules (`due_date`, `late_due_date`, `allow_late_submission`)

### 🔄 Reuse Pattern từ Instructor Code

**File Upload Pattern:**
```
1. Upload temp file → temp_attachments table
2. Create submission → assignment_submissions table
3. Finalize attachments → submission_attachments table
4. Delete temp records
```

---

## 🎯 IMPLEMENTATION PLAN

### Phase 1: Backend APIs

#### 1.1 Submission Controller (NEW)

**`controllers/submissionController.js`:**

```javascript
/**
 * Student Submission Controller
 * Handles assignment submissions for students
 */
class SubmissionController {
  
  /**
   * Submit assignment
   * POST /api/student/assignments/:assignmentId/submit
   * Body: { submissionText?, tempAttachmentIds: [] }
   */
  submitAssignment = catchAsync(async (req, res) => {
    /**
     * TODO: Implementation steps
     * 
     * 1. VALIDATION:
     *    - Get assignment details (due_date, late_due_date, allow_late_submission, max_attempts)
     *    - Check student is enrolled in assignment (via assignment_groups → groups → student_enrollments)
     *    - Count current attempts for this student
     *    - If attempts >= max_attempts → Error: "Maximum attempts reached"
     *    - Check if past deadline:
     *      - If past due_date and NOT allow_late_submission → Error: "Deadline passed"
     *      - If past late_due_date → Error: "Late deadline passed"
     *      - If past due_date but before late_due_date → Mark as late (is_late = true)
     *    - Validate file formats from tempAttachmentIds against assignment.file_formats
     *    - Validate file sizes against assignment.max_file_size
     * 
     * 2. CREATE SUBMISSION RECORD:
     *    - Insert into assignment_submissions:
     *      {
     *        assignment_id,
     *        student_id: req.user.id,
     *        attempt_number: currentAttempts + 1,
     *        submission_text,
     *        submitted_at: now,
     *        is_late: (now > due_date && now <= late_due_date)
     *      }
     * 
     * 3. FINALIZE ATTACHMENTS:
     *    - Get temp_attachments by tempAttachmentIds and user_id
     *    - For each temp attachment:
     *      - Move file from temp/submissions/{user_id}/... to submissions/{submission_id}/...
     *      - Insert into submission_attachments with submission_id
     *      - Mark temp_attachment as finalized
     *    - Delete finalized temp_attachments
     * 
     * 4. RESPONSE:
     *    - Return submission with attachments
     *    - Success message: "Assignment submitted successfully"
     *    - If late: "Assignment submitted (late submission)"
     */
  });

  /**
   * Get student's submissions for an assignment
   * GET /api/student/assignments/:assignmentId/submissions
   */
  getMySubmissions = catchAsync(async (req, res) => {
    /**
     * TODO: Implementation
     * 
     * 1. Get all submissions for this student and assignment
     * 2. Include attachments for each submission
     * 3. Order by attempt_number DESC (latest first)
     * 4. Return array of submissions with:
     *    - attempt_number, submitted_at, is_late
     *    - grade, feedback, graded_at (if graded)
     *    - attachments array
     */
  });

  /**
   * Get single submission detail
   * GET /api/student/submissions/:submissionId
   */
  getSubmissionDetail = catchAsync(async (req, res) => {
    /**
     * TODO: Implementation
     * 
     * 1. Verify submission belongs to current student
     * 2. Get submission with attachments
     * 3. Include assignment info (title, description)
     * 4. Return full submission details
     */
  });

  /**
   * Download submission attachment
   * GET /api/student/submissions/:submissionId/attachments/:attachmentId/download
   */
  downloadSubmissionAttachment = catchAsync(async (req, res) => {
    /**
     * TODO: Implementation
     * 
     * 1. Verify submission belongs to current student
     * 2. Get attachment file_path
     * 3. Generate signed URL or stream file
     * 4. Return file download
     */
  });
}
```

#### 1.2 File Upload Controller Updates

**`controllers/submissionFileController.js` (NEW):**

```javascript
/**
 * Submission File Upload Controller
 * Handles file uploads for student submissions
 */
class SubmissionFileController {
  
  /**
   * Upload temporary file for submission
   * POST /api/student/submissions/upload
   */
  uploadTempFile = [
    upload.single('file'),
    catchAsync(async (req, res) => {
      /**
       * TODO: Similar to announcementFileController.uploadTempAttachment
       * 
       * 1. Validate file (type, size)
       * 2. Upload to temp storage: temp/submissions/{user_id}/{timestamp}_{filename}
       * 3. Save to temp_attachments table with attachment_type = 'submission'
       * 4. Return temp attachment ID
       */
    })
  ];

  /**
   * Finalize temp attachments for submission
   * POST /api/student/submissions/:submissionId/finalize
   * Body: { tempAttachmentIds: [] }
   */
  finalizeTempAttachments = catchAsync(async (req, res) => {
    /**
     * TODO: Similar to announcementFileController.finalizeTempAttachments
     * 
     * 1. Get temp_attachments by IDs and verify user ownership
     * 2. For each temp attachment:
     *    - Move from temp/submissions/{user_id}/... to submissions/{submission_id}/...
     *    - Create submission_attachments record
     *    - Mark temp as finalized
     * 3. Delete finalized temp records
     * 4. Return finalized attachments
     */
  });
}
```

#### 1.3 Routes

**`routes/studentRoutes.js` (NEW):**

```javascript
const express = require('express');
const router = express.Router();
const submissionController = require('../controllers/submissionController');
const submissionFileController = require('../controllers/submissionFileController');
const { authenticateToken, requireRole } = require('../middleware/auth');

// All routes require student role
router.use(authenticateToken);
router.use(requireRole(['student']));

// Submission routes
router.post('/assignments/:assignmentId/submit', submissionController.submitAssignment);
router.get('/assignments/:assignmentId/submissions', submissionController.getMySubmissions);
router.get('/submissions/:submissionId', submissionController.getSubmissionDetail);
router.get('/submissions/:submissionId/attachments/:attachmentId/download', submissionController.downloadSubmissionAttachment);

// File upload routes
router.post('/submissions/upload', submissionFileController.uploadTempFile);
router.post('/submissions/:submissionId/finalize', submissionFileController.finalizeTempAttachments);

module.exports = router;
```

---

### Phase 2: Frontend (Flutter)

#### 2.1 Models

**Request Models:**

```dart
// models/request/submit_assignment_request.dart
@JsonSerializable()
class SubmitAssignmentRequest {
  @JsonKey(name: 'submission_text')
  final String? submissionText;
  
  @JsonKey(name: 'temp_attachment_ids')
  final List<String> tempAttachmentIds;

  SubmitAssignmentRequest({
    this.submissionText,
    required this.tempAttachmentIds,
  });
  
  // toJson, fromJson
}
```

**Response Models:**

```dart
// models/response/submission_response.dart
@JsonSerializable()
class SubmissionResponse {
  final String id;
  @JsonKey(name: 'assignment_id')
  final String assignmentId;
  @JsonKey(name: 'student_id')
  final String studentId;
  @JsonKey(name: 'attempt_number')
  final int attemptNumber;
  @JsonKey(name: 'submission_text')
  final String? submissionText;
  @JsonKey(name: 'submitted_at')
  final DateTime submittedAt;
  @JsonKey(name: 'is_late')
  final bool isLate;
  final double? grade;
  final String? feedback;
  @JsonKey(name: 'graded_at')
  final DateTime? gradedAt;
  
  // Attachments
  final List<SubmissionAttachmentResponse>? attachments;
  
  // Status helpers
  bool get isGraded => grade != null;
  String get statusLabel => isGraded ? 'Graded' : (isLate ? 'Late' : 'Submitted');
}

// models/response/submission_attachment_response.dart
@JsonSerializable()
class SubmissionAttachmentResponse {
  final String id;
  @JsonKey(name: 'file_name')
  final String fileName;
  @JsonKey(name: 'file_url')
  final String fileUrl;
  @JsonKey(name: 'file_size')
  final int fileSize;
  @JsonKey(name: 'file_type')
  final String fileType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
}
```

#### 2.2 API Service

**`services/submission_api_service.dart`:**

```dart
@RestApi()
abstract class SubmissionApiService {
  factory SubmissionApiService(Dio dio, {String baseUrl}) = _SubmissionApiService;

  /// Submit assignment
  @POST('/student/assignments/{assignmentId}/submit')
  Future<ApiResponse<SubmissionResponse>> submitAssignment(
    @Path('assignmentId') String assignmentId,
    @Body() SubmitAssignmentRequest request,
  );

  /// Get my submissions for assignment
  @GET('/student/assignments/{assignmentId}/submissions')
  Future<ApiResponse<List<SubmissionResponse>>> getMySubmissions(
    @Path('assignmentId') String assignmentId,
  );

  /// Get submission detail
  @GET('/student/submissions/{submissionId}')
  Future<ApiResponse<SubmissionResponse>> getSubmissionDetail(
    @Path('submissionId') String submissionId,
  );

  /// Upload temp file
  @POST('/student/submissions/upload')
  @MultiPart()
  Future<ApiResponse<TempAttachmentResponse>> uploadTempFile(
    @Part(name: 'file') File file,
  );
}
```

#### 2.3 Controller

**`modules/student/assignment/controllers/submit_assignment_controller.dart`:**

```dart
class SubmitAssignmentController extends GetxController {
  final SubmissionApiService _api;
  final FilePickerService _filePicker;
  
  // State
  final assignment = Rx<AssignmentResponse?>(null);
  final mySubmissions = <SubmissionResponse>[].obs;
  final selectedFiles = <File>[].obs;
  final tempAttachmentIds = <String>[].obs;
  final submissionText = ''.obs;
  final isUploading = false.obs;
  final isSubmitting = false.obs;
  
  // Computed
  int get currentAttempts => mySubmissions.length;
  int get remainingAttempts => (assignment.value?.maxAttempts ?? 1) - currentAttempts;
  bool get canSubmit => remainingAttempts > 0 && !isPastDeadline;
  bool get isPastDeadline {
    /**
     * TODO: Check if current time is past deadline
     * - If past late_due_date → true
     * - If past due_date && !allow_late_submission → true
     * - Otherwise → false
     */
  }
  bool get isLateSubmission {
    /**
     * TODO: Check if submission would be late
     * - If past due_date && before late_due_date → true
     * - Otherwise → false
     */
  }

  @override
  void onInit() {
    super.onInit();
    // Get assignmentId from arguments
    final assignmentId = Get.arguments['assignmentId'];
    loadAssignment(assignmentId);
    loadMySubmissions(assignmentId);
  }

  /// Load assignment details
  Future<void> loadAssignment(String assignmentId) async {
    /**
     * TODO: Load assignment details
     * - Fetch from API
     * - Store in assignment observable
     * - Show error if not accessible
     */
  }

  /// Load student's submission history
  Future<void> loadMySubmissions(String assignmentId) async {
    /**
     * TODO: Load submission history
     * - Fetch from API
     * - Store in mySubmissions observable
     * - Calculate remaining attempts
     */
  }

  /// Pick files from device
  Future<void> pickFiles() async {
    /**
     * TODO: File picker logic
     * 
     * 1. Check remaining file slots (based on assignment.max_files if exists)
     * 2. Use file_picker to select files
     * 3. Validate file types against assignment.file_formats
     * 4. Validate file sizes against assignment.max_file_size
     * 5. Add valid files to selectedFiles
     * 6. Show errors for invalid files
     */
  }

  /// Remove selected file
  void removeFile(int index) {
    selectedFiles.removeAt(index);
    tempAttachmentIds.removeAt(index);
  }

  /// Upload files to temp storage
  Future<void> uploadFiles() async {
    /**
     * TODO: Upload files logic
     * 
     * 1. Set isUploading = true
     * 2. For each file in selectedFiles:
     *    - Call uploadTempFile API
     *    - Get temp attachment ID
     *    - Add to tempAttachmentIds
     *    - Show progress
     * 3. Set isUploading = false
     * 4. Handle errors (retry option)
     */
  }

  /// Submit assignment
  Future<void> submit() async {
    /**
     * TODO: Submit logic
     * 
     * 1. Validation:
     *    - Check canSubmit
     *    - If no files and no text → Error
     *    - If late → Show warning dialog "This will be a late submission. Continue?"
     * 
     * 2. Upload files if not uploaded yet:
     *    - Call uploadFiles()
     * 
     * 3. Submit:
     *    - Call submitAssignment API with tempAttachmentIds and submissionText
     *    - Show loading indicator
     * 
     * 4. Success:
     *    - Show success message
     *    - Navigate back or to submission detail
     *    - Clear state
     * 
     * 5. Error handling:
     *    - Show error message
     *    - Keep files and text (don't clear)
     */
  }

  /// View submission detail
  void viewSubmission(SubmissionResponse submission) {
    /**
     * TODO: Navigate to submission detail page
     * - Pass submission as argument
     * - Show details: files, grade, feedback
     */
  }
}
```

#### 2.4 UI Pages

**Submit Assignment Page:**

```dart
/**
 * modules/student/assignment/views/submit_assignment_page.dart
 * 
 * Layout:
 * 
 * AppBar:
 *   - Title: "Submit Assignment"
 *   - Back button
 * 
 * Body:
 *   - Assignment Info Card:
 *     - Title, description
 *     - Deadline info (with countdown if close)
 *     - Attempts info: "Attempt 1 of 3"
 *     - Late submission warning (if applicable)
 *   
 *   - Submission Form:
 *     - Text input (optional): "Add comments"
 *     - File upload area:
 *       - Drag & drop or Browse button
 *       - Selected files list (with remove button)
 *       - File size/type validation indicators
 *       - Upload progress bars
 *     
 *   - Previous Submissions (expandable):
 *     - List of past attempts
 *     - Each item: Attempt #, Date, Status, Grade
 *     - Tap to view details
 * 
 * Bottom Button Bar:
 *   - Cancel button
 *   - Submit button (disabled if can't submit)
 *     - Shows "Submit" or "Submit (Late)" based on deadline
 */
```

**Submission Detail Page:**

```dart
/**
 * modules/student/assignment/views/submission_detail_page.dart
 * 
 * Layout:
 * 
 * AppBar:
 *   - Title: "Submission Detail"
 *   - Back button
 * 
 * Body:
 *   - Status Banner:
 *     - Green: "Submitted" / "Graded"
 *     - Orange: "Late Submission"
 *     - Blue: "Pending Grade"
 *   
 *   - Submission Info:
 *     - Attempt number
 *     - Submitted date/time
 *     - Late indicator (if applicable)
 *   
 *   - Grade Section (if graded):
 *     - Score display (large, prominent)
 *     - Feedback text (expandable)
 *     - Graded date
 *   
 *   - Submitted Files:
 *     - List of uploaded files
 *     - File name, size, type
 *     - Download button per file
 *   
 *   - Submission Text:
 *     - Comments from student
 */
```

---

## 🔒 VALIDATION RULES

### Backend Validations

```javascript
// In submitAssignment controller

// 1. Check enrollment
const isEnrolled = await checkStudentEnrollment(studentId, assignmentId);
if (!isEnrolled) {
  throw new AppError('Not enrolled in this assignment', 403);
}

// 2. Check max attempts
const currentAttempts = await countStudentAttempts(studentId, assignmentId);
if (currentAttempts >= assignment.max_attempts) {
  throw new AppError('Maximum attempts reached', 400, 'MAX_ATTEMPTS_REACHED');
}

// 3. Check deadline
const now = new Date();
const dueDate = new Date(assignment.due_date);
const lateDueDate = assignment.late_due_date ? new Date(assignment.late_due_date) : null;

if (now > dueDate) {
  if (!assignment.allow_late_submission) {
    throw new AppError('Deadline has passed', 400, 'DEADLINE_PASSED');
  }
  if (lateDueDate && now > lateDueDate) {
    throw new AppError('Late deadline has passed', 400, 'LATE_DEADLINE_PASSED');
  }
}

// 4. Validate file formats
if (assignment.file_formats && assignment.file_formats.length > 0) {
  const invalidFiles = tempAttachments.filter(att => 
    !assignment.file_formats.includes(att.file_type)
  );
  if (invalidFiles.length > 0) {
    throw new AppError('Invalid file formats', 400, 'INVALID_FILE_FORMAT');
  }
}

// 5. Validate file sizes
const maxSizeMB = assignment.max_file_size || 10;
const maxSizeBytes = maxSizeMB * 1024 * 1024;
const oversizedFiles = tempAttachments.filter(att => att.file_size > maxSizeBytes);
if (oversizedFiles.length > 0) {
  throw new AppError(`Files exceed ${maxSizeMB}MB limit`, 400, 'FILE_TOO_LARGE');
}
```

---

## 📊 UI/UX FLOW

### Happy Path:
```
Student opens assignment
    ↓
Sees submission form + past attempts
    ↓
Clicks "Add Files"
    ↓
Selects files from device
    ↓
Files validated and uploaded to temp storage
    ↓
Adds optional comments
    ↓
Clicks "Submit"
    ↓
Confirmation dialog (if late submission)
    ↓
Submission created + files finalized
    ↓
Success message + navigate to detail
```

### Edge Cases:
```
1. Max attempts reached → Disable submit, show message
2. Past deadline → Show error or late warning
3. Invalid file format → Show error, remove file
4. File too large → Show error, remove file
5. No internet → Files saved locally (offline capability)
6. Upload fails → Retry button, keep files
```

---

## ✅ TESTING CHECKLIST

### Backend:
- [ ] Submit with valid files
- [ ] Submit without files (text only)
- [ ] Submit past due_date (late)
- [ ] Submit past late_due_date (error)
- [ ] Submit with max_attempts reached (error)
- [ ] Submit with invalid file format (error)
- [ ] Submit with oversized file (error)
- [ ] Get submission history
- [ ] Download submission files

### Frontend:
- [ ] File picker works
- [ ] File validation (format, size)
- [ ] Upload progress indicators
- [ ] Submit button states (enabled/disabled)
- [ ] Late submission warning dialog
- [ ] Success/error messages
- [ ] Navigate between pages
- [ ] View submission detail
- [ ] Download files
- [ ] Offline support (cache assignment data)

---

## 🔄 REUSE FROM INSTRUCTOR

| Component | Reuse % | Changes |
|-----------|---------|---------|
| **File upload pattern** | 100% | Just change paths |
| **Temp attachment table** | 100% | Add `attachment_type = 'submission'` |
| **Finalize logic** | 90% | Change destination table |
| **Assignment model** | 100% | No changes |
| **File widget** | 100% | Reuse for student |

---

Đây là plan đầy đủ để implement submission feature. Có muốn tôi detail phần nào cụ thể không?