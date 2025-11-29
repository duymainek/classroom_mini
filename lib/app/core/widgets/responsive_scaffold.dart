import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  const ResponsiveScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.endDrawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 1024;
        final isTablet = width >= 768 && width < 1024;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: appBar,
          drawer: drawer,
          endDrawer: endDrawer,
          resizeToAvoidBottomInset: resizeToAvoidBottomInset,
          body: _buildResponsiveBody(context, width, isDesktop, isTablet),
          bottomNavigationBar: bottomNavigationBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
        );
      },
    );
  }

  Widget _buildResponsiveBody(
    BuildContext context,
    double width,
    bool isDesktop,
    bool isTablet,
  ) {
    if (isDesktop || isTablet) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 1200 : 900,
          ),
          child: body,
        ),
      );
    }
    return body;
  }
}

