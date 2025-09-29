import 'dart:developer' as developer;

class AppLogger {
  static const String _name = 'ClassroomMini';

  static void info(String message, {String? tag}) {
    developer.log(
      message,
      name: _name,
      level: 800, // Info level
      time: DateTime.now(),
    );
  }

  static void error(String message,
      {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      message,
      name: _name,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
  }

  static void debug(String message, {String? tag}) {
    developer.log(
      message,
      name: _name,
      level: 700, // Debug level
      time: DateTime.now(),
    );
  }

  static void warning(String message, {String? tag}) {
    developer.log(
      message,
      name: _name,
      level: 900, // Warning level
      time: DateTime.now(),
    );
  }
}
