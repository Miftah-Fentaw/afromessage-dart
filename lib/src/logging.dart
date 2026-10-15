/// How verbose [AfroMessage] request/response logging should be.
enum AfroMessageLogLevel {
  /// No logs.
  off,

  /// Failures only (HTTP errors, API acknowledge errors, validation).
  error,

  /// High-level request lifecycle (method, path, success/failure).
  info,

  /// Includes sanitized payloads and response bodies.
  debug,
}

/// Receives log lines from [AfroMessage].
///
/// Use this to plug into `logger`, `talker`, Firebase Crashlytics, etc.
typedef AfroMessageLogHandler = void Function(
  AfroMessageLogLevel level,
  String message, {
  Object? error,
  StackTrace? stackTrace,
  Map<String, Object?>? context,
});

bool _shouldLog(AfroMessageLogLevel configured, AfroMessageLogLevel message) {
  if (configured == AfroMessageLogLevel.off) return false;
  return message.index <= configured.index;
}

/// Default handler that prints to the console (safe for local debugging).
void defaultAfroMessageLogger(
  AfroMessageLogLevel level,
  String message, {
  Object? error,
  StackTrace? stackTrace,
  Map<String, Object?>? context,
}) {
  final buffer = StringBuffer('[afromessage_dart][${level.name}] $message');
  if (context != null && context.isNotEmpty) {
    buffer.write(' $context');
  }
  // ignore: avoid_print
  print(buffer);
  if (error != null) {
    // ignore: avoid_print
    print('[afromessage_dart] error: $error');
  }
  if (stackTrace != null) {
    // ignore: avoid_print
    print(stackTrace);
  }
}

/// Internal helper used by the client.
class AfroMessageLog {
  AfroMessageLog({
    required this.level,
    AfroMessageLogHandler? handler,
  }) : handler = handler ?? defaultAfroMessageLogger;

  final AfroMessageLogLevel level;
  final AfroMessageLogHandler handler;

  void call(
    AfroMessageLogLevel messageLevel,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    if (!_shouldLog(level, messageLevel)) return;
    handler(
      messageLevel,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// Strips secrets from maps before debug logging.
  static Map<String, Object?> sanitize(Map<dynamic, dynamic> input) {
    final out = <String, Object?>{};
    input.forEach((key, value) {
      final keyStr = key.toString();
      final lower = keyStr.toLowerCase();
      if (lower.contains('authorization') ||
          lower.contains('apikey') ||
          lower.contains('api_key') ||
          lower == 'token') {
        out[keyStr] = '***';
      } else if (value is Map) {
        out[keyStr] = sanitize(value);
      } else {
        out[keyStr] = value;
      }
    });
    return out;
  }
}
