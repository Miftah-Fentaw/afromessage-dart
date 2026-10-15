/// Personalized recipient for bulk SMS.
class PersonalizedRecipient {
  const PersonalizedRecipient({
    required this.to,
    required this.message,
  });

  final String to;
  final String message;

  Map<String, dynamic> toJson() => {'to': to, 'message': message};
}

/// Request to send bulk SMS.
class BulkSmsRequest {
  const BulkSmsRequest({
    this.to,
    this.personalizedTo,
    this.from,
    this.sender,
    this.message,
    this.campaign,
    this.createCallback,
    this.statusCallback,
  });

  /// Recipients sharing the same [message].
  final List<String>? to;

  /// Recipients each with their own message.
  final List<PersonalizedRecipient>? personalizedTo;

  /// Identifier ID override.
  final String? from;

  /// Sender name. Falls back to client config when omitted.
  final String? sender;

  /// Shared message body (required when not using [personalizedTo]).
  final String? message;

  /// Campaign label for tracking in the dashboard.
  final String? campaign;

  /// POST callback when messages are queued.
  final String? createCallback;

  /// GET callback for status updates.
  final String? statusCallback;

  Map<String, dynamic> toJson({
    String? defaultFrom,
    String? defaultSender,
  }) {
    final resolvedSender = sender ?? defaultSender;
    return {
      if (to != null) 'to': to,
      if (personalizedTo != null)
        'to': personalizedTo!.map((e) => e.toJson()).toList(),
      if ((from ?? defaultFrom)?.isNotEmpty ?? false)
        'from': from ?? defaultFrom,
      if (resolvedSender != null && resolvedSender.isNotEmpty)
        'sender': resolvedSender,
      if (message != null) 'message': message,
      if (campaign != null) 'campaign': campaign,
      if (createCallback != null) 'createCallback': createCallback,
      if (statusCallback != null) 'statusCallback': statusCallback,
    };
  }
}

/// Response from a bulk SMS send.
class BulkSmsResponse {
  const BulkSmsResponse({
    required this.acknowledge,
    this.response,
  });

  factory BulkSmsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['response'];
    return BulkSmsResponse(
      acknowledge: json['acknowledge']?.toString() ?? 'unknown',
      response: raw is Map<String, dynamic>
          ? BulkSmsResponseData.fromJson(raw)
          : null,
    );
  }

  final String acknowledge;
  final BulkSmsResponseData? response;

  bool get isSuccess => acknowledge == 'success';
}

class BulkSmsResponseData {
  const BulkSmsResponseData({
    required this.message,
    required this.campaignId,
  });

  factory BulkSmsResponseData.fromJson(Map<String, dynamic> json) {
    return BulkSmsResponseData(
      message: json['message']?.toString() ?? '',
      campaignId: json['campaign_id']?.toString() ?? '',
    );
  }

  final String message;
  final String campaignId;
}
