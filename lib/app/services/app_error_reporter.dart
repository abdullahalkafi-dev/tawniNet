import 'package:flutter/foundation.dart';

/// Single place where uncaught errors end up.
///
/// Debug: printed to the console. Release: kept in [recent] and handed to
/// [sink] — set it to a crash-reporting SDK (Firebase Crashlytics, Sentry) once
/// the project has one:
///
/// ```dart
/// AppErrorReporter.sink = (e, s, source) => FirebaseCrashlytics.instance.recordError(e, s);
/// ```
class AppErrorReporter {
  AppErrorReporter._();

  static void Function(Object error, StackTrace? stack, String source)? sink;

  /// The last few errors (for a "report a problem" screen / diagnostics).
  static final List<String> recent = [];

  static void report(Object error, StackTrace? stack, {String source = 'app'}) {
    if (kDebugMode) {
      debugPrint('[$source] $error');
      if (stack != null) debugPrint(stack.toString());
    }
    recent.add('${DateTime.now().toIso8601String()} [$source] $error');
    if (recent.length > 20) recent.removeAt(0);
    try {
      sink?.call(error, stack, source);
    } catch (_) {}
  }
}
