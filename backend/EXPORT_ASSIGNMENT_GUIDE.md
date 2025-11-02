# Hướng Dẫn Sử Dụng Chức Năng Export Assignment

## Tổng Quan

Chức năng export assignment cho phép giảng viên xuất dữ liệu bài tập ra file CSV để phục vụ quá trình đánh giá cuối kỳ.

## Các Loại Export

### 1. Export Assignment Tracking (Theo dõi chi tiết từng bài tập)

**Endpoint:** `GET /api/assignments/{assignmentId}/export/tracking`

**Mô tả:** Xuất dữ liệu theo dõi chi tiết cho một bài tập cụ thể, bao gồm tất cả sinh viên (đã nộp và chưa nộp).

**Tham số:**
- `search` (optional): Tìm kiếm theo tên sinh viên
- `status` (optional): Lọc theo trạng thái (all, submitted, not_submitted, late, graded)
- `groupId` (optional): Lọc theo nhóm cụ thể
- `sortBy` (optional): Sắp xếp theo trường (fullName, email, status, etc.)
- `sortOrder` (optional): Thứ tự sắp xếp (asc, desc)

**Dữ liệu xuất ra:**
- Username, Full Name, Email
- Group Name
- Status (not_submitted, submitted, late, graded)
- Total Submissions (tổng số lần nộp)
- Graded Submissions (số lần đã chấm điểm)
- Late Submissions (số lần nộp trễ)
- Average Grade (điểm trung bình)
- Latest Grade (điểm lần nộp gần nhất)
- Latest Submitted At (thời gian nộp gần nhất)
- Latest Is Late (có nộp trễ không)

### 2. Export All Assignments (Xuất tất cả bài tập)

**Endpoint:** `GET /api/assignments/export/all`

**Mô tả:** Xuất danh sách tất cả bài tập trong khóa học hoặc học kỳ.

**Tham số:**
- `courseId` (optional): Lọc theo khóa học
- `semesterId` (optional): Lọc theo học kỳ
- `includeSubmissions` (optional): Bao gồm thống kê nộp bài
- `includeGrades` (optional): Bao gồm thống kê điểm số

**Dữ liệu xuất ra:**
- Assignment Title, Course Code, Course Name
- Instructor, Start Date, Due Date, Late Due Date
- Max Attempts, Active status
- Total Submissions, Graded Submissions, Late Submissions
- Average Grade (nếu includeGrades = true)

## Cách Sử Dụng Trong Flutter App

### 1. Export Assignment Tracking

```dart
// Trong AssignmentTrackingPage
Future<void> _exportTracking() async {
  try {
    Get.dialog(const Center(child: CircularProgressIndicator()));
    
    final csvBytes = await controller.exportAssignmentTracking(
      widget.assignmentId,
      search: '', // Tìm kiếm theo tên
      status: 'all', // Lọc theo trạng thái
      groupId: '', // Lọc theo nhóm
      sortBy: 'fullName', // Sắp xếp theo tên
      sortOrder: 'asc', // Thứ tự tăng dần
    );
    
    if (Get.isDialogOpen == true) Get.back();
    
    if (csvBytes == null || csvBytes.isEmpty) {
      Get.snackbar('Lỗi', 'Không thể xuất dữ liệu');
      return;
    }
    
    // Lưu file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filePath = '${directory.path}/assignment_tracking_${widget.assignmentId}_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsBytes(csvBytes);
    
    Get.snackbar('Thành công', 'Đã xuất file CSV: $filePath');
  } catch (e) {
    if (Get.isDialogOpen == true) Get.back();
    Get.snackbar('Lỗi', 'Không thể xuất file: $e');
  }
}
```

### 2. Export All Assignments

```dart
// Trong AssignmentListPage
Future<void> _exportAllAssignments(AssignmentController controller) async {
  try {
    Get.dialog(const Center(child: CircularProgressIndicator()));
    
    final semesterId = SemesterHelper.getCurrentSemesterId();
    final csvBytes = await controller.exportAllAssignments(
      semesterId: semesterId,
      includeSubmissions: true,
      includeGrades: true,
    );
    
    if (Get.isDialogOpen == true) Get.back();
    
    if (csvBytes == null || csvBytes.isEmpty) {
      Get.snackbar('Lỗi', 'Không thể xuất dữ liệu');
      return;
    }
    
    // Lưu file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filePath = '${directory.path}/all_assignments_$timestamp.csv';
    final file = File(filePath);
    await file.writeAsBytes(csvBytes);
    
    Get.snackbar('Thành công', 'Đã xuất file CSV: $filePath');
  } catch (e) {
    if (Get.isDialogOpen == true) Get.back();
    Get.snackbar('Lỗi', 'Không thể xuất file: $e');
  }
}
```

## Giao Diện Người Dùng

### 1. Assignment List Page
- Nút download (📥) trong AppBar để export tất cả bài tập
- Xuất file với tên: `all_assignments_YYYY-MM-DDTHH-mm-ss.csv`

### 2. Assignment Tracking Page  
- Nút download (📥) trong AppBar để export tracking data
- Xuất file với tên: `assignment_tracking_{assignmentId}_YYYY-MM-DDTHH-mm-ss.csv`

## Lưu Ý Kỹ Thuật

### 1. Response Type
- API sử dụng `ResponseType.bytes` để trả về dữ liệu CSV dưới dạng binary
- Flutter nhận dữ liệu dưới dạng `List<int>` (bytes)

### 2. File Encoding
- File CSV được encode với UTF-8 và có BOM để tương thích với Excel
- Tên file có timestamp để tránh trùng lặp

### 3. Error Handling
- Luôn đóng loading dialog trước khi xử lý kết quả
- Kiểm tra null và empty data trước khi lưu file
- Hiển thị thông báo lỗi rõ ràng cho người dùng

### 4. File Storage
- File được lưu trong thư mục Documents của ứng dụng
- Đường dẫn file được hiển thị trong thông báo thành công

## Ví Dụ Sử Dụng

1. **Export tracking cho bài tập cụ thể:**
   - Vào Assignment Detail → Tracking
   - Bấm nút download trong AppBar
   - File sẽ được lưu với thông tin chi tiết của tất cả sinh viên

2. **Export tất cả bài tập:**
   - Vào Assignment List
   - Bấm nút download trong AppBar  
   - File sẽ chứa danh sách tất cả bài tập với thống kê

## Troubleshooting

### Loading không tắt
- Kiểm tra xem có đóng dialog sau khi nhận response không
- Đảm bảo `Get.isDialogOpen == true` trước khi gọi `Get.back()`

### File không được tạo
- Kiểm tra quyền truy cập thư mục Documents
- Đảm bảo `csvBytes` không null và không empty
- Kiểm tra đường dẫn file có hợp lệ không

### Dữ liệu không đúng
- Kiểm tra API endpoint có trả về đúng format CSV không
- Đảm bảo ResponseType được set là `ResponseType.bytes`
- Kiểm tra encoding UTF-8 với BOM
