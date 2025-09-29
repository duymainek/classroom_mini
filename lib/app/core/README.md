# Core Module - App Configuration & Semester Management

Module này cung cấp các tính năng quản lý cấu hình toàn cục của ứng dụng, đặc biệt là quản lý học kì đang được chọn.

## Các thành phần chính

### 1. AppConfig
- **File**: `app_config.dart`
- **Mục đích**: Quản lý trạng thái toàn cục của ứng dụng, đặc biệt là thông tin học kì đang được chọn
- **Tính năng**:
  - Lưu trữ thông tin học kì hiện tại (ID, tên, mã)
  - Reactive state management với GetX
  - Các method để thiết lập và xóa lựa chọn học kì

### 2. SemesterHelper
- **File**: `utils/semester_helper.dart`
- **Mục đích**: Utility class cung cấp các helper methods để làm việc với thông tin học kì
- **Tính năng**:
  - Kiểm tra xem có học kì nào được chọn không
  - Lấy thông tin học kì hiện tại
  - Hiển thị thông báo nếu chưa chọn học kì
  - Reactive streams cho UI

### 3. SemesterSelector
- **File**: `widgets/semester_selector.dart`
- **Mục đích**: Widget UI để chọn học kì
- **Tính năng**:
  - Dropdown để chọn học kì
  - Tự động cập nhật AppConfig khi chọn
  - Validation và error handling

### 4. AppBinding
- **File**: `app_binding.dart`
- **Mục đích**: Khởi tạo các dependencies toàn cục
- **Tính năng**:
  - Khởi tạo AppConfig như singleton
  - Được gọi trong main.dart

## Cách sử dụng

### 1. Khởi tạo trong main.dart
```dart
import 'package:classroom_mini/app/core/app_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo AppConfig và các dependencies toàn cục
  AppBinding().dependencies();
  
  // ... rest of your code
}
```

### 2. Sử dụng trong Controller
```dart
import 'package:classroom_mini/app/core/utils/semester_helper.dart';

class MyController extends GetxController {
  Future<void> loadData() async {
    // Kiểm tra xem có học kì được chọn không
    if (!SemesterHelper.checkSemesterSelected()) {
      return;
    }
    
    // Lấy semesterId để gọi API
    final semesterId = SemesterHelper.getCurrentSemesterId();
    
    // Gọi API với semesterId
    final response = await apiService.getData(semesterId: semesterId);
  }
}
```

### 3. Sử dụng trong UI
```dart
import 'package:classroom_mini/app/core/widgets/semester_selector.dart';

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SemesterSelector(
          semesters: semesterList,
          onSemesterChanged: (id, name, code) {
            // Callback khi chọn học kì mới
            print('Selected semester: $name');
          },
        ),
        // ... rest of your UI
      ],
    );
  }
}
```

### 4. Reactive UI với Obx
```dart
import 'package:classroom_mini/app/core/utils/semester_helper.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final semesterName = SemesterHelper.getCurrentSemesterName();
      final isSelected = SemesterHelper.hasSelectedSemester();
      
      return Text(
        isSelected ? 'Học kì: $semesterName' : 'Chưa chọn học kì',
      );
    });
  }
}
```

## Tích hợp với Assignment Controller

AssignmentController đã được cập nhật để tự động sử dụng semesterId từ AppConfig:

1. **loadAssignments()**: Tự động truyền semesterId vào API call
2. **createAssignment()**: Kiểm tra và truyền semesterId khi tạo bài tập mới
3. **StudentAssignmentController**: Cũng được cập nhật tương tự

## API Changes

### AssignmentCreateRequest
- Đã thêm field `semesterId` (required)
- Model đã được cập nhật để hỗ trợ semesterId

### ApiService.getAssignments()
- Đã thêm parameter `semesterId` (optional)
- API sẽ filter assignments theo semesterId nếu được cung cấp

## Lưu ý quan trọng

1. **Luôn kiểm tra semester được chọn**: Sử dụng `SemesterHelper.checkSemesterSelected()` trước khi thực hiện các thao tác cần semesterId

2. **Reactive UI**: Sử dụng `Obx()` để UI tự động cập nhật khi semester thay đổi

3. **Error Handling**: SemesterHelper sẽ tự động hiển thị thông báo nếu chưa chọn học kì

4. **Performance**: AppConfig được khởi tạo như singleton, không cần lo lắng về memory leaks

## Ví dụ hoàn chỉnh

Xem file `widgets/semester_selector_example.dart` để có ví dụ đầy đủ về cách sử dụng tất cả các tính năng.
