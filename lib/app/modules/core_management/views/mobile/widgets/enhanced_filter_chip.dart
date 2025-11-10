import 'package:flutter/material.dart';

class FilterItem {
  final String id;
  final String label;

  const FilterItem({
    required this.id,
    required this.label,
  });
}

class EnhancedFilterChip extends StatefulWidget {
  final List<FilterItem> items;
  final String? selectedId;
  final Function(String?) onChanged;

  const EnhancedFilterChip({
    Key? key,
    required this.items,
    required this.selectedId,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<EnhancedFilterChip> createState() => _EnhancedFilterChipState();
}

class _EnhancedFilterChipState extends State<EnhancedFilterChip>
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final isSelected = widget.selectedId == item.id;

          return GestureDetector(
            onTapDown: (_) {
              _animationController.forward();
            },
            onTapUp: (_) {
              _animationController.reverse();
              widget.onChanged(isSelected ? null : item.id);
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
                    margin: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[700],
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        widget.onChanged(selected ? item.id : null);
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: Theme.of(context).colorScheme.primary,
                      checkmarkColor: Colors.white,
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: isSelected ? 4 : 0,
                      shadowColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
