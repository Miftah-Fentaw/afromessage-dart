import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'models/bulk_sms.dart';
import 'models/config.dart';
import 'models/security_code.dart';
import 'models/send_sms.dart';
import 'models/verify_code.dart';

/// Dart client for the [AfroMessage](https://afromessage.com) Ethiopian SMS API.
///
/// Mirrors the Node.js [`afromessage`](https://www.npmjs.com/package/afromessage)
/// package: send SMS, bulk SMS, OTPs, and verify codes.
///
/// ```dart
/// final sms = AfroMessage(
///   AfroMessageConfig(
///     apiKey: 'YOUR_TOKEN',
///     senderName: 'YOUR_SENDER',
///     identifierId: 'YOUR_IDENTIFIER',
///   ),
/// );
///
/// final result = await sms.sendSms(
///   SendSmsRequest(to: '0912345678', message: 'Hello from Dart'),
/// );
/// ```
class AfroMessage {
  AfroMessage(
    this.config, {
    http.Client? client,
  }) : _client = client ?? http.Client() {
    if (config.apiKey.isEmpty) {
      throw AfroMessageException('apiKey is required.');
    }
  }

  final AfroMessageConfig config;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json;charset=UTF-8',
        'Authorization': 'Bearer ${config.apiKey}',
      };

  /// Sends a single SMS via `POST /send`.
  Future<SendSmsResponse> sendSms(SendSmsRequest request) async {
    if (request.to.isEmpty || request.message.isEmpty) {
      throw AfroMessageException('Both to and message are required.');
    }

    final body = request.toJson(
      defaultFrom: config.identifierId,
      defaultSender: config.senderName,
    );

    final json = await _postJson('/send', body);
    return SendSmsResponse.fromJson(json);
  }

  /// Sends bulk SMS via `POST /bulk_send`.
  Future<BulkSmsResponse> sendBulkSms(BulkSmsRequest request) async {
    final hasRecipients = (request.to != null && request.to!.isNotEmpty) ||
        (request.personalizedTo != null && request.personalizedTo!.isNotEmpty);

    if (!hasRecipients) {
      throw AfroMessageException(
        'Provide either to or personalizedTo recipients.',
      );
    }

    if (request.personalizedTo == null &&
        (request.message == null || request.message!.isEmpty)) {
      throw AfroMessageException(
        'message is required when not using personalizedTo.',
      );
    }

    final body = request.toJson(
      defaultFrom: config.identifierId,
      defaultSender: config.senderName,
    );

    final json = await _postJson('/bulk_send', body);
    return BulkSmsResponse.fromJson(json);
  }

  /// Sends an OTP / security code via `GET /challenge`.
  Future<SendSecurityCodeResponse> sendSecurityCode(
    SendSecurityCodeRequest request,
  ) async {
    if (request.to.isEmpty) {
      throw AfroMessageException('to is required.');
    }

    final params = request.toQueryParameters(
      defaultFrom: config.identifierId,
      defaultSender: config.senderName,
    );

    final json = await _getJson('/challenge', params);
    return SendSecurityCodeResponse.fromJson(json);
  }

  /// Verifies an OTP / security code via `GET /verify`.
  Future<VerifyCodeResponse> verifyCode(VerifyCodeRequest request) async {
    if (request.code.isEmpty) {
      throw AfroMessageException('code is required.');
    }

    final json = await _getJson('/verify', request.toQueryParameters());
    return VerifyCodeResponse.fromJson(json);
  }

  /// Closes the underlying HTTP client. Call when disposing long-lived instances.
  void close() => _client.close();

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${config.baseUrl}$path');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> _getJson(
    String path,
    Map<String, String> query,
  ) async {
    final uri = Uri.parse('${config.baseUrl}$path').replace(
      queryParameters: query,
    );
    final response = await _client.get(uri, headers: _headers);
    return _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      } else {
        throw AfroMessageException(
          'Unexpected response shape',
          statusCode: response.statusCode,
          body: response.body,
        );
      }
    } on FormatException {
      throw AfroMessageException(
        'Invalid JSON response',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AfroMessageException(
        json['error']?.toString() ??
            json['message']?.toString() ??
            'Request failed',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return json;
  }
}
