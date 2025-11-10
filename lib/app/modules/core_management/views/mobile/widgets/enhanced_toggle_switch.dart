import 'package:flutter/material.dart';

class EnhancedToggleSwitch extends StatelessWidget {
  final String label;
  final String description;
  final bool value;
  final Function(bool) onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final IconData? activeIcon;
  final IconData? inactiveIcon;

  const EnhancedToggleSwitch({
    Key? key,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.activeIcon,
    this.inactiveIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActive = value;
    final activeColorValue = activeColor ?? Colors.green;
    final inactiveColorValue = inactiveColor ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive
            ? activeColorValue.withValues(alpha: 0.1)
            : inactiveColorValue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? activeColorValue.withValues(alpha: 0.3)
              : inactiveColorValue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isActive
                ? (activeIcon ?? Icons.check_circle)
                : (inactiveIcon ?? Icons.cancel),
            color: isActive ? activeColorValue : inactiveColorValue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: isActive ? activeColorValue : inactiveColorValue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive
                        ? activeColorValue.withValues(alpha: 0.7)
                        : inactiveColorValue.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: onChanged,
            activeThumbColor: activeColorValue,
            inactiveThumbColor: inactiveColorValue,
            inactiveTrackColor: inactiveColorValue.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
