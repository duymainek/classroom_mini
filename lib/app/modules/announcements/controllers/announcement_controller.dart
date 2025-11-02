import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:classroom_mini/app/data/services/announcement_api_service.dart';
import 'package:classroom_mini/app/data/services/api_service.dart';
import 'package:classroom_mini/app/data/models/request/announcement_request.dart';
import 'package:classroom_mini/app/data/models/response/announcement_response.dart';
import 'package:classroom_mini/app/data/models/response/course_response.dart';
import 'package:classroom_mini/app/data/models/response/group_response.dart';

/**
 * Announcement Controller
 * Manages announcement operations using GetX state management
 */
class AnnouncementController extends GetxController {
  final AnnouncementApiService _apiService =
      AnnouncementApiService(DioClient.dio);
  final ApiService _mainApiService = DioClient.apiService;

  // Observable variables
  final RxList<Announcement> _announcements = <Announcement>[].obs;
  final RxList<AnnouncementComment> _comments = <AnnouncementComment>[].obs;
  final RxList<StudentTracking> _trackingData = <StudentTracking>[].obs;
  final RxList<FileTrackingData> _fileTrackingData = <FileTrackingData>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _scopeFilter = 'all'.obs;
  final RxString _sortBy = 'published_at'.obs;
  final RxString _sortOrder = 'desc'.obs;
  final RxInt _currentPage = 1.obs;
  final RxBool _hasMore = true.obs;

  // Form state
  final Rx<AnnouncementFormState> _formState = AnnouncementFormState().obs;
  final RxBool _isFormLoading = false.obs;
  final RxBool _isCommentsLoading = false.obs;
  final RxBool _isTrackingLoading = false.obs;

  // Courses and Groups data
  final RxList<Course> _courses = <Course>[].obs;
  final RxList<Group> _groups = <Group>[].obs;
  final RxBool _isLoadingCourses = false.obs;
  final RxBool _isLoadingGroups = false.obs;

  // Getters
  List<Announcement> get announcements => _announcements;
  List<AnnouncementComment> get comments => _comments;
  List<StudentTracking> get trackingData => _trackingData;
  List<FileTrackingData> get fileTrackingData => _fileTrackingData;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get searchQuery => _searchQuery.value;
  String get scopeFilter => _scopeFilter.value;
  String get sortBy => _sortBy.value;
  String get sortOrder => _sortOrder.value;
  int get currentPage => _currentPage.value;
  bool get hasMore => _hasMore.value;
  Rx<AnnouncementFormState> get formState => _formState;
  bool get isFormLoading => _isFormLoading.value;
  bool get isCommentsLoading => _isCommentsLoading.value;
  bool get isTrackingLoading => _isTrackingLoading.value;

  // Courses and Groups getters
  List<Course> get courses => _courses;
  List<Group> get groups => _groups;
  bool get isLoadingCourses => _isLoadingCourses.value;
  bool get isLoadingGroups => _isLoadingGroups.value;

  @override
  void onInit() {
    super.onInit();
    loadAnnouncements();
    loadCourses();
  }

  @override
  void onClose() {
    super.onClose();
  }

