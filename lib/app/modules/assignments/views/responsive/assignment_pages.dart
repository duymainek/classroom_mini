import 'package:classroom_mini/app/core/utils/responsive_view_factory.dart';
import 'package:flutter/material.dart';
import 'package:classroom_mini/app/data/models/response/assignment_response.dart';
import '../mobile/responsive_assignment_pages.dart' as mobile_pages;

class ResponsiveAssignmentCreatePage extends StatelessWidget {
  const ResponsiveAssignmentCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveViewFactory.createResponsiveView(
      mobile: const mobile_pages.AssignmentCreatePage(),
      tablet: const mobile_pages.AssignmentCreatePage(),
      desktop: const mobile_pages.AssignmentCreatePage(),
      fourK: const mobile_pages.AssignmentCreatePage(),
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
      tablet: mobile_pages.AssignmentEditPage(assignment: assignment),
      desktop: mobile_pages.AssignmentEditPage(assignment: assignment),
      fourK: mobile_pages.AssignmentEditPage(assignment: assignment),
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
      tablet: mobile_pages.AssignmentDetailPage(assignment: assignment),
      desktop: mobile_pages.AssignmentDetailPage(assignment: assignment),
      fourK: mobile_pages.AssignmentDetailPage(assignment: assignment),
    );
  }
}
