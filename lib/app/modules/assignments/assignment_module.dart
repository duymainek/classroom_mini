import 'bindings/assignment_binding.dart';

class AssignmentModule {
  static void init() {
    // Register bindings only; routes are centralized in AppPages
    AssignmentBinding().dependencies();
  }
}
