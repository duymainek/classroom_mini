import 'dart:typed_data';
import 'dart:convert';
import 'package:classroom_mini/app/data/models/request/auth_request.dart';
import 'package:classroom_mini/app/data/models/response/course_response.dart';
import 'package:classroom_mini/app/data/models/response/group_response.dart';
import 'package:get/get.dart';
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/metadata_service.dart';
import '../../../core/app_config.dart';

class StudentManagementController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> students = <Map<String, dynamic>>[].obs;
  final RxString query = ''.obs;

  // Create Student Form State
  final RxBool isCreatingStudent = false.obs;
  final RxInt currentStep = 0.obs;
  final RxBool isLoadingCourses = false.obs;
  final RxBool isLoadingGroups = false.obs;
  final RxList<Map<String, String>> courses = <Map<String, String>>[].obs;
  final RxList<Map<String, String>> groups = <Map<String, String>>[].obs;
  final RxString selectedSemesterId = ''.obs;
  final RxString selectedCourseId = ''.obs;
  final RxString selectedGroupId = ''.obs;

  // Import CSV State
  final RxBool isImporting = false.obs;
  final RxList<Map<String, dynamic>> importRows = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> importResults =
      <Map<String, dynamic>>[].obs;
  final RxMap<int, Map<String, dynamic>> rowResultByNumber =
      <int, Map<String, dynamic>>{}.obs;

  // Course and Group selection for import
  final RxList<Course> importCourses = <Course>[].obs;
  final RxList<Group> importGroups = <Group>[].obs;
  final Rx<Course?> selectedImportCourse = Rx<Course?>(null);
  final Rx<Group?> selectedImportGroup = Rx<Group?>(null);
  final RxBool useGlobalAssignment = true.obs;
  final RxMap<int, Course?> rowCourseAssignments = <int, Course?>{}.obs;
  final RxMap<int, Group?> rowGroupAssignments = <int, Group?>{}.obs;

  late final StudentRepository _studentRepository;
  late final CourseRepository _courseRepository;
  late final MetadataService _metadataService;

  @override
  void onInit() {
    super.onInit();
    final apiService = Get.find<ApiService>();
    _studentRepository = StudentRepository(
      apiService: apiService,
      storageService: Get.find<StorageService>(),
    );
    _courseRepository = CourseRepository(apiService);
    _metadataService = MetadataService(apiService);
    loadStudents();
  }

  Future<void> loadStudents() async {
    isLoading.value = true;
    try {
      final result = await _studentRepository.getStudents();
      if (result.success) {
        final List<Map<String, dynamic>> mapped = [];
        final list = result.students ?? [];
        for (final u in list) {
          final map = <String, dynamic>{
            'id': u.id,
            'username': u.username,
            'email': u.email,
            'fullName': u.fullName,
            'isActive': u.isActive,
            'groupId': u.groupId,
            'courseId': u.courseId,
            'group': u.group,
            'course': u.course,
          };
          mapped.add(map);
        }
        students.assignAll(mapped);
      }
    } finally {
      isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> get filteredStudents {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return students;
    return students.where((s) {
      final username = (s['username'] ?? '').toString().toLowerCase();
      final email = (s['email'] ?? '').toString().toLowerCase();
      final fullName = (s['fullName'] ?? '').toString().toLowerCase();
      return username.contains(q) || email.contains(q) || fullName.contains(q);
    }).toList();
  }

  void setQuery(String value) {
    query.value = value;
  }

  Future<void> refreshStudents() async {
    await loadStudents();
  }

  Map<String, dynamic>? findById(String id) {
    try {
      return students.firstWhereOrNull((s) => s['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteStudentById(String id) async {
    final res = await _studentRepository.deleteStudent(id);
    if (res.success) {
      students.removeWhere((s) => s['id'] == id);
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> createStudent({
    required String username,
    required String password,
    required String email,
    required String fullName,
    String? groupId,
    String? courseId,
  }) async {
    final res = await _studentRepository.createStudent(
      username: username,
      password: password,
      email: email,
      fullName: fullName,
      groupId: groupId,
      courseId: courseId,
    );
    if (res.success && res.student != null) {
      final u = res.student!;
      final studentMap = {
        'id': u.id,
        'username': u.username,
        'email': u.email,
        'fullName': u.fullName,
        'isActive': u.isActive,
        'groupId': u.groupId,
        'courseId': u.courseId,
        'group': u.group,
        'course': u.course,
      };
      students.insert(0, studentMap);
      return studentMap;
    }
    return null;
  }

  Future<bool> exportStudents({String format = 'csv'}) async {
    // Prefer direct bytes download and save for reliability across platforms
    final (Uint8List? bytes, String filename) =
        await _studentRepository.downloadStudentsCsv(format: format);
    if (bytes == null) return false;

    print('filename: $filename');
    print('bytes: ${bytes.length}');
    print('format: $format');

    try {
      await FileSaver.instance.saveFile(
        name: filename.replaceAll('.$format', ''),
        bytes: bytes,
        ext: format,
        mimeType: format == 'csv' ? MimeType.csv : MimeType.other,
      );
      print('saved');
      return true;
    } catch (_) {
      print('error: $_');
      return false;
    }
  }

  Future<bool> updateStudentName(String id, String fullName) async {
    // Minimal sample edit flow: update fullName only
    final update = UpdateStudentRequest(fullName: fullName);
    final res = await _studentRepository.updateStudent(id, update);
    if (res.success) {
      final index = students.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        final current = Map<String, dynamic>.from(students[index]);
        current['fullName'] = fullName;
        students[index] = current;
      }
      return true;
    }
    return false;
  }

  Future<bool> updateStudentActive(String id, bool isActive) async {
    final update = UpdateStudentRequest(isActive: isActive);
    final res = await _studentRepository.updateStudent(id, update);
    if (res.success) {
      final index = students.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        final current = Map<String, dynamic>.from(students[index]);
        current['isActive'] = isActive;
        students[index] = current;
      }
      return true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> previewImport(
      List<Map<String, dynamic>> rows) async {
    final res = await _studentRepository.importStudentsPreview(rows);
    if (res.success) return res.data;
    return null;
  }

  Future<Map<String, dynamic>?> confirmImportLegacy(
      List<Map<String, dynamic>> rows) async {
    final res = await _studentRepository.importStudents(rows);
    if (res.success) return res.data;
    return null;
  }

  Future<Map<String, dynamic>?> previewImportDetailed(
      List<Map<String, dynamic>> rows) async {
    final res = await _studentRepository.importStudentsPreviewRaw(rows);
    if (res.success) {
      return {
        'summary': res.summary,
        'results': res.results ?? [],
      };
    }
    return null;
  }

  Future<Map<String, dynamic>?> confirmImportDetailed(
      List<Map<String, dynamic>> rows,
      [Map<String, dynamic>? assignmentData]) async {
    try {
      final res =
          await _studentRepository.importStudentsRaw(rows, assignmentData);
      if (res.success) {
        return {
          'summary': res.summary,
          'results': res.results ?? [],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Import CSV Methods
  Future<void> loadImportCoursesAndGroups() async {
    try {
      isImporting.value = true;

      // Load courses
      final courseResponse = await Get.find<ApiService>().getCourses();
      if (courseResponse.success) {
        importCourses.assignAll(courseResponse.data.courses);
      }

      // Load groups
      final groupResponse = await Get.find<ApiService>().getGroups();
      if (groupResponse.success) {
        importGroups.assignAll(groupResponse.data.groups);
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi tải dữ liệu: $e');
    } finally {
      isImporting.value = false;
    }
  }

  void setImportCourse(Course? course) {
    selectedImportCourse.value = course;
    if (course != null) {
      loadImportGroupsForCourse(course.id);
    }
  }

  void setImportGroup(Group? group) {
    selectedImportGroup.value = group;
  }

  Future<void> loadImportGroupsForCourse(String courseId) async {
    try {
      final groupResponse = await Get.find<ApiService>().getGroups();
      if (groupResponse.success) {
        importGroups.assignAll(groupResponse.data.groups
            .where((g) => g.courseId == courseId)
            .toList());
        selectedImportGroup.value =
            null; // Reset selected group when course changes
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Lỗi tải nhóm: $e');
    }
  }

  void setUseGlobalAssignment(bool value) {
    useGlobalAssignment.value = value;
  }

  void updateRowCourseAssignment(int rowIndex, Course? course) {
    rowCourseAssignments[rowIndex] = course;
  }

  void updateRowGroupAssignment(int rowIndex, Group? group) {
    rowGroupAssignments[rowIndex] = group;
  }

  void removeImportRow(int index) {
    if (index >= 0 && index < importRows.length) {
      importRows.removeAt(index);
    }
  }

  Map<String, int> computeImportStats() {
    int ready = 0;
    int errors = 0;
    for (final r in importRows) {
      final original = (r['_rowNumber'] as num?)?.toInt();
      final res = original != null ? rowResultByNumber[original] : null;
      final status = (res?['status'] ?? '').toString().toUpperCase();
      if (status == 'READY' || status == 'CREATED') {
        ready++;
      } else {
        errors++;
      }
    }
    return {
      'ready': ready,
      'errors': errors,
      'total': importRows.length,
    };
  }

  Future<void> pickAndPreviewCsv() async {
    try {
      isImporting.value = true;

      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (res == null || res.files.isEmpty) {
        return;
      }

      final file = res.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        return;
      }

      final content = utf8.decode(bytes);
      final csvRows = const CsvToListConverter(eol: '\n').convert(content);
      if (csvRows.isEmpty) {
        return;
      }

      final headers = csvRows.first.map((e) => e.toString()).toList();
      final requiredHeaders = {'username', 'email', 'fullName', 'isActive'};
      final headerSet = headers.map((e) => e.trim()).toSet();

      if (!headerSet.containsAll(requiredHeaders)) {
        Get.snackbar('Lỗi',
            'CSV thiếu cột bắt buộc: username, email, fullName, isActive');
        return;
      }

      final List<Map<String, dynamic>> records = [];
      for (int i = 1; i < csvRows.length; i++) {
        final row = csvRows[i];
        if (row.isEmpty ||
            row.every((c) => (c?.toString().trim().isEmpty ?? true))) {
          continue;
        }

        final map = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j].toString()] = row[j];
        }

        map['username'] = map['username']?.toString().trim();
        map['email'] = map['email']?.toString().trim();
        map['fullName'] = map['fullName']?.toString().trim();
        final isActiveStr = map['isActive']?.toString().toLowerCase();
        map['isActive'] = (isActiveStr == 'true' ||
            isActiveStr == '1' ||
            isActiveStr == 'yes');
        map['_rowNumber'] = i; // track original row number
        records.add(map);
      }

      final detailed = await previewImportDetailed(records);
      if (detailed == null) {
        Get.snackbar('Lỗi', 'Xem trước thất bại');
        return;
      }

      importRows.assignAll(records);
      importResults.assignAll(
          List<Map<String, dynamic>>.from(detailed['results'] as List));
      rowResultByNumber.assignAll({
        for (final r in importResults)
          if (r['rowNumber'] != null) (r['rowNumber'] as num).toInt(): r
      });
    } catch (e) {
      Get.snackbar('Lỗi', 'Không đọc được tệp CSV');
    } finally {
      isImporting.value = false;
    }
  }

  Future<void> confirmImport() async {
    try {
      isImporting.value = true;

      // Prepare assignment data
      Map<String, dynamic> assignmentData = {};

      if (useGlobalAssignment.value) {
        // Global assignment
        assignmentData['globalCourseId'] = selectedImportCourse.value?.id;
        assignmentData['globalGroupId'] = selectedImportGroup.value?.id;
      } else {
        // Individual assignments
        Map<String, Map<String, String>> assignments = {};
        for (int i = 0; i < importRows.length; i++) {
          final course = rowCourseAssignments[i];
          final group = rowGroupAssignments[i];
          if (course != null || group != null) {
            assignments[i.toString()] = {
              if (course != null) 'courseId': course.id,
              if (group != null) 'groupId': group.id,
            };
          }
        }
        assignmentData['assignments'] = assignments;
      }

      // Validate assignment data
      if (useGlobalAssignment.value) {
        if (selectedImportCourse.value == null ||
            selectedImportGroup.value == null) {
          Get.snackbar('Lỗi', 'Vui lòng chọn khóa học và nhóm');
          return;
        }
      }

      final detailed = await confirmImportDetailed(importRows, assignmentData);
      if (detailed == null) {
        Get.snackbar('Lỗi', 'Import thất bại');
        return;
      }

      final summary = detailed['summary'] as Map<String, dynamic>?;
      Get.snackbar('Thành công',
          'Hoàn tất import: thêm ${summary?['created'] ?? 0}, bỏ qua ${summary?['skipped'] ?? 0}');

      // Refresh students list
      await refreshStudents();

      // Clear import data after successful import
      clearImportData();
    } catch (e) {
      Get.snackbar('Lỗi', 'Import thất bại: $e');
    } finally {
      isImporting.value = false;
    }
  }

  void clearImportData() {
    importRows.clear();
    importResults.clear();
    rowResultByNumber.clear();
    selectedImportCourse.value = null;
    selectedImportGroup.value = null;
    rowCourseAssignments.clear();
    rowGroupAssignments.clear();
  }

  // Create Student Form Methods
  void initializeCreateStudentForm() {
    currentStep.value = 0;
    courses.clear();
    groups.clear();
    selectedSemesterId.value = '';
    selectedCourseId.value = '';
    selectedGroupId.value = '';
    _ensureSemesterContext();
  }

  Future<void> _ensureSemesterContext() async {
    final cfg = AppConfig.instance;
    if (cfg.hasSelectedSemester()) {
      print(
          '[StudentController] AppConfig semester: id=${cfg.selectedSemesterId} name=${cfg.selectedSemesterName}');
      selectedSemesterId.value = cfg.selectedSemesterId;
      await loadCourses(cfg.selectedSemesterId);
      return;
    }
    try {
      print(
          '[StudentController] No semester in AppConfig. Fetching current semester...');
      final current = await Get.find<ApiService>().getCurrentSemester();
      if (current.success && current.data?.currentSemester != null) {
        final s = current.data!.currentSemester!;
        print(
            '[StudentController] Fetched current semester: id=${s.id} name=${s.name}');
        AppConfig.instance.setSelectedSemester(
          semesterId: s.id,
          semesterName: s.name,
          semesterCode: s.code,
        );
        selectedSemesterId.value = s.id;
        await loadCourses(s.id);
      }
    } catch (e) {
      print('[StudentController] Error fetching current semester: $e');
    }
  }

  Future<void> loadCourses(String semesterId) async {
    try {
      isLoadingCourses.value = true;
      print('[StudentController] Loading courses for semester=$semesterId ...');

      final res = await _courseRepository.getCourses(
        page: 1,
        limit: 100,
        search: '',
        status: 'active',
        semesterId: semesterId,
      );

      courses.assignAll(
        res.data.courses.map((c) => {'id': c.id, 'label': c.name}).toList(),
      );

      print('[StudentController] Courses loaded: count=${courses.length}');

      // Auto-select if only one course
      if (courses.length == 1) {
        selectedCourseId.value = courses.first['id']!;
        print(
            '[StudentController] Auto-selected single course: ${selectedCourseId.value}');
        await loadGroups(selectedCourseId.value);
      }
    } catch (e) {
      print('[StudentController] Error loading courses: $e');
    } finally {
      isLoadingCourses.value = false;
    }
  }

  Future<void> loadGroups(String courseId) async {
    try {
      isLoadingGroups.value = true;
      print('[StudentController] Loading groups for course=$courseId ...');

      final groupsList = await _metadataService.loadGroupsForCourse(courseId);
      groups.assignAll(
        groupsList.map((g) => {'id': g.id, 'label': g.name}).toList(),
      );

      print('[StudentController] Groups loaded: count=${groups.length}');
    } catch (e) {
      print('[StudentController] Error loading groups: $e');
    } finally {
      isLoadingGroups.value = false;
    }
  }

  void onCourseChanged(String? courseId) {
    selectedCourseId.value = courseId ?? '';
    selectedGroupId.value = '';
    groups.clear();
    if (courseId != null && courseId.isNotEmpty) {
      loadGroups(courseId);
    }
  }

  void onGroupChanged(String? groupId) {
    selectedGroupId.value = groupId ?? '';
  }

  void nextStep() {
    if (currentStep.value < 1) {
      currentStep.value++;
    }
  }

  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
    }
  }

  Future<Map<String, dynamic>?> createStudentWithForm({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    if (selectedCourseId.value.isEmpty || selectedGroupId.value.isEmpty) {
      Get.snackbar('Lỗi', 'Chọn khoá và nhóm để gán');
      return null;
    }

    isCreatingStudent.value = true;
    try {
      final created = await createStudent(
        username: username,
        password: password,
        email: email,
        fullName: fullName,
        groupId: selectedGroupId.value,
        courseId: selectedCourseId.value,
      );

      if (created != null) {
        Get.snackbar('Thành công', 'Đã tạo sinh viên và gán nhóm/khoá');
        // Reset form
        initializeCreateStudentForm();
      } else {
        Get.snackbar('Lỗi', 'Tạo tài khoản thất bại');
      }

      return created;
    } catch (e) {
      Get.snackbar('Lỗi', 'Có lỗi xảy ra: $e');
      return null;
    } finally {
      isCreatingStudent.value = false;
    }
  }
}
