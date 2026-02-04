import 'package:flutter/foundation.dart';

class PlvLogger {
  static const bool _verbose = bool.fromEnvironment(
    'PLV_VERBOSE_LOG',
    defaultValue: false,
  );

  static void d(String message) {
    if (kDebugMode && _verbose) {
      debugPrint(message);
    }
  }

  static void w(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void e(String message) {
    if (!kReleaseMode) {
      debugPrint(message);
    }
  }
}
