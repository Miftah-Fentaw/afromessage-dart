/// Thrown when AfroMessage API configuration or request validation fails.
class AfroMessageException implements Exception {
  AfroMessageException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() {
    final buffer = StringBuffer('AfroMessageException: $message');
    if (statusCode != null) buffer.write(' (status: $statusCode)');
    if (body != null && body!.isNotEmpty) buffer.write(' — $body');
    return buffer.toString();
  }
}
