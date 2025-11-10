import 'package:classroom_mini/app/data/models/request/course_request.dart';
import 'package:classroom_mini/app/data/models/request/group_request.dart';
import 'package:classroom_mini/app/data/models/request/semester_request.dart';
import 'package:classroom_mini/app/data/models/response/course_response.dart';
import 'package:classroom_mini/app/data/models/response/group_response.dart';
import 'package:classroom_mini/app/data/models/response/semester_response.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/semester_repository.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/group_repository.dart';

class CoreManagementController extends GetxController {
  // Repositories
  final SemesterRepository _semesterRepository;
  final CourseRepository _courseRepository;
  final GroupRepository _groupRepository;

  CoreManagementController(
    this._semesterRepository,
    this._courseRepository,
    this._groupRepository,
  );

  bool _preloaded = false;

  // Observable states (filtered for UI)
  final RxList<Semester> _semesters = <Semester>[].obs;
  final RxList<Course> _courses = <Course>[].obs;
  final RxList<Group> _groups = <Group>[].obs;

  // Cached master lists
  final List<Semester> _allSemesters = <Semester>[];
  final List<Course> _allCourses = <Course>[];
  final List<Group> _allGroups = <Group>[];

  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _currentTab = 'semesters'.obs;

  // Pagination states
  final RxInt _semesterPage = 1.obs;
  final RxInt _coursePage = 1.obs;
  final RxInt _groupPage = 1.obs;
  final RxInt _semesterTotalPages = 1.obs;
  final RxInt _courseTotalPages = 1.obs;
  final RxInt _groupTotalPages = 1.obs;

  // Search and filter states
  final RxString _semesterSearch = ''.obs;
  final RxString _courseSearch = ''.obs;
  final RxString _groupSearch = ''.obs;
  final RxString _selectedSemesterId = ''.obs;
  final RxString _selectedCourseId = ''.obs;

  // Getters
  List<Semester> get semesters => _semesters;
  List<Course> get courses => _courses;
  List<Group> get groups => _groups;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get currentTab => _currentTab.value;
  int get semesterPage => _semesterPage.value;
  int get coursePage => _coursePage.value;
  int get groupPage => _groupPage.value;
  int get semesterTotalPages => _semesterTotalPages.value;
  int get courseTotalPages => _courseTotalPages.value;
  int get groupTotalPages => _groupTotalPages.value;
  String get semesterSearch => _semesterSearch.value;
  String get courseSearch => _courseSearch.value;
  String get groupSearch => _groupSearch.value;
  String get selectedSemesterId => _selectedSemesterId.value;
  String get selectedCourseId => _selectedCourseId.value;

  // Tab management
  Future<void> setCurrentTab(String tab) async {
    _currentTab.value = tab;
    update();
    // Preload once if not already
    if (!_preloaded) {
      await Future.wait([
        loadSemesters(refresh: true),
        loadCourses(refresh: true),
        loadGroups(refresh: true),
      ]);
      _preloaded = true;
    } else {
      // Apply local filters for the visible tab (no network)
      if (tab == 'courses') {
        _applyCourseFilters();
      } else if (tab == 'groups') {
        _applyGroupFilters();
      } else {
        _applySemesterFilters();
      }
    }
  }

  // Semester management
  Future<void> loadSemesters({bool refresh = false}) async {
    if (refresh) _semesterPage.value = 1;

    try {
      _isLoading.value = true;
      update();
      _errorMessage.value = '';

      final response = await _semesterRepository.getSemesters(
        page: _semesterPage.value,
        search: _semesterSearch.value,
        status: 'all',
      );

      if (refresh) {
        _allSemesters.clear();
      }
      _allSemesters.addAll(response.data.semesters);
      _applySemesterFilters();
      _semesterTotalPages.value = (response.data.pagination.pages == 0)
          ? 1
          : response.data.pagination.pages;
    } catch (e) {
      _errorMessage.value = e.toString();
      debugPrint('error: $e');
    } finally {
      _isLoading.value = false;
      update();
    }
  }

