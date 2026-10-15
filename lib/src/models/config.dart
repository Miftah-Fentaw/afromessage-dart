/// Configuration for the AfroMessage SMS client.
class AfroMessageConfig {
  const AfroMessageConfig({
    required this.apiKey,
    this.senderName = '',
    this.identifierId = '',
    this.baseUrl = 'https://api.afromessage.com/api',
  });

  /// Bearer token from your AfroMessage dashboard.
  final String apiKey;

  /// Verified sender name shown as the SMS "from" label.
  final String senderName;

  /// System identifier ID (short code) when you have multiple identifiers.
  final String identifierId;

  /// API base URL. Override only for testing or custom proxies.
  final String baseUrl;
}
