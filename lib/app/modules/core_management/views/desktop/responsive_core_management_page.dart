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
            // Left sidebar for navigation
            Container(
              width: 300,
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
                  const Spacer(),
                  // Statistics panel
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thống kê',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Học kỳ: ${controller.semesters.length}'),
                        Text('Khóa học: ${controller.courses.length}'),
                        Text('Nhóm: ${controller.groups.length}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Main content area
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
        leading: Icon(icon, size: 24),
        title: Text(title, style: const TextStyle(fontSize: 16)),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý Học kỳ',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateSemesterDialog(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Học kỳ'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search and filters
          Row(
            children: [
              SizedBox(
                width: 400,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm học kỳ...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: controller.setSemesterSearch,
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => controller.loadSemesters(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Semester grid
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.semesters.isEmpty
                    ? const Center(child: Text('Không có học kỳ nào'))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: controller.semesters.length,
                        itemBuilder: (context, index) {
                          final semester = controller.semesters[index];
                          return Card(
                            elevation: 2,
                            child: InkWell(
                              onTap: () => _showEditSemesterDialog(
                                  context, controller, semester),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: semester.isActive
                                              ? Colors.green
                                              : Colors.grey,
                                          child: Text(
                                            semester.code.substring(0, 1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            semester.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        PopupMenuButton(
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.edit),
                                                  SizedBox(width: 8),
                                                  Text('Chỉnh sửa'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.delete),
                                                  SizedBox(width: 8),
                                                  Text('Xóa'),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showEditSemesterDialog(context,
                                                  controller, semester);
                                            } else if (value == 'delete') {
                                              _showDeleteSemesterDialog(context,
                                                  controller, semester);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Mã: ${semester.code}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          semester.isActive
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 16,
                                          color: semester.isActive
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          semester.isActive
                                              ? 'Hoạt động'
                                              : 'Không hoạt động',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: semester.isActive
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý Khóa học',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateCourseDialog(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Khóa học'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search and filters
          Row(
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm khóa học...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: controller.setCourseSearch,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Học kỳ',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => controller.loadCourses(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Course grid
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.courses.isEmpty
                    ? const Center(child: Text('Không có khóa học nào'))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: controller.courses.length,
                        itemBuilder: (context, index) {
                          final course = controller.courses[index];
                          return Card(
                            elevation: 2,
                            child: InkWell(
                              onTap: () => _showEditCourseDialog(
                                  context, controller, course),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: course.isActive
                                              ? Colors.blue
                                              : Colors.grey,
                                          child: Text(
                                            course.code.substring(0, 1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            course.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        PopupMenuButton(
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.edit),
                                                  SizedBox(width: 8),
                                                  Text('Chỉnh sửa'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.delete),
                                                  SizedBox(width: 8),
                                                  Text('Xóa'),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showEditCourseDialog(
                                                  context, controller, course);
                                            } else if (value == 'delete') {
                                              _showDeleteCourseDialog(
                                                  context, controller, course);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Mã: ${course.code}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${course.sessionCount} buổi học',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          course.isActive
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 16,
                                          color: course.isActive
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          course.isActive
                                              ? 'Hoạt động'
                                              : 'Không hoạt động',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: course.isActive
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý Nhóm',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateGroupDialog(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Thêm Nhóm'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Search and filters
          Row(
            children: [
              SizedBox(
                width: 300,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm nhóm...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: controller.setGroupSearch,
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 250,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Khóa học',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => controller.loadGroups(refresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Group grid
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.groups.isEmpty
                    ? const Center(child: Text('Không có nhóm nào'))
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: controller.groups.length,
                        itemBuilder: (context, index) {
                          final group = controller.groups[index];
                          return Card(
                            elevation: 2,
                            child: InkWell(
                              onTap: () => _showEditGroupDialog(
                                  context, controller, group),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: group.isActive
                                              ? Colors.orange
                                              : Colors.grey,
                                          child: Text(
                                            group.name.substring(0, 1),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            group.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        PopupMenuButton(
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.edit),
                                                  SizedBox(width: 8),
                                                  Text('Chỉnh sửa'),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.delete),
                                                  SizedBox(width: 8),
                                                  Text('Xóa'),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _showEditGroupDialog(
                                                  context, controller, group);
                                            } else if (value == 'delete') {
                                              _showDeleteGroupDialog(
                                                  context, controller, group);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Khóa học: ${group.courseBrief?.name ?? 'N/A'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          group.isActive
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 16,
                                          color: group.isActive
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          group.isActive
                                              ? 'Hoạt động'
                                              : 'Không hoạt động',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: group.isActive
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  // Dialog methods (same as web version)
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
