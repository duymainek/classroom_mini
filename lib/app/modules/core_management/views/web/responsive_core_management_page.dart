import 'package:classroom_mini/app/modules/core_management/controllers/core_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../shared/semester_form_widget.dart';
import '../shared/course_form_widget.dart';
import '../shared/group_form_widget.dart';

class ResponsiveCoreManagementPage extends StatelessWidget {
  const ResponsiveCoreManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CoreManagementController>(
      builder: (controller) => Scaffold(
        appBar: AppBar(
          title: const Text('Quản lý Thực thể Cốt lõi'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Row(
          children: [
            // Sidebar Navigation
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildNavItem(
                    context,
                    'Học kỳ',
                    'semesters',
                    Icons.calendar_today,
                    controller.currentTab == 'semesters',
                    () => controller.setCurrentTab('semesters'),
                  ),
                  _buildNavItem(
                    context,
                    'Khóa học',
                    'courses',
                    Icons.school,
                    controller.currentTab == 'courses',
                    () => controller.setCurrentTab('courses'),
                  ),
                  _buildNavItem(
                    context,
                    'Nhóm',
                    'groups',
                    Icons.group,
                    controller.currentTab == 'groups',
                    () => controller.setCurrentTab('groups'),
                  ),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: _buildMainContent(context, controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    String tab,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        selected: isSelected,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context, CoreManagementController controller) {
    switch (controller.currentTab) {
      case 'semesters':
        return _buildSemesterContent(context, controller);
      case 'courses':
        return _buildCourseContent(context, controller);
      case 'groups':
        return _buildGroupContent(context, controller);
      default:
        return _buildSemesterContent(context, controller);
    }
  }

  Widget _buildSemesterContent(
      BuildContext context, CoreManagementController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý Học kỳ',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateSemesterDialog(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Học kỳ'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar
          SizedBox(
            width: 400,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm học kỳ...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: controller.setSemesterSearch,
            ),
          ),
          const SizedBox(height: 16),
          // Semester list
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.semesters.isEmpty
                    ? const Center(child: Text('Không có học kỳ nào'))
                    : ListView.builder(
                        itemCount: controller.semesters.length,
                        itemBuilder: (context, index) {
                          final semester = controller.semesters[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: semester.isActive
                                    ? Colors.green
                                    : Colors.grey,
                                child: Text(semester.code.substring(0, 1)),
                              ),
                              title: Text(semester.name),
                              subtitle: Text('Mã: ${semester.code}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showEditSemesterDialog(
                                        context, controller, semester),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _showDeleteSemesterDialog(
                                        context, controller, semester),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseContent(
      BuildContext context, CoreManagementController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý Khóa học',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateCourseDialog(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Khóa học'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filters and search
          Row(
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm khóa học...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: controller.setCourseSearch,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Học kỳ',
                    border: OutlineInputBorder(),
                  ),
                  value: controller.selectedSemesterId.isEmpty
                      ? null
                      : controller.selectedSemesterId,
                  items: controller.semesters
                      .where((s) => s.isActive)
                      .map((semester) => DropdownMenuItem(
                            value: semester.id,
                            child: Text('${semester.code} - ${semester.name}'),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      controller.setSelectedSemester(value ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Course list
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.courses.isEmpty
                    ? const Center(child: Text('Không có khóa học nào'))
                    : ListView.builder(
                        itemCount: controller.courses.length,
                        itemBuilder: (context, index) {
                          final course = controller.courses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    course.isActive ? Colors.blue : Colors.grey,
                                child: Text(course.code.substring(0, 1)),
                              ),
                              title: Text(course.name),
                              subtitle: Text(
                                  'Mã: ${course.code} - ${course.sessionCount} buổi'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showEditCourseDialog(
                                        context, controller, course),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _showDeleteCourseDialog(
                                        context, controller, course),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupContent(
      BuildContext context, CoreManagementController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý Nhóm',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateGroupDialog(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Nhóm'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Filters and search
          Row(
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm nhóm...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: controller.setGroupSearch,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Khóa học',
                    border: OutlineInputBorder(),
                  ),
                  value: controller.selectedCourseId.isEmpty
                      ? null
                      : controller.selectedCourseId,
                  items: controller.courses
                      .where((c) => c.isActive)
                      .map((course) => DropdownMenuItem(
                            value: course.id,
                            child: Text('${course.code} - ${course.name}'),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      controller.setSelectedCourse(value ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Group list
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.groups.isEmpty
                    ? const Center(child: Text('Không có nhóm nào'))
                    : ListView.builder(
                        itemCount: controller.groups.length,
                        itemBuilder: (context, index) {
                          final group = controller.groups[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: group.isActive
                                    ? Colors.orange
                                    : Colors.grey,
                                child: Text(group.name.substring(0, 1)),
                              ),
                              title: Text(group.name),
                              subtitle: Text(
                                  'Khóa học: ${group.courseBrief?.name ?? 'N/A'}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _showEditGroupDialog(
                                        context, controller, group),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => _showDeleteGroupDialog(
                                        context, controller, group),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // Dialog methods
  void _showCreateSemesterDialog(
      BuildContext context, CoreManagementController controller) {
    showDialog(
      context: context,
      builder: (context) => SemesterFormWidget(
        title: 'Thêm Học kỳ Mới',
        submitText: 'Tạo',
        onSubmit: (code, name, isActive) {
          controller.createSemester(code, name);
        },
      ),
    );
  }

  void _showEditSemesterDialog(
      BuildContext context, CoreManagementController controller, semester) {
    showDialog(
      context: context,
      builder: (context) => SemesterFormWidget(
        initialCode: semester.code,
        initialName: semester.name,
        initialIsActive: semester.isActive,
        title: 'Chỉnh sửa Học kỳ',
        submitText: 'Cập nhật',
        onSubmit: (code, name, isActive) {
          controller.updateSemester(semester.id, code, name, isActive);
        },
      ),
    );
  }

  void _showDeleteSemesterDialog(
      BuildContext context, CoreManagementController controller, semester) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa học kỳ "${semester.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteSemester(semester.id);
              Get.back();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showCreateCourseDialog(
      BuildContext context, CoreManagementController controller) {
    showDialog(
      context: context,
      builder: (context) => CourseFormWidget(
        semesters: controller.semesters,
        title: 'Thêm Khóa học Mới',
        submitText: 'Tạo',
        onSubmit: (code, name, sessionCount, semesterId, isActive) {
          controller.createCourse(code, name, sessionCount, semesterId);
        },
      ),
    );
  }

  void _showEditCourseDialog(
      BuildContext context, CoreManagementController controller, course) {
    showDialog(
      context: context,
      builder: (context) => CourseFormWidget(
        initialCode: course.code,
        initialName: course.name,
        initialSessionCount: course.sessionCount,
        initialSemesterId: course.semesterId,
        initialIsActive: course.isActive,
        semesters: controller.semesters,
        title: 'Chỉnh sửa Khóa học',
        submitText: 'Cập nhật',
        onSubmit: (code, name, sessionCount, semesterId, isActive) {
          controller.updateCourse(
              course.id, code, name, sessionCount, semesterId, isActive);
        },
      ),
    );
  }

  void _showDeleteCourseDialog(
      BuildContext context, CoreManagementController controller, course) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa khóa học "${course.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteCourse(course.id);
              Get.back();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(
      BuildContext context, CoreManagementController controller) {
    showDialog(
      context: context,
      builder: (context) => GroupFormWidget(
        courses: controller.courses,
        title: 'Thêm Nhóm Mới',
        submitText: 'Tạo',
        onSubmit: (name, courseId, isActive) {
          controller.createGroup(name, courseId);
        },
      ),
    );
  }

  void _showEditGroupDialog(
      BuildContext context, CoreManagementController controller, group) {
    showDialog(
      context: context,
      builder: (context) => GroupFormWidget(
        initialName: group.name,
        initialCourseId: group.courseId,
        initialIsActive: group.isActive,
        courses: controller.courses,
        title: 'Chỉnh sửa Nhóm',
        submitText: 'Cập nhật',
        onSubmit: (name, courseId, isActive) {
          controller.updateGroup(group.id, name, courseId, isActive);
        },
      ),
    );
  }

  void _showDeleteGroupDialog(
      BuildContext context, CoreManagementController controller, group) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa nhóm "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.deleteGroup(group.id);
              Get.back();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
