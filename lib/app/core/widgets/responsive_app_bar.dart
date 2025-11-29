import 'package:flutter/material.dart';

class ResponsiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? surfaceTintColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final bool? centerTitle;
  final double titleSpacing;
  final double toolbarHeight;
  final double? leadingWidth;
  final bool primary;
  final FlexibleSpaceBar? flexibleSpace;

  const ResponsiveAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.surfaceTintColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.centerTitle,
    this.titleSpacing = NavigationToolbar.kMiddleSpacing,
    this.toolbarHeight = kToolbarHeight,
    this.leadingWidth,
    this.primary = true,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final effectiveMaxWidth = _getDefaultMaxWidth(width);

        Widget appBarContent = AppBar(
          title: title,
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          bottom: bottom,
          elevation: elevation,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          surfaceTintColor: surfaceTintColor,
          iconTheme: iconTheme,
          actionsIconTheme: actionsIconTheme,
          centerTitle: centerTitle,
          titleSpacing: titleSpacing,
          toolbarHeight: toolbarHeight,
          leadingWidth: leadingWidth,
          primary: primary,
          flexibleSpace: flexibleSpace,
        );

        if (width > effectiveMaxWidth) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
              child: appBarContent,
            ),
          );
        }

        return appBarContent;
      },
    );
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

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}

class ResponsiveSliverAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? surfaceTintColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final bool? centerTitle;
  final double titleSpacing;
  final double? expandedHeight;
  final bool floating;
  final bool pinned;
  final bool snap;
  final double? leadingWidth;
  final bool primary;
  final FlexibleSpaceBar? flexibleSpace;
  final double toolbarHeight;

  const ResponsiveSliverAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.surfaceTintColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.centerTitle,
    this.titleSpacing = NavigationToolbar.kMiddleSpacing,
    this.expandedHeight,
    this.floating = false,
    this.pinned = false,
    this.snap = false,
    this.leadingWidth,
    this.primary = true,
    this.flexibleSpace,
    this.toolbarHeight = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final effectiveMaxWidth = _getDefaultMaxWidth(width);

        Widget sliverAppBar = SliverAppBar(
          title: title,
          actions: actions,
          leading: leading,
          automaticallyImplyLeading: automaticallyImplyLeading,
          bottom: bottom,
          elevation: elevation,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          surfaceTintColor: surfaceTintColor,
          iconTheme: iconTheme,
          actionsIconTheme: actionsIconTheme,
          centerTitle: centerTitle,
          titleSpacing: titleSpacing,
          expandedHeight: expandedHeight,
          floating: floating,
          pinned: pinned,
          snap: snap,
          leadingWidth: leadingWidth,
          primary: primary,
          flexibleSpace: flexibleSpace != null
              ? FlexibleSpaceBar(
                  title: flexibleSpace!.title,
                  background: flexibleSpace!.background,
                  centerTitle: flexibleSpace!.centerTitle,
                  titlePadding: flexibleSpace!.titlePadding,
                  collapseMode: flexibleSpace!.collapseMode,
                  stretchModes: flexibleSpace!.stretchModes,
                )
              : null,
          toolbarHeight: toolbarHeight,
        );

        if (width > effectiveMaxWidth) {
          final horizontalPadding = (width - effectiveMaxWidth) / 2;
          return SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            sliver: sliverAppBar,
          );
        }

        return sliverAppBar;
      },
    );
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
