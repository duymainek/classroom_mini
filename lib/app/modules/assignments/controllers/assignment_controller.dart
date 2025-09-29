import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/gemini_service.dart'; // Import GeminiService
import '../../../data/models/assignment_model.dart';
import '../../../data/models/submission_model.dart';
import '../../../data/models/assignment_request_models.dart';
import '../../../data/models/assignment_response_models.dart';
import '../models/assignment_form_state.dart';
import '../../../core/utils/semester_helper.dart';

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

  // Form setters
  void initFormState({List<CourseInfo>? courses, List<GroupInfo>? groups}) {
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
      final resp = await _apiService.getCourses(page: page, limit: limit);
      final courses = resp.data.courses
          .map((c) => CourseInfo(id: c.id, code: c.code, name: c.name))
          .toList();
      updateForm((s) {
        s.courses = courses;
      });
    } catch (e) {
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
          .map((g) => GroupInfo(id: g.id, name: g.name))
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
        _assignments.assignAll(response.data);
      } else {
        _assignments.addAll(response.data);
      }

      _hasMore.value = _currentPage.value < response.pagination.pages;
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
      return response.data;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải chi tiết bài tập: $e');
      return null;
    }
  }

  /// Create new assignment
  Future<bool> createAssignment(AssignmentCreateRequest request) async {
    _isLoading.value = true;
    _error.value = '';
    bool dialogShown = false;

    try {
      // Freeze UI with loading dialog
      if (!(Get.isDialogOpen ?? false)) {
        dialogShown = true;
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
          return false;
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
      );

      final response = await _apiService.createAssignment(sanitized);
      _assignments.insert(0, response.data);
      Get.snackbar('Thành công', 'Tạo bài tập thành công');
      // Close only the loading dialog here; navigation handled by UI caller
      if (Get.isDialogOpen == true) {
        Get.back();
      }
      return true;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tạo bài tập: $e');
      return false;
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
        _assignments[index] = response.data;
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

  /// Load assignment submissions
  Future<void> loadAssignmentSubmissions(
    String assignmentId, {
    int page = 1,
    int limit = 20,
    String search = '',
    String status = 'all',
    String sortBy = 'submitted_at',
    String sortOrder = 'desc',
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
      );

      _submissions.assignAll(response.data);
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
        _assignments.assignAll(response.data);
      } else {
        _assignments.addAll(response.data);
      }

      _hasMore.value = _currentPage.value < response.pagination.pages;
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

  /// Upload attachment
  Future<SubmissionAttachment?> uploadAttachment(
      String submissionId, FileUploadRequest request) async {
    try {
      final response =
          await _apiService.uploadAttachment(submissionId, request);
      return response.data;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải file: $e');
      return null;
    }
  }

  /// Delete attachment
  Future<bool> deleteAttachment(String attachmentId) async {
    try {
      await _apiService.deleteAttachment(attachmentId);
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
