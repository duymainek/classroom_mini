import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:file_saver/file_saver.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/services/api_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/models/request_models.dart';

class StudentManagementController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> students = <Map<String, dynamic>>[].obs;
  final RxString query = ''.obs;

  late final StudentRepository _studentRepository;

  @override
  void onInit() {
    super.onInit();
    _studentRepository = StudentRepository(
      apiService: Get.find<ApiService>(),
      storageService: Get.find<StorageService>(),
    );
    loadStudents();
  }

  Future<void> loadStudents() async {
    isLoading.value = true;
    try {
      final result = await _studentRepository.getStudents();
      if (result.success) {
        final List<Map<String, dynamic>> mapped = [];
        final list = result.students ?? [];
        final groups = result.groups;
        final courses = result.courses;
        for (int i = 0; i < list.length; i++) {
          final u = list[i];
          final map = <String, dynamic>{
            'id': u.id,
            'username': u.username,
            'email': u.email,
            'fullName': u.fullName,
            'isActive': u.isActive,
            'groupId': u.groupId,
            'courseId': u.courseId,
          };
          if (groups != null && i < groups.length) {
            map['group'] = groups[i];
          }
          if (courses != null && i < courses.length) {
            map['course'] = courses[i];
          }
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

  Future<Map<String, dynamic>?> confirmImport(
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
      List<Map<String, dynamic>> rows) async {
    final res = await _studentRepository.importStudentsRaw(rows);
    if (res.success) {
      return {
        'summary': res.summary,
        'results': res.results ?? [],
      };
    }
    return null;
  }
}
