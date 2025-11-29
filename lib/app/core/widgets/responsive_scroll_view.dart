import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class ResponsiveScrollView extends StatelessWidget {
  final List<Widget> slivers;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool reverse;
  final double? cacheExtent;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final String? restorationId;
  final Clip clipBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final double? maxWidth;

  const ResponsiveScrollView({
    super.key,
    required this.slivers,
    this.controller,
    this.physics,
    this.reverse = false,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final effectiveMaxWidth = maxWidth ?? _getDefaultMaxWidth(width);

        if (width > effectiveMaxWidth) {
          final horizontalPadding = (width - effectiveMaxWidth) / 2;
          return CustomScrollView(
            controller: controller,
            physics: physics,
            reverse: reverse,
            cacheExtent: cacheExtent,
            semanticChildCount: semanticChildCount,
            dragStartBehavior: dragStartBehavior,
            restorationId: restorationId,
            clipBehavior: clipBehavior,
            keyboardDismissBehavior: keyboardDismissBehavior,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 0) {
                        return _buildAppBarWrapper(context, slivers.first);
                      }
                      return slivers[index];
                    },
                    childCount: slivers.length,
                  ),
                ),
              ),
            ],
          );
        }

        return CustomScrollView(
          controller: controller,
          physics: physics,
          reverse: reverse,
          cacheExtent: cacheExtent,
          semanticChildCount: semanticChildCount,
          dragStartBehavior: dragStartBehavior,
          restorationId: restorationId,
          clipBehavior: clipBehavior,
          keyboardDismissBehavior: keyboardDismissBehavior,
          slivers: slivers,
        );
      },
    );
  }

  Widget _buildAppBarWrapper(BuildContext context, Widget appBar) {
    if (appBar is SliverAppBar) {
      return SliverAppBar(
        title: appBar.title,
        actions: appBar.actions,
        leading: appBar.leading,
        automaticallyImplyLeading: appBar.automaticallyImplyLeading,
        bottom: appBar.bottom,
        elevation: appBar.elevation,
        backgroundColor: appBar.backgroundColor,
        foregroundColor: appBar.foregroundColor,
        surfaceTintColor: appBar.surfaceTintColor,
        iconTheme: appBar.iconTheme,
        actionsIconTheme: appBar.actionsIconTheme,
        centerTitle: appBar.centerTitle,
        titleSpacing: appBar.titleSpacing,
        expandedHeight: appBar.expandedHeight,
        floating: appBar.floating,
        pinned: appBar.pinned,
        snap: appBar.snap,
        leadingWidth: appBar.leadingWidth,
        primary: appBar.primary,
        flexibleSpace: appBar.flexibleSpace,
        toolbarHeight: appBar.toolbarHeight,
      );
    }
    return appBar;
  }

  double _getDefaultMaxWidth(double screenWidth) {
    if (screenWidth < 768) {
      return double.infinity;
    } else if (screenWidth < 1024) {
      return 900;
    } else {
      return 1200;
    }
  }
}
