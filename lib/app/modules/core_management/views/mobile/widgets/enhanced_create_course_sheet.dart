import 'package:classroom_mini/app/data/models/response/semester_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class EnhancedCreateCourseSheet extends StatefulWidget {
  final List<Semester> semesters;
  final Function(String code, String name, int sessionCount, String semesterId,
      bool isActive) onSubmit;

  const EnhancedCreateCourseSheet({
    Key? key,
    required this.semesters,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<EnhancedCreateCourseSheet> createState() =>
      _EnhancedCreateCourseSheetState();
}

class _EnhancedCreateCourseSheetState
    extends State<EnhancedCreateCourseSheet> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  int _sessionCount = 10;
  String? _selectedSemesterId;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, _slideAnimation.value * MediaQuery.of(context).size.height),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildForm()),
                  _buildActions(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thêm khóa học mới',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tạo khóa học mới trong học kỳ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Đóng',
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            _buildCourseSettingsSection(),
            const SizedBox(height: 24),
            _buildStatusSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Thông tin cơ bản',
      icon: Icons.info_outline,
      children: [
        _buildTextField(
          controller: _codeController,
          label: 'Mã khóa học',
          hint: 'Ví dụ: CS101',
          icon: Icons.tag,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập mã khóa học';
            }
            if (value.trim().length < 2) {
              return 'Mã khóa học phải có ít nhất 2 ký tự';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _nameController,
          label: 'Tên khóa học',
          hint: 'Ví dụ: Lập trình cơ bản',
          icon: Icons.text_fields,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vui lòng nhập tên khóa học';
            }
            if (value.trim().length < 2) {
              return 'Tên khóa học phải có ít nhất 2 ký tự';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildDropdownField(),
      ],
    );
  }

  Widget _buildCourseSettingsSection() {
    return _buildSection(
      title: 'Cài đặt khóa học',
      icon: Icons.settings_outlined,
      children: [
        _buildSessionCountField(),
      ],
    );
  }

  Widget _buildStatusSection() {
    return _buildSection(
      title: 'Trạng thái',
      icon: Icons.toggle_on,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isActive ? Colors.green.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isActive ? Colors.green.shade200 : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _isActive
                      ? Colors.green.shade100
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isActive ? Icons.check_circle : Icons.cancel,
                  color: _isActive ? Colors.green.shade700 : Colors.grey.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isActive ? 'Đang hoạt động' : 'Không hoạt động',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: _isActive
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isActive
                          ? 'Khóa học này sẽ được sử dụng ngay'
                          : 'Khóa học này sẽ bị vô hiệu hóa',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isActive
                            ? Colors.green.shade600
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                  HapticFeedback.selectionClick();
                },
                activeColor: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    final activeSemesters = widget.semesters.where((s) => s.isActive).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Học kỳ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedSemesterId,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
            ),
            hintText: 'Chọn học kỳ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: activeSemesters.map((semester) {
            return DropdownMenuItem(
              value: semester.id,
              child: Text('${semester.code} - ${semester.name}'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSemesterId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng chọn học kỳ';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSessionCountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số buổi học',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _sessionCount,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.event_available,
              color: Theme.of(context).colorScheme.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: const [
            DropdownMenuItem(value: 10, child: Text('10 buổi')),
            DropdownMenuItem(value: 15, child: Text('15 buổi')),
            DropdownMenuItem(value: 20, child: Text('20 buổi')),
            DropdownMenuItem(value: 30, child: Text('30 buổi')),
          ],
          onChanged: (value) {
            setState(() {
              _sessionCount = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'Hủy',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Tạo khóa học',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      widget.onSubmit(
        _codeController.text.trim(),
        _nameController.text.trim(),
        _sessionCount,
        _selectedSemesterId!,
        _isActive,
      );
      Get.back();
    }
  }
}

