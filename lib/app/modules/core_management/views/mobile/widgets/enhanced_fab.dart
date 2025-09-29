import 'package:flutter/material.dart';

class EnhancedFAB extends StatefulWidget {
  final String currentTab;
  final VoidCallback onSemesterCreate;
  final VoidCallback onCourseCreate;
  final VoidCallback onGroupCreate;

  const EnhancedFAB({
    Key? key,
    required this.currentTab,
    required this.onSemesterCreate,
    required this.onCourseCreate,
    required this.onGroupCreate,
  }) : super(key: key);

  @override
  State<EnhancedFAB> createState() => _EnhancedFABState();
}

class _EnhancedFABState extends State<EnhancedFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    switch (widget.currentTab) {
      case 'semesters':
        widget.onSemesterCreate();
        break;
      case 'courses':
        widget.onCourseCreate();
        break;
      case 'groups':
        widget.onGroupCreate();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: _onTap,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.add),
            label: Text(_getLabel()),
          ),
        );
      },
    );
  }

  String _getLabel() {
    switch (widget.currentTab) {
      case 'semesters':
        return 'Thêm học kỳ';
      case 'courses':
        return 'Thêm khóa học';
      case 'groups':
        return 'Thêm nhóm';
      default:
        return 'Thêm mới';
    }
  }
}
