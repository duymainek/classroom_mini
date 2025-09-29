import 'package:get/get.dart';
import 'bindings/quiz_binding.dart';

class QuizModule {
  static void init() {
    QuizBinding().dependencies();
  }
}
