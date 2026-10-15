/// Request to verify a previously sent security code.
class VerifyCodeRequest {
  const VerifyCodeRequest({
    required this.code,
    this.to,
    this.verificationId,
  }) : assert(
          to != null || verificationId != null,
          'Provide either to or verificationId',
        );

  /// The code the user entered.
  final String code;

  /// Recipient phone. Required if [verificationId] is omitted.
  final String? to;

  /// Verification ID from [SendSecurityCodeResponseData.verificationId].
  final String? verificationId;

  Map<String, String> toQueryParameters() {
    return {
      'code': code,
      if (to != null && to!.isNotEmpty) 'to': to!,
      if (verificationId != null && verificationId!.isNotEmpty)
        'vc': verificationId!,
    };
  }
}

/// Response from verifying a security code.
class VerifyCodeResponse {
  const VerifyCodeResponse({
    required this.acknowledge,
    this.response,
    this.error,
  });

  factory VerifyCodeResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['response'];
    return VerifyCodeResponse(
      acknowledge: json['acknowledge']?.toString() ?? 'unknown',
      response: raw is Map<String, dynamic>
          ? VerifyCodeResponseData.fromJson(raw)
          : null,
      error: json['error']?.toString(),
    );
  }

  final String acknowledge;
  final VerifyCodeResponseData? response;
  final String? error;

  bool get isSuccess => acknowledge == 'success';
}

class VerifyCodeResponseData {
  const VerifyCodeResponseData({
    required this.phone,
    required this.code,
    required this.verificationId,
    required this.sentAt,
  });

  factory VerifyCodeResponseData.fromJson(Map<String, dynamic> json) {
    return VerifyCodeResponseData(
      phone: json['phone']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      verificationId: json['verificationId']?.toString() ?? '',
      sentAt: json['sentAt']?.toString() ?? '',
    );
  }

  final String phone;
  final String code;
  final String verificationId;
  final String sentAt;
}
