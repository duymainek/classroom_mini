import 'package:classroom_mini/app/core/utils/responsive_view_factory.dart';
import 'package:flutter/material.dart';
import 'mobile/responsive_dashboard_page.dart' as mobile;

class ResponsiveDashboardPage extends StatelessWidget {
  const ResponsiveDashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveViewFactory.createResponsiveView(
      mobile: const mobile.ResponsiveDashboardPage(),
      tablet: Container(),
      desktop: Container(),
      fourK: Container(),
    );
  }
}
