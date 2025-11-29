import 'package:classroom_mini/app/data/models/response/course_response.dart';
import 'package:classroom_mini/app/data/models/response/group_response.dart';
import 'package:get/get.dart' hide MultipartFile;
import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/gemini_service.dart'; // Import GeminiService
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import 'package:classroom_mini/app/data/models/response/submission_response.dart';
import 'package:classroom_mini/app/data/models/request/assignment_request.dart';
import '../models/assignment_form_state.dart';
import '../../../core/utils/semester_helper.dart';
import '../../../routes/app_routes.dart';

class AssignmentController extends GetxController {
  final ApiService _apiService = ApiService(DioClient.dio);
  late final GeminiService _geminiService; // Instantiate GeminiService

  @override
  void onInit() {
    super.onInit();
    _geminiService = GeminiService(); // Initialize GeminiService without Dio
    loadAssignments();
  }

  // New method to generate description using Gemini API
  void generateDescriptionFromGemini(String prompt) {
    // Changed return type to void
    _isGeneratingDescription.value = true; // Use dedicated loading state
    _error.value = '';
    String accumulatedDescription = '';

    _geminiService.generateDescription(prompt).listen(
      (chunk) {
        accumulatedDescription += chunk;
        updateForm((s) => s.description = accumulatedDescription);
      },
      onError: (e) {
        _error.value = e.toString();
        Get.snackbar('Lỗi', 'Không thể tạo mô tả: $e');
        _isGeneratingDescription.value = false;
      },
      onDone: () {
        _isGeneratingDescription.value = false;
        Get.snackbar('Thành công', 'Đã tạo mô tả bằng Gemini AI');
      },
    );
  }

  // Observable variables
  final RxList<Assignment> _assignments = <Assignment>[].obs;
  final RxList<SubmissionTrackingData> _submissions =
      <SubmissionTrackingData>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _statusFilter = 'all'.obs;
  final RxString _sortBy = 'created_at'.obs;
  final RxString _sortOrder = 'desc'.obs;
  final RxInt _currentPage = 1.obs;
  final RxBool _hasMore = true.obs;

  // Form state: selected group ids for assignment distribution
  final RxSet<String> _selectedGroupIdsForForm = <String>{}.obs;
  final Rx<AssignmentFormState> _formState = AssignmentFormState().obs;
  final RxBool _isFormMetaLoading = false.obs;
  final RxBool _isGeneratingDescription =
      false.obs; // Dedicated loading for Gemini
  final RxBool _isGroupsLoading = false.obs; // Loading flag for groups only
  final RxString _selectedGroupIdForSubmissions = ''.obs;

  // Controllers
  final TextEditingController searchController = TextEditingController();

  // Getters
  List<Assignment> get assignments => _assignments;
  List<SubmissionTrackingData> get submissions => _submissions;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get searchQuery => _searchQuery.value;
  String get statusFilter => _statusFilter.value;
  String get sortBy => _sortBy.value;
  String get sortOrder => _sortOrder.value;
  int get currentPage => _currentPage.value;
  bool get hasMore => _hasMore.value;
  Set<String> get selectedGroupIdsForForm => _selectedGroupIdsForForm;
  RxSet<String> get selectedGroupIdsForFormRx => _selectedGroupIdsForForm;
  Rx<AssignmentFormState> get formState => _formState; // Return the Rx object

  bool get isFormMetaLoading => _isFormMetaLoading.value;
  bool get isGeneratingDescription =>
      _isGeneratingDescription.value; // Getter for new loading state
  bool get isGroupsLoading => _isGroupsLoading.value;
  String get selectedGroupIdForSubmissions =>
      _selectedGroupIdForSubmissions.value;

  void updateSelectedGroupIdForSubmissions(String? groupId) {
    _selectedGroupIdForSubmissions.value = groupId ?? '';
  }

  // Tracking statistics getters
  int get totalStudents => _submissions.length;
  int get submittedCount => _submissions
      .where((s) => s.status != SubmissionStatus.notSubmitted)
      .length;
  int get notSubmittedCount => _submissions
      .where((s) => s.status == SubmissionStatus.notSubmitted)
      .length;
  int get lateCount =>
      _submissions.where((s) => s.status == SubmissionStatus.late).length;
  int get gradedCount =>
      _submissions.where((s) => s.status == SubmissionStatus.graded).length;
  double get submissionRate =>
      totalStudents > 0 ? (submittedCount / totalStudents) * 100 : 0.0;
  double get averageGrade {
    final gradedSubmissions =
        _submissions.where((s) => s.averageGrade != null).toList();
    if (gradedSubmissions.isEmpty) return 0.0;
    return gradedSubmissions
            .map((s) => s.averageGrade!)
            .reduce((a, b) => a + b) /
        gradedSubmissions.length;
  }

