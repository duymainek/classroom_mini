import 'package:classroom_mini/app/core/utils/responsive_view_factory.dart';
import 'package:flutter/material.dart';
import 'package:classroom_mini/app/data/models/assignment_model.dart';
import '../web/responsive_assignment_pages.dart' as web_pages;
import '../desktop/responsive_assignment_pages.dart' as desktop_pages;
import '../mobile/responsive_assignment_pages.dart' as mobile_pages;

class ResponsiveAssignmentCreatePage extends StatelessWidget {
  const ResponsiveAssignmentCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveViewFactory.createResponsiveView(
      mobile: const mobile_pages.AssignmentCreatePage(),
      tablet: const desktop_pages.AssignmentCreatePage(),
      desktop: const desktop_pages.AssignmentCreatePage(),
      fourK: const web_pages.AssignmentCreatePage(),
    );
  }
}

class ResponsiveAssignmentEditPage extends StatelessWidget {
  final Assignment assignment;

  const ResponsiveAssignmentEditPage({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return ResponsiveViewFactory.createResponsiveView(
      mobile: mobile_pages.AssignmentEditPage(assignment: assignment),
      tablet: desktop_pages.AssignmentEditPage(assignment: assignment),
      desktop: desktop_pages.AssignmentEditPage(assignment: assignment),
      fourK: web_pages.AssignmentEditPage(assignment: assignment),
    );
  }
}

class ResponsiveAssignmentDetailPage extends StatelessWidget {
  final Assignment assignment;

  const ResponsiveAssignmentDetailPage({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return ResponsiveViewFactory.createResponsiveView(
      mobile: mobile_pages.AssignmentDetailPage(assignment: assignment),
      tablet: desktop_pages.AssignmentDetailPage(assignment: assignment),
      desktop: desktop_pages.AssignmentDetailPage(assignment: assignment),
      fourK: web_pages.AssignmentDetailPage(assignment: assignment),
    );
  }
}
