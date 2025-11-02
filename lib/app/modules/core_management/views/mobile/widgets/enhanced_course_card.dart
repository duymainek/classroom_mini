import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:classroom_mini/app/data/services/connectivity_service.dart';

class EnhancedCourseCard extends StatefulWidget {
  final dynamic course;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EnhancedCourseCard({
    Key? key,
    required this.course,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<EnhancedCourseCard> createState() => _EnhancedCourseCardState();
}

class _EnhancedCourseCardState extends State<EnhancedCourseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _animationController.forward();
      },
      onTapUp: (_) {
        _animationController.reverse();
      },
      onTapCancel: () {
        _animationController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.course.isActive
                      ? [
                          Colors.blue.shade50,
                          Colors.blue.shade100,
                        ]
                      : [
                          Colors.grey.shade50,
                          Colors.grey.shade100,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: widget.course.isActive
                      ? Colors.blue.shade200
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // Handle card tap
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Status Icon
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: widget.course.isActive
                                  ? [Colors.blue.shade400, Colors.blue.shade600]
                                  : [
                                      Colors.grey.shade400,
                                      Colors.grey.shade600
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (widget.course.isActive
                                        ? Colors.blue
                                        : Colors.grey)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.course.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mã: ${widget.course.code}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.course.sessionCount} buổi học',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.course.isActive
                                          ? Colors.blue.shade100
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.course.isActive
                                          ? 'Đang hoạt động'
                                          : 'Không hoạt động',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: widget.course.isActive
                                            ? Colors.blue.shade700
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${widget.course.sessionCount} buổi',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Obx(() {
                          final connectivityService = Get.find<ConnectivityService>();
                          if (!connectivityService.isOnline.value) {
                            return const SizedBox.shrink();
                          }
                          return PopupMenuButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: Colors.grey[600],
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Chỉnh sửa'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete,
                                        size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Xóa',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                widget.onEdit();
                              } else if (value == 'delete') {
                                widget.onDelete();
                              }
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