  // Form setters
  void initFormState({List<Course>? courses, List<Group>? groups}) {
    _formState.value = AssignmentFormState(courses: courses, groups: groups);
  }

  void updateForm(void Function(AssignmentFormState) mutate) {
    final current = _formState.value;
    mutate(current);
    _formState.refresh();
  }

  Future<void> loadCoursesForForm({int page = 1, int limit = 200}) async {
    if (_isFormMetaLoading.value) return;
    _isFormMetaLoading.value = true;
    try {
      debugPrint('🔄 [AssignmentController] Loading courses for form...');
      final resp = await _apiService.getCourses(page: page, limit: limit);
      debugPrint('✅ [AssignmentController] Courses response received. Success: ${resp.success}, Courses count: ${resp.data.courses.length}');
      
      if (resp.data.courses.isEmpty) {
        debugPrint('⚠️ [AssignmentController] No courses found in response');
        updateForm((s) {
          s.courses = [];
        });
        return;
      }
      
      final courses = resp.data.courses
          .map((c) => Course(
              id: c.id,
              code: c.code,
              name: c.name,
              sessionCount: c.sessionCount,
              semesterId: c.semesterId,
              isActive: c.isActive,
              createdAt: c.createdAt,
              updatedAt: c.updatedAt))
          .toList();
      
      debugPrint('✅ [AssignmentController] Parsed ${courses.length} courses');
      updateForm((s) {
        s.courses = courses;
      });
      debugPrint('✅ [AssignmentController] Updated form state with courses');
    } catch (e, stackTrace) {
      debugPrint('❌ [AssignmentController] Error loading courses: $e');
      debugPrint('❌ [AssignmentController] Stack trace: $stackTrace');
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải danh sách khóa học: $e');
    } finally {
      _isFormMetaLoading.value = false;
    }
  }

  Future<void> loadGroupsForForm(String courseId,
      {int page = 1, int limit = 500}) async {
    if (_isGroupsLoading.value) return;
    _isGroupsLoading.value = true;
    try {
      final resp = await _apiService.getGroups(
          courseId: courseId, page: page, limit: limit);
      final groups = resp.data.groups
          .map((g) => Group(
              id: g.id,
              name: g.name,
              courseId: g.courseId,
              isActive: g.isActive,
              createdAt: g.createdAt,
              updatedAt: g.updatedAt))
          .toList();
      updateForm((s) {
        s.groups = groups;
      });
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải danh sách nhóm: $e');
    } finally {
      _isGroupsLoading.value = false;
    }
  }

  void setSelectedGroupsForForm(Iterable<String> ids) {
    _selectedGroupIdsForForm
      ..clear()
      ..addAll(ids);
  }

  void toggleGroupSelectionForForm(String id, {bool? selected}) {
    if (selected == null) {
      if (_selectedGroupIdsForForm.contains(id)) {
        _selectedGroupIdsForForm.remove(id);
      } else {
        _selectedGroupIdsForForm.add(id);
      }
    } else {
      if (selected) {
        _selectedGroupIdsForForm.add(id);
      } else {
        _selectedGroupIdsForForm.remove(id);
      }
    }
  }