  /// Load announcements with current filters
  Future<void> loadAnnouncements({bool refresh = false}) async {
    if (_isLoading.value) return;

    _isLoading.value = true;
    _error.value = '';

    if (refresh) {
      _currentPage.value = 1;
      _announcements.clear();
      _hasMore.value = true;
    }

    try {
      final response = await _apiService.getAnnouncements(
        page: _currentPage.value,
        limit: 20,
        search: _searchQuery.value.isEmpty ? null : _searchQuery.value,
        courseId: _formState.value.courseId?.isEmpty == true
            ? null
            : _formState.value.courseId,
        scopeType: _scopeFilter.value == 'all' ? null : _scopeFilter.value,
        sortBy: _sortBy.value,
        sortOrder: _sortOrder.value,
      );

      if (response.success && response.data?.announcements != null) {
        if (refresh) {
          _announcements.assignAll(response.data!.announcements!);
        } else {
          _announcements.addAll(response.data!.announcements!);
        }

        if (response.data!.pagination != null) {
          _hasMore.value =
              _currentPage.value < response.data!.pagination!.pages;
          _currentPage.value++;
        }
      } else {
        _error.value = response.message;
        Get.snackbar(
            'Lỗi', 'Không thể tải danh sách thông báo: ${response.message}');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải danh sách thông báo: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Load more announcements (pagination)
  Future<void> loadMoreAnnouncements() async {
    if (!_hasMore.value || _isLoading.value) return;
    await loadAnnouncements();
  }

  /// Search announcements
  void searchAnnouncements(String query) {
    _searchQuery.value = query;
    loadAnnouncements(refresh: true);
  }

  /// Filter announcements by scope
  void filterByScope(String scope) {
    _scopeFilter.value = scope;
    loadAnnouncements(refresh: true);
  }

  /// Sort announcements
  void sortAnnouncements(String sortBy, String sortOrder) {
    _sortBy.value = sortBy;
    _sortOrder.value = sortOrder;
    loadAnnouncements(refresh: true);
  }

  /// Get announcement by ID
  Future<Announcement?> getAnnouncementById(String announcementId) async {
    try {
      final response = await _apiService.getAnnouncementById(announcementId);
      if (response.success && response.data?.announcement != null) {
        return response.data!.announcement!;
      }
      return null;
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải chi tiết thông báo: $e');
      return null;
    }
  }

  /// Create new announcement
  Future<String?> createAnnouncement(CreateAnnouncementRequest request) async {
    _isFormLoading.value = true;
    _error.value = '';

    try {
      print('=== CREATING ANNOUNCEMENT ===');
      print('Request: ${request.toJson()}');

      final response = await _apiService.createAnnouncement(request);

      print('Response received:');
      print('Success: ${response.success}');
      print('Message: ${response.message}');
      print('Data: ${response.data?.toJson()}');

      if (response.success && response.data?.announcement != null) {
        _announcements.insert(0, response.data!.announcement!);
        Get.snackbar('Thành công', 'Tạo thông báo thành công');
        return response.data!.announcement!.id;
      } else {
        _error.value = response.message;
        Get.snackbar('Lỗi', 'Không thể tạo thông báo: ${response.message}');
        return null;
      }
    } catch (e) {
      print('=== CREATE ANNOUNCEMENT ERROR ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tạo thông báo: $e');
      return null;
    } finally {
      _isFormLoading.value = false;
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }

  /// Update announcement
  Future<bool> updateAnnouncement(
      String id, UpdateAnnouncementRequest request) async {
    _isFormLoading.value = true;
    _error.value = '';

    try {
      final response = await _apiService.updateAnnouncement(id, request);

      if (response.success && response.data?.announcement != null) {
        final index = _announcements.indexWhere((a) => a.id == id);
        if (index != -1) {
          _announcements[index] = response.data!.announcement!;
        }
        Get.snackbar('Thành công', 'Cập nhật thông báo thành công');
        return true;
      } else {
        _error.value = response.message;
        Get.snackbar(
            'Lỗi', 'Không thể cập nhật thông báo: ${response.message}');
        return false;
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể cập nhật thông báo: $e');
      return false;
    } finally {
      _isFormLoading.value = false;
    }
  }

  /// Delete announcement
  Future<bool> deleteAnnouncement(String announcementId) async {
    _isLoading.value = true;
    _error.value = '';

    try {
      final response = await _apiService.deleteAnnouncement(announcementId);

      if (response.success) {
        _announcements.removeWhere((a) => a.id == announcementId);
        Get.snackbar('Thành công', 'Xóa thông báo thành công');
        return true;
      } else {
        _error.value = response.message;
        Get.snackbar('Lỗi', 'Không thể xóa thông báo: ${response.message}');
        return false;
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể xóa thông báo: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Show delete confirmation dialog
  Future<void> showDeleteConfirmation(Announcement announcement) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn có chắc chắn muốn xóa thông báo này không?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(Get.context!)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style:
                        Theme.of(Get.context!).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    announcement.content,
                    style: Theme.of(Get.context!).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hành động này không thể hoàn tác.',
              style: Theme.of(Get.context!).textTheme.bodySmall?.copyWith(
                    color: Theme.of(Get.context!).colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(Get.context!).colorScheme.error,
              foregroundColor: Theme.of(Get.context!).colorScheme.onError,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (result == true) {
      await deleteAnnouncement(announcement.id);
    }
  }

  /// Load announcement comments
  Future<void> loadAnnouncementComments(String announcementId,
      {int page = 1, int limit = 20}) async {
    _isCommentsLoading.value = true;
    _error.value = '';

    try {
      final response = await _apiService.getAnnouncementComments(
        announcementId,
        page: page,
        limit: limit,
      );

      if (response.success && response.data?.comments != null) {
        if (page == 1) {
          _comments.assignAll(response.data!.comments!);
        } else {
          _comments.addAll(response.data!.comments!);
        }
      } else {
        _error.value = response.message;
        Get.snackbar('Lỗi', 'Không thể tải bình luận: ${response.message}');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải bình luận: $e');
    } finally {
      _isCommentsLoading.value = false;
    }
  }

  /// Add comment to announcement
  Future<bool> addComment(
      String announcementId, AddCommentRequest request) async {
    try {
      final response = await _apiService.addComment(announcementId, request);

      if (response.success &&
          response.data?.comments != null &&
          response.data!.comments!.isNotEmpty) {
        _comments.insert(0, response.data!.comments!.first);
        Get.snackbar('Thành công', 'Thêm bình luận thành công');
        return true;
      } else {
        Get.snackbar('Lỗi', 'Không thể thêm bình luận: ${response.message}');
        return false;
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể thêm bình luận: $e');
      return false;
    }
  }

  /// Track announcement view
  Future<void> trackView(String announcementId) async {
    try {
      await _apiService.trackView(announcementId);
    } catch (e) {
      // Silent fail for tracking
      print('Failed to track view: $e');
    }
  }

  /// Track file download
  Future<void> trackDownload(String fileId) async {
    try {
      await _apiService.trackDownload(fileId);
    } catch (e) {
      // Silent fail for tracking
      print('Failed to track download: $e');
    }
  }

  /// Load announcement tracking data
  Future<void> loadAnnouncementTracking(String announcementId,
      {String? groupId, String? status}) async {
    _isTrackingLoading.value = true;
    _error.value = '';

    try {
      final response = await _apiService.getAnnouncementTracking(
        announcementId,
        groupId: groupId,
        status: status,
      );

      if (response.success && response.data?.tracking != null) {
        _trackingData.assignAll(response.data!.tracking!.tracking);
      } else {
        _error.value = response.message;
        Get.snackbar(
            'Lỗi', 'Không thể tải dữ liệu theo dõi: ${response.message}');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu theo dõi: $e');
    } finally {
      _isTrackingLoading.value = false;
    }
  }

  /// Load file download tracking data
  Future<void> loadFileDownloadTracking(String announcementId,
      {String? fileId}) async {
    _isTrackingLoading.value = true;
    _error.value = '';

    try {
      final response = await _apiService.getFileDownloadTracking(
        announcementId,
        fileId: fileId,
      );

      if (response.success && response.data?.fileTracking != null) {
        _fileTrackingData.assignAll(response.data!.fileTracking!);
      } else {
        _error.value = response.message;
        Get.snackbar(
            'Lỗi', 'Không thể tải dữ liệu tải xuống: ${response.message}');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải dữ liệu tải xuống: $e');
    } finally {
      _isTrackingLoading.value = false;
    }
  }

  /// Load announcement file tracking data (alias for loadFileDownloadTracking)
  Future<void> loadAnnouncementFileTracking(String announcementId,
      {String? fileId}) async {
    await loadFileDownloadTracking(announcementId, fileId: fileId);
  }

  /// Getter for file tracking loading state
  bool get isFileTrackingLoading => _isTrackingLoading.value;

  /// Form management
  void initFormState() {
    _formState.value = AnnouncementFormState();
  }

  void updateForm(void Function(AnnouncementFormState) mutate) {
    final current = _formState.value;
    mutate(current);
    _formState.refresh();
  }

  /// Clear error
  void clearError() {
    _error.value = '';
  }

  /// Reset filters
  void resetFilters() {
    _searchQuery.value = '';
    _scopeFilter.value = 'all';
    _sortBy.value = 'published_at';
    _sortOrder.value = 'desc';
    loadAnnouncements(refresh: true);
  }

  /// Load courses from API
  Future<void> loadCourses() async {
    if (_isLoadingCourses.value) return;

    _isLoadingCourses.value = true;
    _error.value = '';

    try {
      final response = await _mainApiService.getCourses(
        page: 1,
        limit: 100, // Load all courses for form
        search: '',
        status: 'active',
        semesterId: '',
        sortBy: 'name',
        sortOrder: 'asc',
      );

      if (response.success) {
        _courses.assignAll(response.data.courses);
      } else {
        _error.value = 'Không thể tải danh sách khóa học';
        Get.snackbar('Lỗi', 'Không thể tải danh sách khóa học');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải danh sách khóa học: $e');
    } finally {
      _isLoadingCourses.value = false;
    }
  }

  /// Load groups by course ID
  Future<void> loadGroupsByCourse(String courseId) async {
    if (_isLoadingGroups.value) return;

    _isLoadingGroups.value = true;
    _error.value = '';

    try {
      final response = await _mainApiService.getGroupsByCourse(
        courseId,
        page: 1,
        limit: 100, // Load all groups for the course
        search: '',
        status: 'active',
      );

      if (response.success) {
        _groups.assignAll(response.data.groups);
      } else {
        _error.value = 'Không thể tải danh sách nhóm';
        Get.snackbar('Lỗi', 'Không thể tải danh sách nhóm');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Lỗi', 'Không thể tải danh sách nhóm: $e');
    } finally {
      _isLoadingGroups.value = false;
    }
  }

  /// Finalize attachments for announcement
  Future<bool> finalizeAttachments(
      String announcementId, List<String> attachmentIds) async {
    try {
      print('=== FINALIZING ATTACHMENTS ===');
      print('Announcement ID: $announcementId');
      print('Attachment IDs: $attachmentIds');

      final response = await _mainApiService.finalizeAnnouncementAttachments(
        announcementId,
        {'attachmentIds': attachmentIds},
      );

      print('Finalize response: ${response.toJson()}');

      if (response.success) {
        print('Attachments finalized successfully');
        return true;
      } else {
        print('Failed to finalize attachments: ${response.message}');
        Get.snackbar(
            'Lỗi', 'Không thể finalize attachments: ${response.message}');
        return false;
      }
    } catch (e) {
      print('=== FINALIZE ATTACHMENTS ERROR ===');
      print('Error: $e');
      Get.snackbar('Lỗi', 'Không thể finalize attachments: $e');
      return false;
    }
  }
}

/**
 * Announcement Form State
 * Manages form data for creating/editing announcements
 */
class AnnouncementFormState {
  String? title;
  String? content;
  String? courseId;
  String? scopeType;
  List<String>? groupIds;
  List<String>? attachmentIds;

  AnnouncementFormState({
    this.title,
    this.content,
    this.courseId,
    this.scopeType,
    this.groupIds,
    this.attachmentIds,
  });

  AnnouncementFormState copyWith({
    String? title,
    String? content,
    String? courseId,
    String? scopeType,
    List<String>? groupIds,
    List<String>? attachmentIds,
  }) {
    return AnnouncementFormState(
      title: title ?? this.title,
      content: content ?? this.content,
      courseId: courseId ?? this.courseId,
      scopeType: scopeType ?? this.scopeType,
      groupIds: groupIds ?? this.groupIds,
      attachmentIds: attachmentIds ?? this.attachmentIds,
    );
  }

  bool get isValidBasic {
    final titleOk = (title?.trim().length ?? 0) >= 2;
    final contentOk = (content?.trim().length ?? 0) >= 10;
    final courseOk = courseId != null && courseId!.isNotEmpty;
    final scopeOk = scopeType != null && scopeType!.isNotEmpty;

    return titleOk && contentOk && courseOk && scopeOk;
  }

  String? get titleError {
    if (title == null || title!.trim().isEmpty) {
      return 'Vui lòng nhập tiêu đề';
    }
    if (title!.trim().length < 2) {
      return 'Tiêu đề phải có ít nhất 2 ký tự';
    }
    return null;
  }

  String? get contentError {
    if (content == null || content!.trim().isEmpty) {
      return 'Vui lòng nhập nội dung';
    }
    if (content!.trim().length < 10) {
      return 'Nội dung phải có ít nhất 10 ký tự';
    }
    return null;
  }

  bool get isValidScope {
    if (scopeType == 'one_group') {
      return groupIds != null && groupIds!.length == 1;
    } else if (scopeType == 'multiple_groups') {
      return groupIds != null && groupIds!.isNotEmpty;
    } else if (scopeType == 'all_groups') {
      return true;
    }
    return false;
  }

  bool get isValid {
    return isValidBasic && isValidScope;
  }
}
