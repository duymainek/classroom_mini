import 'package:classroom_mini/app/modules/core_management/controllers/core_management_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'widgets/enhanced_app_bar.dart';
import 'widgets/enhanced_tab_bar.dart';
import 'widgets/enhanced_semester_content.dart';
import 'widgets/enhanced_course_content.dart';
import 'widgets/enhanced_group_content.dart';
import 'widgets/enhanced_fab.dart';
import 'widgets/enhanced_create_semester_sheet.dart';
import 'widgets/enhanced_create_course_sheet.dart';
import 'widgets/enhanced_create_group_sheet.dart';

class EnhancedCoreManagementPage extends StatefulWidget {
  const EnhancedCoreManagementPage({Key? key}) : super(key: key);

  @override
  State<EnhancedCoreManagementPage> createState() =>
      _EnhancedCoreManagementPageState();
}

class _EnhancedCoreManagementPageState extends State<EnhancedCoreManagementPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final tabName = _tabNameForIndex(_tabController.index);
      final controller = Get.find<CoreManagementController>();
      if (controller.currentTab != tabName) {
        controller.setCurrentTab(tabName);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CoreManagementController>(
      builder: (controller) => Scaffold(
        key: ValueKey(controller.currentTab),
        appBar: const EnhancedAppBar(),
        body: Column(
          children: [
            // Tab Bar
            EnhancedTabBar(
              tabController: _tabController,
              onTabChanged: (index) =>
                  controller.setCurrentTab(_tabNameForIndex(index)),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  EnhancedSemesterContent(controller: controller),
                  EnhancedCourseContent(controller: controller),
                  EnhancedGroupContent(controller: controller),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: EnhancedFAB(
          currentTab: controller.currentTab,
          onSemesterCreate: () =>
              _showCreateSemesterDialog(context, controller),
          onCourseCreate: () => _showCreateCourseDialog(context, controller),
          onGroupCreate: () => _showCreateGroupDialog(context, controller),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = Get.find<CoreManagementController>();
    final desiredIndex = _tabIndexForName(controller.currentTab);
    if (_tabController.index != desiredIndex) {
      _tabController.index = desiredIndex;
    }
  }

  int _tabIndexForName(String name) {
    switch (name) {
      case 'semesters':
        return 0;
      case 'courses':
        return 1;
      case 'groups':
        return 2;
      default:
        return 0;
    }
  }

  String _tabNameForIndex(int index) {
    switch (index) {
      case 0:
        return 'semesters';
      case 1:
        return 'courses';
      case 2:
        return 'groups';
      default:
        return 'semesters';
    }
  }

  void _showCreateSemesterDialog(
      BuildContext context, CoreManagementController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => EnhancedCreateSemesterSheet(
        onSubmit: (code, name, isActive) {
          controller.createSemester(code, name);
        },
      ),
    );
  }

  void _showCreateCourseDialog(
      BuildContext context, CoreManagementController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => EnhancedCreateCourseSheet(
        semesters: controller.semesters,
        onSubmit: (code, name, sessionCount, semesterId, isActive) {
          controller.createCourse(code, name, sessionCount, semesterId);
        },
      ),
    );
  }

  void _showCreateGroupDialog(
      BuildContext context, CoreManagementController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) => EnhancedCreateGroupSheet(
        courses: controller.courses,
        onSubmit: (name, courseId, isActive) {
          controller.createGroup(name, courseId);
        },
      ),
    );
  }
}
