import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quiz_controller.dart';

class QuizListView extends GetView<QuizController> {
  const QuizListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz List'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Quiz List View is under construction',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