  Future<void> createSemester(String code, String name) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final request = SemesterCreateRequest(code: code, name: name);
      final newSemester = await _semesterRepository.createSemester(request);

      _allSemesters.insert(0, newSemester);
      _applySemesterFilters();
      Get.snackbar('Success', 'Semester created successfully');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateSemester(
      String semesterId, String code, String name, bool isActive) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final request = SemesterUpdateRequest(
        code: code,
        name: name,
        isActive: isActive,
      );
      final updatedSemester =
          await _semesterRepository.updateSemester(semesterId, request);

      final index = _allSemesters.indexWhere((s) => s.id == semesterId);
      if (index != -1) {
        _allSemesters[index] = updatedSemester;
      }
      _applySemesterFilters();
      Get.snackbar('Success', 'Semester updated successfully');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteSemester(String semesterId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _semesterRepository.deleteSemester(semesterId);
      _allSemesters.removeWhere((s) => s.id == semesterId);
      _applySemesterFilters();
      Get.snackbar('Success', 'Semester deleted successfully');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Course management
  Future<void> loadCourses({bool refresh = false}) async {
    if (refresh) _coursePage.value = 1;

    try {
      _isLoading.value = true;
      update();
      _errorMessage.value = '';

      final response = await _courseRepository.getCourses(
        page: _coursePage.value,
        search: _courseSearch.value,
        semesterId: _selectedSemesterId.value,
        status: 'all',
      );

      if (refresh) {
        _allCourses.clear();
      }
      _allCourses.addAll(response.data.courses);
      _applyCourseFilters();
      _courseTotalPages.value = (response.data.pagination.pages == 0)
          ? 1
          : response.data.pagination.pages;
    } catch (e) {
      _errorMessage.value = e.toString();
    } finally {
      _isLoading.value = false;
      update();
    }
  }

  Future<void> createCourse(
      String code, String name, int sessionCount, String semesterId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final request = CourseCreateRequest(
        code: code,
        name: name,
        sessionCount: sessionCount,
        semesterId: semesterId,
      );
      final newCourse = await _courseRepository.createCourse(request);

      _allCourses.insert(0, newCourse);
      _applyCourseFilters();
      Get.snackbar('Success', 'Course created successfully');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateCourse(String courseId, String code, String name,
      int sessionCount, String semesterId, bool isActive) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final request = CourseUpdateRequest(
        code: code,
        name: name,
        sessionCount: sessionCount,
        semesterId: semesterId,
        isActive: isActive,
      );
      final updatedCourse =
          await _courseRepository.updateCourse(courseId, request);

      final index = _allCourses.indexWhere((c) => c.id == courseId);
      if (index != -1) {
        _allCourses[index] = updatedCourse;
      }
      _applyCourseFilters();
      Get.snackbar('Success', 'Course updated successfully');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteCourse(String courseId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _courseRepository.deleteCourse(courseId);
      _allCourses.removeWhere((c) => c.id == courseId);
      _applyCourseFilters();
      Get.snackbar('Success', 'Course deleted successfully');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Group management
  Future<void> loadGroups({bool refresh = false}) async {
    if (refresh) _groupPage.value = 1;

    try {
      _isLoading.value = true;
      update();
      _errorMessage.value = '';

      final response = await _groupRepository.getGroups(
        page: _groupPage.value,
        search: _groupSearch.value,
        courseId: _selectedCourseId.value,
        status: 'all',
      );

      if (refresh) {
        _allGroups.clear();
      }
      _allGroups.addAll(response.data.groups);
      _applyGroupFilters();
      _groupTotalPages.value = (response.data.pagination.pages == 0)
          ? 1
          : response.data.pagination.pages;
    } catch (e) {
      _errorMessage.value = e.toString();
    } finally {
      _isLoading.value = false;
      update();
    }
  }

  Future<void> createGroup(String name, String courseId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final request = GroupCreateRequest(name: name, courseId: courseId);
      final newGroup = await _groupRepository.createGroup(request);

      _allGroups.insert(0, newGroup);
      _applyGroupFilters();
      Get.snackbar('Success', 'Group created successfully');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateGroup(
      String groupId, String name, String courseId, bool isActive) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final request = GroupUpdateRequest(
        name: name,
        courseId: courseId,
        isActive: isActive,
      );
      final updatedGroup = await _groupRepository.updateGroup(groupId, request);

      final index = _allGroups.indexWhere((g) => g.id == groupId);
      if (index != -1) {
        _allGroups[index] = updatedGroup;
      }
      _applyGroupFilters();
      Get.snackbar('Success', 'Group updated successfully');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _groupRepository.deleteGroup(groupId);
      _allGroups.removeWhere((g) => g.id == groupId);
      _applyGroupFilters();
      Get.snackbar('Success', 'Group deleted successfully');
    } catch (e) {
      _errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  // Search and filter methods
  void setSemesterSearch(String search) {
    _semesterSearch.value = search;
    _applySemesterFilters();
  }

  void setCourseSearch(String search) {
    _courseSearch.value = search;
    _applyCourseFilters();
  }

  void setGroupSearch(String search) {
    _groupSearch.value = search;
    _applyGroupFilters();
  }

  void setSelectedSemester(String semesterId) {
    _selectedSemesterId.value = semesterId;
    _applyCourseFilters();
  }

  void setSelectedCourse(String courseId) {
    _selectedCourseId.value = courseId;
    _applyGroupFilters();
  }

  // Pagination methods
  void loadNextSemesterPage() {
    if (_semesterPage.value < _semesterTotalPages.value) {
      _semesterPage.value++;
      loadSemesters();
    }
  }

  void loadNextCoursePage() {
    if (_coursePage.value < _courseTotalPages.value) {
      _coursePage.value++;
      loadCourses();
    }
  }

  void loadNextGroupPage() {
    if (_groupPage.value < _groupTotalPages.value) {
      _groupPage.value++;
      loadGroups();
    }
  }

  // Initialization
  @override
  void onInit() {
    super.onInit();
    // Handle optional initial tab from navigation arguments
    final args = Get.arguments;
    if (args is Map && args['initialTab'] is String) {
      final String initialTab = args['initialTab'];
      setCurrentTab(initialTab);
      // Preload all master data once; local filters handle tab views
      loadSemesters(refresh: true);
      loadCourses(refresh: true);
      loadGroups(refresh: true);
      _preloaded = true;
    } else {
      loadSemesters(refresh: true);
      loadCourses(refresh: true);
      loadGroups(refresh: true);
      _preloaded = true;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  // Local filter appliers
  void _applySemesterFilters() {
    final q = _semesterSearch.value.trim().toLowerCase();
    if (q.isEmpty) {
      _semesters
        ..clear()
        ..addAll(_allSemesters);
    } else {
      _semesters
        ..clear()
        ..addAll(_allSemesters.where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.code.toLowerCase().contains(q)));
    }
    update();
  }

  void _applyCourseFilters() {
    final q = _courseSearch.value.trim().toLowerCase();
    final semId = _selectedSemesterId.value;
    Iterable<Course> list = _allCourses;
    if (semId.isNotEmpty) list = list.where((c) => c.semesterId == semId);
    if (q.isNotEmpty) {
      list = list.where((c) =>
          c.name.toLowerCase().contains(q) || c.code.toLowerCase().contains(q));
    }
    _courses
      ..clear()
      ..addAll(list);
    update();
  }

  void _applyGroupFilters() {
    final q = _groupSearch.value.trim().toLowerCase();
    final cId = _selectedCourseId.value;
    Iterable<Group> list = _allGroups;
    if (cId.isNotEmpty) list = list.where((g) => g.courseId == cId);
    if (q.isNotEmpty)
      list = list.where((g) => g.name.toLowerCase().contains(q));
    _groups
      ..clear()
      ..addAll(list);
    update();
  }
}
