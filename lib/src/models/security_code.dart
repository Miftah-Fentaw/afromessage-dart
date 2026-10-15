/// Code character type for OTP / challenge SMS.
enum SecurityCodeType {
  /// Digits only (`0`).
  numeric(0),

  /// Letters only (`1`).
  alphabetic(1),

  /// Letters and digits (`2`).
  alphanumeric(2);

  const SecurityCodeType(this.value);
  final int value;
}

/// Request to send a security / OTP code.
class SendSecurityCodeRequest {
  const SendSecurityCodeRequest({
    required this.to,
    this.from,
    this.sender,
    this.length = 4,
    this.type = SecurityCodeType.numeric,
    this.ttl = 0,
    this.callback,
    this.prefix,
    this.postfix,
    this.spacesBefore = 0,
    this.spacesAfter = 0,
  });

  final String to;
  final String? from;
  final String? sender;

  /// Character length of the generated code. Default `4`.
  final int length;

  /// Code character set. Default numeric.
  final SecurityCodeType type;

  /// Seconds until expiry. `0` means no expiry.
  final int ttl;

  final String? callback;

  /// Text before the code.
  final String? prefix;

  /// Text after the code.
  final String? postfix;

  /// Spaces between [prefix] and the code.
  final int spacesBefore;

  /// Spaces between the code and [postfix].
  final int spacesAfter;

  Map<String, String> toQueryParameters({
    String? defaultFrom,
    String? defaultSender,
  }) {
    final params = <String, String>{
      'to': to,
      'len': length.toString(),
      't': type.value.toString(),
      'ttl': ttl.toString(),
      'sb': spacesBefore.toString(),
      'sa': spacesAfter.toString(),
    };

    final resolvedFrom = from ?? defaultFrom;
    final resolvedSender = sender ?? defaultSender;
    if (resolvedFrom != null && resolvedFrom.isNotEmpty) {
      params['from'] = resolvedFrom;
    }
    if (resolvedSender != null && resolvedSender.isNotEmpty) {
      params['sender'] = resolvedSender;
    }
    if (callback != null && callback!.isNotEmpty) {
      params['callback'] = callback!;
    }
    if (prefix != null && prefix!.isNotEmpty) params['pr'] = prefix!;
    if (postfix != null && postfix!.isNotEmpty) params['ps'] = postfix!;

    return params;
  }
}

/// Response from sending a security code.
class SendSecurityCodeResponse {
  const SendSecurityCodeResponse({
    required this.acknowledge,
    this.response,
  });

  factory SendSecurityCodeResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['response'];
    return SendSecurityCodeResponse(
      acknowledge: json['acknowledge']?.toString() ?? 'unknown',
      response: raw is Map<String, dynamic>
          ? SendSecurityCodeResponseData.fromJson(raw)
          : null,
    );
  }

  final String acknowledge;
  final SendSecurityCodeResponseData? response;

  bool get isSuccess => acknowledge == 'success';
}

class SendSecurityCodeResponseData {
  const SendSecurityCodeResponseData({
    required this.status,
    required this.messageId,
    required this.message,
    required this.to,
    required this.code,
    required this.verificationId,
  });

  factory SendSecurityCodeResponseData.fromJson(Map<String, dynamic> json) {
    return SendSecurityCodeResponseData(
      status: json['status']?.toString() ?? '',
      messageId: json['message_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      to: json['to']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      verificationId: json['verificationId']?.toString() ?? '',
    );
  }

  final String status;
  final String messageId;
  final String message;
  final String to;

  /// Generated security code (handle carefully; do not log in production).
  final String code;

  /// Pass this (or the phone) to [VerifyCodeRequest].
  final String verificationId;
}
