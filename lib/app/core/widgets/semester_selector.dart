import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app_config.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';

/**
 * Widget để chọn học kì với giao diện hiện đại
 * Hiển thị dropdown compact với danh sách học kì và cập nhật AppConfig khi chọn
 */
class SemesterSelector extends StatelessWidget {
  final List<SemesterOption> semesters;
  final String? currentSemesterId;
  final Function(String semesterId, String semesterName, String semesterCode)?
      onSemesterChanged;
  final bool isCompact;

  const SemesterSelector({
    super.key,
    required this.semesters,
    this.currentSemesterId,
    this.onSemesterChanged,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sử dụng Dashboard controller để theo dõi reactive state
    final dashboardController = Get.find<DashboardController>();

    final selectedId = currentSemesterId ??
        dashboardController.currentSemester.value?.id ??
        '';

    final selectedSemester = semesters.firstWhereOrNull(
      (s) => s.id == selectedId,
    );

    if (isCompact) {
      return _buildCompactSelector(
          context, selectedSemester, dashboardController);
    }

    return _buildFullSelector(context, selectedSemester, dashboardController);
  }

  Widget _buildCompactSelector(
    BuildContext context,
    SemesterOption? selectedSemester,
    DashboardController dashboardController,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showSemesterPicker(
              context, selectedSemester, dashboardController),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.school,
                  size: 20,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedSemester?.name ?? 'Chọn học kì',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selectedSemester != null
                        ? Colors.grey.shade800
                        : Colors.grey.shade500,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullSelector(
    BuildContext context,
    SemesterOption? selectedSemester,
    DashboardController dashboardController,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSemester?.id,
          isExpanded: true,
          icon: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey.shade600,
            ),
          ),
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  size: 20,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Chọn học kì',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          items: semesters.map((semester) {
            return DropdownMenuItem<String>(
              value: semester.id,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 18,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            semester.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            semester.code,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              _handleSemesterChange(newValue, dashboardController);
            }
          },
        ),
      ),
    );
  }

  void _showSemesterPicker(
    BuildContext context,
    SemesterOption? selectedSemester,
    DashboardController dashboardController,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.school,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Chọn học kì',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: semesters.length,
                itemBuilder: (context, index) {
                  final semester = semesters[index];
                  final isSelected = selectedSemester?.id == semester.id;

                  return ListTile(
                    leading: Icon(
                      Icons.school,
                      color: isSelected
                          ? Colors.blue.shade600
                          : Colors.grey.shade600,
                    ),
                    title: Text(
                      semester.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Colors.blue.shade600
                            : Colors.grey.shade800,
                      ),
                    ),
                    subtitle: Text(
                      semester.code,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.blue.shade500
                            : Colors.grey.shade600,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: Colors.blue.shade600,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      _handleSemesterChange(semester.id, dashboardController);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSemesterChange(
      String semesterId, DashboardController dashboardController) {
    final selectedSemester = semesters.firstWhere(
      (s) => s.id == semesterId,
      orElse: () => semesters.first,
    );

    // Cập nhật Dashboard controller và AppConfig
    dashboardController.switchSemester(selectedSemester.id);
    AppConfig.instance.setSelectedSemester(
      semesterId: selectedSemester.id,
      semesterName: selectedSemester.name,
      semesterCode: selectedSemester.code,
    );

    // Gọi callback nếu có
    onSemesterChanged?.call(
      selectedSemester.id,
      selectedSemester.name,
      selectedSemester.code,
    );
  }
}

/**
 * Model cho option học kì
 */
class SemesterOption {
  final String id;
  final String name;
  final String code;

  const SemesterOption({
    required this.id,
    required this.name,
    required this.code,
  });
}