  void clearSelectedGroupsForForm() {
    _selectedGroupIdsForForm.clear();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Load assignments with current filters
  Future<void> loadAssignments({bool refresh = false}) async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    _error.value = '';

    if (refresh) {
      _currentPage.value = 1;
      _assignments.clear();
      _hasMore.value = true;
    }

    try {
      // Lấy semesterId từ SemesterHelper
      final semesterId = SemesterHelper.getCurrentSemesterId();

      final response = await _apiService.getAssignments(
        page: _currentPage.value,
        limit: 20,
        search: _searchQuery.value,
        status: _statusFilter.value,
        sortBy: _sortBy.value,
        sortOrder: _sortOrder.value,
        semesterId: semesterId.isNotEmpty ? semesterId : null,
      );

      if (refresh) {
        _assignments.assignAll(response.data.assignments);
      } else {
        _assignments.addAll(response.data.assignments);
      }

      _hasMore.value = _currentPage.value < response.data.pagination.pages;
      _currentPage.value++;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải danh sách bài tập: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load more assignments (pagination)
  Future<void> loadMoreAssignments() async {
    if (!_hasMore.value || _isLoading.value) return;
    await loadAssignments();
  }

  /// Search assignments
  void searchAssignments(String query) {
    _searchQuery.value = query;
    loadAssignments(refresh: true);
  }

  /// Filter assignments by status
  void filterByStatus(String status) {
    _statusFilter.value = status;
    loadAssignments(refresh: true);
  }

  /// Sort assignments
  void sortAssignments(String sortBy, String sortOrder) {
    _sortBy.value = sortBy;
    _sortOrder.value = sortOrder;
    loadAssignments(refresh: true);
  }

  /// Get assignment by ID
  Future<Assignment?> getAssignmentById(String assignmentId) async {
    try {
      final response = await _apiService.getAssignmentById(assignmentId);
      return response.data.assignment;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải chi tiết bài tập: $e');
      return null;
    }
  }

  /// Create new assignment
  Future<String?> createAssignment(AssignmentCreateRequest request) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      // Freeze UI with loading dialog
      if (!(Get.isDialogOpen ?? false)) {
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
      }
      // Đảm bảo có học kì được chọn; nếu chưa, tự động chọn học kì mới nhất
      String semesterId;
      if (!SemesterHelper.hasSelectedSemester()) {
        final ok = await SemesterHelper.autoSelectLatestSemester();
        if (!ok) {
          _error.value = 'Vui lòng chọn học kì trước khi tạo bài tập';
          return null;
        }
      }
      semesterId = SemesterHelper.getCurrentSemesterId();

      // Adapt to new UI: sanitize numeric and temporal fields before submit
      final int clampedAttempts = request.maxAttempts.clamp(1, 10);
      final int clampedMaxFileSize = request.maxFileSize.clamp(1, 100);

      DateTime start = request.startDate;
      DateTime due = request.dueDate.isBefore(start) ? start : request.dueDate;
      DateTime? lateDue;
      if (request.allowLateSubmission && request.lateDueDate != null) {
        lateDue = request.lateDueDate!.isAfter(due) ? request.lateDueDate : due;
      }

      // Allow only supported formats
      const allowed = {
        'pdf',
        'doc',
        'docx',
        'txt',
        'jpg',
        'jpeg',
        'png',
        'zip',
        'rar'
      };
      final sanitizedFormats = request.fileFormats
          .map((e) => e.toLowerCase())
          .where((e) => allowed.contains(e))
          .toSet()
          .toList();

      // Debug: Log attachment IDs before creating request
      debugPrint('=== CONTROLLER DEBUG ===');
      debugPrint('Original request.attachmentIds: ${request.attachmentIds}');
      debugPrint('attachmentIds is null: ${request.attachmentIds == null}');
      debugPrint('attachmentIds length: ${request.attachmentIds?.length ?? 0}');
      debugPrint('=== END CONTROLLER DEBUG ===');

      final sanitized = AssignmentCreateRequest(
        title: request.title.trim(),
        description: request.description?.trim().isEmpty == true
            ? null
            : request.description?.trim(),
        courseId: request.courseId,
        semesterId: semesterId, // Thêm semesterId vào request
        startDate: start,
        dueDate: due,
        lateDueDate: lateDue,
        allowLateSubmission: request.allowLateSubmission,
        maxAttempts: clampedAttempts,
        fileFormats: sanitizedFormats,
        maxFileSize: clampedMaxFileSize,
        groupIds: (request.groupIds == null)
            ? <String>[]
            : request.groupIds!.where((e) => e.trim().isNotEmpty).toList(),
        // Include attachment IDs if any are provided
        attachmentIds: request.attachmentIds,
      );

      final response = await _apiService.createAssignment(sanitized);
      _assignments.insert(0, response.data.assignment);
      Get.snackbar('Thành công', 'Tạo bài tập thành công');
      _isLoading.value = false;

      // Close loading dialog first
      if (Get.isDialogOpen == true) {
        Get.back();
      }

      // Wait a bit for dialog to close, then navigate
      await Future.delayed(const Duration(milliseconds: 100));
      Get.offAllNamed(Routes.ASSIGNMENTS_LIST);
      return response.data.assignment.id; // Return the created assignment ID
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tạo bài tập: $e');
      return null;
    } finally {
      _isLoading.value = false;
      // Ensure dialog closed in any case (controller only closes dialog)
    }
  }

