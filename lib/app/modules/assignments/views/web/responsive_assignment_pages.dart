import 'package:flutter/material.dart';
import 'package:classroom_mini/app/data/models/assignment_model.dart';
import 'assignment_list_view.dart';

class AssignmentCreatePage extends StatelessWidget {
  const AssignmentCreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AssignmentCreateView();
  }
}

class AssignmentEditPage extends StatelessWidget {
  final Assignment assignment;

  const AssignmentEditPage({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return AssignmentEditView(assignment: assignment);
  }
}

class AssignmentDetailPage extends StatelessWidget {
  final Assignment assignment;

  const AssignmentDetailPage({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return AssignmentDetailView(assignment: assignment);
  }
}
