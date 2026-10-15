/// Thrown for configuration, validation, network, HTTP, or API acknowledge errors.
class AfroMessageException implements Exception {
  AfroMessageException(
    this.message, {
    this.statusCode,
    this.body,
    this.endpoint,
    this.method,
    this.acknowledge,
    this.cause,
  });

  /// Human-readable summary.
  final String message;

  /// HTTP status when the failure came from the transport layer.
  final int? statusCode;

  /// Raw response body (JSON string) when available.
  final String? body;

  /// API path, e.g. `/send`.
  final String? endpoint;

  /// HTTP method, e.g. `POST`.
  final String? method;

  /// AfroMessage `acknowledge` field when present (`error`, `failure`, …).
  final String? acknowledge;

  /// Underlying error (e.g. socket failure).
  final Object? cause;

  @override
  String toString() {
    final buffer = StringBuffer('AfroMessageException: $message');
    if (method != null && endpoint != null) {
      buffer.write(' [$method $endpoint]');
    }
    if (acknowledge != null) buffer.write(' (acknowledge: $acknowledge)');
    if (statusCode != null) buffer.write(' (status: $statusCode)');
    if (body != null && body!.isNotEmpty) buffer.write(' — $body');
    if (cause != null) buffer.write(' | cause: $cause');
    return buffer.toString();
  }
}
