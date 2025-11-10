import 'package:classroom_mini/app/core/utils/responsive_view_factory.dart';
import 'package:flutter/material.dart';
import 'package:classroom_mini/app/data/models/response/quiz_response.dart';
import '../mobile/quiz_detail_view.dart' as mobile_pages;

class ResponsiveQuizDetailPage extends StatelessWidget {
  final Quiz quiz;

  const ResponsiveQuizDetailPage({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    return ResponsiveViewFactory.createResponsiveView(
      mobile: mobile_pages.MobileQuizDetailView(quiz: quiz),
      tablet: mobile_pages.MobileQuizDetailView(quiz: quiz),
      desktop: mobile_pages.MobileQuizDetailView(quiz: quiz),
      fourK: mobile_pages.MobileQuizDetailView(quiz: quiz),
    );
  }
}

