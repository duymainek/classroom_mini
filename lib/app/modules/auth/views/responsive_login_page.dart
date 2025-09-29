import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'web/responsive_login_page.dart' as web;
import 'mobile/responsive_login_page.dart' as mobile;
import 'desktop/responsive_login_page.dart' as desktop;

class ResponsiveLoginPage extends StatelessWidget {
  const ResponsiveLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use ResponsiveBreakpoints to determine which view to show
    if (ResponsiveBreakpoints.of(context).smallerThan(TABLET)) {
      return const mobile.ResponsiveLoginPage();
    } else if (ResponsiveBreakpoints.of(context).largerThan(DESKTOP)) {
      return const desktop.ResponsiveLoginPage();
    } else {
      return const web.ResponsiveLoginPage();
    }
  }
}
