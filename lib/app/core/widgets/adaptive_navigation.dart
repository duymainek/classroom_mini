import 'package:flutter/material.dart';

class AdaptiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavDestination> destinations;
  final Widget child;

  const AdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1024;
        final isTablet = width >= 768 && width < 1024;

        if (isDesktop) {
          return Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.selected,
                destinations: destinations
                    .map((dest) => NavigationRailDestination(
                          icon: dest.icon,
                          selectedIcon: dest.selectedIcon ?? dest.icon,
                          label: Text(dest.label),
                        ))
                    .toList(),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: child),
            ],
          );
        } else if (isTablet) {
          return Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.none,
                destinations: destinations
                    .map((dest) => NavigationRailDestination(
                          icon: dest.icon,
                          selectedIcon: dest.selectedIcon ?? dest.icon,
                          label: Text(dest.label),
                        ))
                    .toList(),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: child),
            ],
          );
        } else {
          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations
                  .map((dest) => NavigationDestination(
                        icon: dest.icon,
                        selectedIcon: dest.selectedIcon ?? dest.icon,
                        label: dest.label,
                        tooltip: dest.tooltip,
                      ))
                  .toList(),
            ),
          );
        }
      },
    );
  }
}

class NavDestination {
  final Widget icon;
  final Widget? selectedIcon;
  final String label;
  final String? tooltip;

  const NavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
  });
}
