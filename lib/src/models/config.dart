import '../logging.dart';

/// Configuration for the AfroMessage SMS client.
///
/// ## Required
/// - [apiKey] — Bearer token from the AfroMessage dashboard.
///
/// ## Recommended
/// - [senderName] — verified sender label shown as SMS “from”.
///   Many accounts require this; omit only if your dashboard allows it.
///
/// ## Optional
/// - [identifierId] — system identifier / short-code (`from` in the API).
///   Needed only if you have **multiple** identifiers.
/// - [baseUrl] — override for proxies/tests (default AfroMessage API).
/// - [logLevel] / [logger] — developer diagnostics (API key is never logged).
/// - [throwOnApiError] — throw when HTTP 200 but `acknowledge` is not `success`.
class AfroMessageConfig {
  const AfroMessageConfig({
    required this.apiKey,
    this.senderName = '',
    this.identifierId = '',
    this.baseUrl = 'https://api.afromessage.com/api',
    this.logLevel = AfroMessageLogLevel.off,
    this.logger,
    this.throwOnApiError = false,
  });

  /// **Required.** Bearer token from your AfroMessage dashboard.
  final String apiKey;

  /// **Recommended.** Verified sender name shown as the SMS “from” label.
  final String senderName;

  /// **Optional.** System identifier ID (short code) when you have multiple.
  ///
  /// Sent as the API `from` field. Leave empty if you only have one identifier.
  final String identifierId;

  /// API base URL. Override only for testing or custom proxies.
  final String baseUrl;

  /// Minimum log verbosity. Default is [AfroMessageLogLevel.off].
  final AfroMessageLogLevel logLevel;

  /// Optional custom log sink. Defaults to [defaultAfroMessageLogger] when
  /// [logLevel] is not [AfroMessageLogLevel.off].
  final AfroMessageLogHandler? logger;

  /// When `true`, responses with `acknowledge != success` throw
  /// [AfroMessageException] instead of returning a failed response object.
  ///
  /// Default `false` so callers can check `result.isSuccess` themselves.
  final bool throwOnApiError;
}
