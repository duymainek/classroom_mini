/**
 * AppConfig quản lý các cấu hình toàn cục của ứng dụng
 * Bao gồm thông tin học kì đang được chọn, user info, và các settings khác
 */
class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  static AppConfig get instance => _instance;

  // Simple values (not reactive)
  String _selectedSemesterId = '';
  String _selectedSemesterName = '';
  String _selectedSemesterCode = '';
  bool _isSemesterSelected = false;
  bool _isInstructor = false;

  // Getters
  String get selectedSemesterId => _selectedSemesterId;
  String get selectedSemesterName => _selectedSemesterName;
  String get selectedSemesterCode => _selectedSemesterCode;
  bool get isSemesterSelected => _isSemesterSelected;
  bool get isInstructor => _isInstructor;

  /**
   * Thiết lập học kì đang được chọn
   * @param {String} semesterId - ID của học kì
   * @param {String} semesterName - Tên học kì
   * @param {String} semesterCode - Mã học kì
   */
  void setSelectedSemester({
    required String semesterId,
    required String semesterName,
    required String semesterCode,
  }) {
    _selectedSemesterId = semesterId;
    _selectedSemesterName = semesterName;
    _selectedSemesterCode = semesterCode;
    _isSemesterSelected = true;
  }

  /**
   * Xóa lựa chọn học kì hiện tại
   */
  void clearSelectedSemester() {
    _selectedSemesterId = '';
    _selectedSemesterName = '';
    _selectedSemesterCode = '';
    _isSemesterSelected = false;
  }

  /**
   * Kiểm tra xem có học kì nào được chọn không
   * @returns {bool} true nếu có học kì được chọn
   */
  bool hasSelectedSemester() {
    return _isSemesterSelected && _selectedSemesterId.isNotEmpty;
  }

  /**
   * Lấy thông tin học kì hiện tại dưới dạng Map
   * @returns {Map<String, String>} Thông tin học kì
   */
  Map<String, String> getCurrentSemesterInfo() {
    return {
      'id': _selectedSemesterId,
      'name': _selectedSemesterName,
      'code': _selectedSemesterCode,
    };
  }

  /**
   * Thiết lập role của user
   * @param {bool} isInstructor - true nếu là instructor, false nếu là student
   */
  void setUserRole(bool isInstructor) {
    _isInstructor = isInstructor;
  }

  /**
   * Xóa thông tin role của user (khi logout)
   */
  void clearUserRole() {
    _isInstructor = false;
  }
}
