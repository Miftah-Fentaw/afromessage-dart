/// Request to send a single SMS.
class SendSmsRequest {
  const SendSmsRequest({
    required this.to,
    required this.message,
    this.from,
    this.sender,
    this.template = 0,
    this.callback,
  });

  /// Recipient phone number.
  ///
  /// Accepts Ethio Telecom / Safaricom forms such as `09…`, `07…`, `9…`,
  /// `7…`, `251…`, or `+251…`. Normalized to E.164 before sending.
  final String to;

  /// Message body, or template UID when [template] is non-zero.
  final String message;

  /// Identifier ID override. Defaults to client [AfroMessageConfig.identifierId].
  final String? from;

  /// Sender name override. Defaults to client [AfroMessageConfig.senderName].
  final String? sender;

  /// `1` if [message] is a template ID; otherwise `0`.
  final int template;

  /// Optional GET callback URL for delivery progress.
  final String? callback;

  Map<String, dynamic> toJson({
    String? defaultFrom,
    String? defaultSender,
  }) {
    return {
      'to': to,
      'message': message,
      if ((from ?? defaultFrom)?.isNotEmpty ?? false)
        'from': from ?? defaultFrom,
      if ((sender ?? defaultSender)?.isNotEmpty ?? false)
        'sender': sender ?? defaultSender,
      if (template != 0) 'template': template,
      if (callback != null && callback!.isNotEmpty) 'callback': callback,
    };
  }
}

/// Response from a single SMS send.
class SendSmsResponse {
  const SendSmsResponse({
    required this.acknowledge,
    this.response,
    this.error,
  });

  factory SendSmsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['response'];
    return SendSmsResponse(
      acknowledge: json['acknowledge']?.toString() ?? 'unknown',
      response: raw is Map<String, dynamic>
          ? SendSmsResponseData.fromJson(raw)
          : null,
      error: json['error']?.toString(),
    );
  }

  final String acknowledge;
  final SendSmsResponseData? response;
  final String? error;

  bool get isSuccess => acknowledge == 'success';
}

class SendSmsResponseData {
  const SendSmsResponseData({
    required this.status,
    required this.messageId,
    required this.message,
    required this.to,
  });

  factory SendSmsResponseData.fromJson(Map<String, dynamic> json) {
    return SendSmsResponseData(
      status: json['status']?.toString() ?? '',
      messageId: json['message_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
    );
  }

  final String status;
  final String messageId;
  final String message;
  final String to;
}