  /// Update assignment
  Future<bool> updateAssignment(AssignmentUpdateRequest request) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final response = await _apiService.updateAssignment(request.id, request);
      final index = _assignments.indexWhere((a) => a.id == request.id);
      if (index != -1) {
        _assignments[index] = response.data.assignment;
      }
      Get.snackbar('Thành công', 'Cập nhật bài tập thành công');
      return true;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể cập nhật bài tập: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete assignment
  Future<bool> deleteAssignment(String assignmentId) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      await _apiService.deleteAssignment(assignmentId);
      _assignments.removeWhere((a) => a.id == assignmentId);
      Get.snackbar('Thành công', 'Xóa bài tập thành công');
      return true;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể xóa bài tập: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Show delete confirmation dialog
  Future<bool> showDeleteConfirmation(Assignment assignment) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(Get.context!)
                    .colorScheme
                    .errorContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_outlined,
                color: Theme.of(Get.context!).colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Xác nhận xóa'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa bài tập này không?',
              style: Theme.of(Get.context!).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(Get.context!)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(Get.context!)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment,
                        size: 20,
                        color: Theme.of(Get.context!).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          assignment.title,
                          style: Theme.of(Get.context!)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (assignment.description != null &&
                      assignment.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      assignment.description!,
                      style:
                          Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                                color: Theme.of(Get.context!)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (assignment.course != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          size: 16,
                          color: Theme.of(Get.context!)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${assignment.course!.code} - ${assignment.course!.name}',
                            style: Theme.of(Get.context!)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(Get.context!)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(Get.context!)
                    .colorScheme
                    .errorContainer
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(Get.context!)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Theme.of(Get.context!).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hành động này không thể hoàn tác.',
                      style:
                          Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                                color: Theme.of(Get.context!).colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).colorScheme.error,
              foregroundColor: Theme.of(Get.context!).colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete, size: 18),
                SizedBox(width: 8),
                Text('Xóa'),
              ],
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await deleteAssignment(assignment.id);
      return success;
    }
    return false;
  }

  /// Load assignment submissions
  Future<void> loadAssignmentSubmissions(
    String assignmentId, {
    int page = 1,
    int limit = 20,
    String search = '',
    String status = 'all',
    String sortBy = 'submitted_at',
    String sortOrder = 'desc',
    String groupId = '',
    String attemptFilter = 'all',
  }) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final response = await _apiService.getAssignmentSubmissions(
        assignmentId,
        page: page,
        limit: limit,
        search: search,
        status: status,
        sortBy: sortBy,
        sortOrder: sortOrder,
        groupId:
            groupId.isEmpty ? _selectedGroupIdForSubmissions.value : groupId,
        attemptFilter: attemptFilter,
      );

      // Sắp xếp: những học sinh đã nộp lên trên, chưa nộp xuống dưới
      final sortedSubmissions = List<SubmissionTrackingData>.from(
        response.data.submissions,
      )..sort((a, b) {
          // Ưu tiên: đã nộp > chưa nộp
          final aHasSubmitted = a.status != SubmissionStatus.notSubmitted;
          final bHasSubmitted = b.status != SubmissionStatus.notSubmitted;

          if (aHasSubmitted && !bHasSubmitted) return -1;
          if (!aHasSubmitted && bHasSubmitted) return 1;

          // Nếu cùng trạng thái, sắp xếp theo thời gian nộp (mới nhất lên trên)
          if (aHasSubmitted && bHasSubmitted) {
            final aTime = a.latestSubmission?.submittedAt;
            final bTime = b.latestSubmission?.submittedAt;
            if (aTime != null && bTime != null) {
              return bTime.compareTo(aTime);
            }
            if (aTime != null) return -1;
            if (bTime != null) return 1;
          }

          // Nếu chưa nộp hoặc không có thời gian, sắp xếp theo tên
          return a.fullName.compareTo(b.fullName);
        });

      _submissions.assignAll(sortedSubmissions);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải danh sách nộp bài: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Grade submission
  Future<bool> gradeSubmission(
      String submissionId, GradeSubmissionRequest request) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      await _apiService.gradeSubmission(submissionId, request);
      Get.snackbar('Thành công', 'Chấm điểm thành công');
      return true;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể chấm điểm: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Export submissions to CSV
  Future<List<int>?> exportSubmissions(String assignmentId) async {
    try {
      return await _apiService.exportSubmissions(assignmentId);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể xuất dữ liệu: $e');
      return null;
    }
  }

  /// Export assignment tracking data to CSV (includes all students)
  Future<List<int>?> exportAssignmentTracking(
    String assignmentId, {
    String search = '',
    String status = 'all',
    String groupId = '',
    String sortBy = 'fullName',
    String sortOrder = 'asc',
  }) async {
    try {
      return await _apiService.exportAssignmentTracking(
        assignmentId,
        search: search,
        status: status,
        groupId: groupId,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể xuất dữ liệu theo dõi: $e');
      return null;
    }
  }

  /// Export all assignments to CSV
  Future<List<int>?> exportAllAssignments({
    String courseId = '',
    String semesterId = '',
    bool includeSubmissions = true,
    bool includeGrades = true,
  }) async {
    try {
      return await _apiService.exportAllAssignments(
        courseId: courseId,
        semesterId: semesterId,
        includeSubmissions: includeSubmissions,
        includeGrades: includeGrades,
      );
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể xuất tất cả bài tập: $e');
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error.value = '';
  }

  /// Reset filters
  void resetFilters() {
    _searchQuery.value = '';
    _statusFilter.value = 'all';
    _sortBy.value = 'created_at';
    _sortOrder.value = 'desc';
    loadAssignments(refresh: true);
  }
}

class StudentAssignmentController extends GetxController {
  final ApiService _apiService = ApiService(DioClient.dio);

  // Observable variables
  final RxList<Assignment> _assignments = <Assignment>[].obs;
  final RxList<AssignmentSubmission> _submissions =
      <AssignmentSubmission>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _statusFilter = 'all'.obs;
  final RxInt _currentPage = 1.obs;
  final RxBool _hasMore = true.obs;

  // Getters
  List<Assignment> get assignments => _assignments;
  List<AssignmentSubmission> get submissions => _submissions;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get searchQuery => _searchQuery.value;
  String get statusFilter => _statusFilter.value;
  int get currentPage => _currentPage.value;
  bool get hasMore => _hasMore.value;

  @override
  void onInit() {
    super.onInit();
    loadAssignments();
  }

  /// Load student assignments
  Future<void> loadAssignments({bool refresh = false}) async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    _error.value = '';

    if (refresh) {
      _currentPage.value = 1;
      _assignments.clear();
      _hasMore.value = true;
    }

    try {
      // Lấy semesterId từ SemesterHelper
      final semesterId = SemesterHelper.getCurrentSemesterId();

      final response = await _apiService.getAssignments(
        page: _currentPage.value,
        limit: 20,
        search: _searchQuery.value,
        status: _statusFilter.value,
        sortBy: 'due_date',
        sortOrder: 'asc',
        semesterId: semesterId.isNotEmpty ? semesterId : null,
      );

      if (refresh) {
        _assignments.assignAll(response.data.assignments);
      } else {
        _assignments.addAll(response.data.assignments);
      }

      _hasMore.value = _currentPage.value < response.data.pagination.pages;
      _currentPage.value++;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải danh sách bài tập: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load more assignments (pagination)
  Future<void> loadMoreAssignments() async {
    if (!_hasMore.value || _isLoading.value) return;
    await loadAssignments();
  }

  /// Search assignments
  void searchAssignments(String query) {
    _searchQuery.value = query;
    loadAssignments(refresh: true);
  }

  /// Filter assignments by status
  void filterByStatus(String status) {
    _statusFilter.value = status;
    loadAssignments(refresh: true);
  }

  /// Get student submissions for an assignment
  Future<StudentSubmissionResponse?> getStudentSubmissions(
      String assignmentId) async {
    try {
      return await _apiService.getStudentSubmissions(assignmentId);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải thông tin nộp bài: $e');
      return null;
    }
  }

  /// Submit assignment
  Future<bool> submitAssignment(
      String assignmentId, SubmitAssignmentRequest request) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      await _apiService.submitAssignment(assignmentId, request);
      Get.snackbar('Thành công', 'Nộp bài thành công');
      return true;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể nộp bài: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update submission
  Future<bool> updateSubmission(
      String submissionId, UpdateSubmissionRequest request) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      await _apiService.updateSubmission(submissionId, request);
      Get.snackbar('Thành công', 'Cập nhật bài nộp thành công');
      return true;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể cập nhật bài nộp: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete submission
  Future<bool> deleteSubmission(String submissionId) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      await _apiService.deleteSubmission(submissionId);
      Get.snackbar('Thành công', 'Xóa bài nộp thành công');
      return true;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể xóa bài nộp: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Delete attachment
  Future<bool> deleteAttachment(String attachmentId) async {
    try {
      await _apiService.deleteAssignmentAttachment(attachmentId);
      Get.snackbar('Thành công', 'Xóa file thành công');
      return true;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể xóa file: $e');
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error.value = '';
  }

  /// Reset filters
  void resetFilters() {
    _searchQuery.value = '';
    _statusFilter.value = 'all';
    loadAssignments(refresh: true);
  }
}
