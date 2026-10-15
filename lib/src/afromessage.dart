import 'dart:convert';

import 'package:http/http.dart' as http;

import 'exceptions.dart';
import 'logging.dart';
import 'models/bulk_sms.dart';
import 'models/config.dart';
import 'models/security_code.dart';
import 'models/send_sms.dart';
import 'models/verify_code.dart';
import 'phone.dart';

/// Dart client for the [AfroMessage](https://afromessage.com) Ethiopian SMS API.
///
/// ## Credentials
/// - **Required:** [AfroMessageConfig.apiKey]
/// - **Recommended:** [AfroMessageConfig.senderName]
/// - **Optional:** [AfroMessageConfig.identifierId] (only with multiple short codes)
///
/// ## Logging
/// Set [AfroMessageConfig.logLevel] to [AfroMessageLogLevel.info] or
/// [AfroMessageLogLevel.debug] while integrating. The API key is never logged.
///
/// ```dart
/// final sms = AfroMessage(
///   AfroMessageConfig(
///     apiKey: 'YOUR_TOKEN',
///     senderName: 'YOUR_SENDER',
///     logLevel: AfroMessageLogLevel.debug,
///     throwOnApiError: true, // optional: throw when acknowledge != success
///   ),
/// );
///
/// try {
///   final result = await sms.sendSms(
///     SendSmsRequest(to: '0912345678', message: 'Hello from Dart'),
///   );
///   if (!result.isSuccess) {
///     // inspect result.error / result.raw
///   }
/// } on AfroMessageException catch (e) {
///   // validation, network, HTTP, or (if enabled) acknowledge errors
/// }
/// ```
class AfroMessage {
  AfroMessage(
    this.config, {
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _log = AfroMessageLog(
          level: config.logLevel,
          handler: config.logger,
        ) {
    if (config.apiKey.isEmpty) {
      throw AfroMessageException('apiKey is required.');
    }
    _log(
      AfroMessageLogLevel.info,
      'Client created',
      context: {
        'baseUrl': config.baseUrl,
        'hasSenderName': config.senderName.isNotEmpty,
        'hasIdentifierId': config.identifierId.isNotEmpty,
        'throwOnApiError': config.throwOnApiError,
        'logLevel': config.logLevel.name,
      },
    );
  }

  final AfroMessageConfig config;
  final http.Client _client;
  final AfroMessageLog _log;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json;charset=UTF-8',
        'Authorization': 'Bearer ${config.apiKey}',
      };

  /// Sends a single SMS via `POST /send`.
  ///
  /// [SendSmsRequest.to] is normalized with [normalizeEthiopianPhone].
  Future<SendSmsResponse> sendSms(SendSmsRequest request) async {
    if (request.to.isEmpty || request.message.isEmpty) {
      throw AfroMessageException(
        'Both to and message are required.',
        endpoint: '/send',
        method: 'POST',
      );
    }

    final body = request.toJson(
      defaultFrom: config.identifierId,
      defaultSender: config.senderName,
    );
    body['to'] = normalizeEthiopianPhone(request.to);

    final json = await _postJson('/send', body);
    final result = SendSmsResponse.fromJson(json);
    _ensureAcknowledgeSuccess(
      acknowledge: result.acknowledge,
      error: result.error,
      json: json,
      endpoint: '/send',
      method: 'POST',
    );
    return result;
  }

  /// Sends bulk SMS via `POST /bulk_send`.
  ///
  /// Recipient numbers are normalized with [normalizeEthiopianPhone].
  Future<BulkSmsResponse> sendBulkSms(BulkSmsRequest request) async {
    final hasRecipients = (request.to != null && request.to!.isNotEmpty) ||
        (request.personalizedTo != null && request.personalizedTo!.isNotEmpty);

    if (!hasRecipients) {
      throw AfroMessageException(
        'Provide either to or personalizedTo recipients.',
        endpoint: '/bulk_send',
        method: 'POST',
      );
    }

    if (request.personalizedTo == null &&
        (request.message == null || request.message!.isEmpty)) {
      throw AfroMessageException(
        'message is required when not using personalizedTo.',
        endpoint: '/bulk_send',
        method: 'POST',
      );
    }

    final body = request.toJson(
      defaultFrom: config.identifierId,
      defaultSender: config.senderName,
    );

    if (request.personalizedTo != null) {
      body['to'] = request.personalizedTo!
          .map(
            (r) => {
              'to': normalizeEthiopianPhone(r.to),
              'message': r.message,
            },
          )
          .toList();
    } else if (request.to != null) {
      body['to'] = request.to!.map(normalizeEthiopianPhone).toList();
    }

    final json = await _postJson('/bulk_send', body);
    final result = BulkSmsResponse.fromJson(json);
    _ensureAcknowledgeSuccess(
      acknowledge: result.acknowledge,
      error: null,
      json: json,
      endpoint: '/bulk_send',
      method: 'POST',
    );
    return result;
  }

  /// Sends an OTP / security code via `GET /challenge`.
  ///
  /// [SendSecurityCodeRequest.to] is normalized with [normalizeEthiopianPhone].
  Future<SendSecurityCodeResponse> sendSecurityCode(
    SendSecurityCodeRequest request,
  ) async {
    if (request.to.isEmpty) {
      throw AfroMessageException(
        'to is required.',
        endpoint: '/challenge',
        method: 'GET',
      );
    }

    final params = request.toQueryParameters(
      defaultFrom: config.identifierId,
      defaultSender: config.senderName,
    );
    params['to'] = normalizeEthiopianPhone(request.to);

    final json = await _getJson('/challenge', params);
    final result = SendSecurityCodeResponse.fromJson(json);
    _ensureAcknowledgeSuccess(
      acknowledge: result.acknowledge,
      error: null,
      json: json,
      endpoint: '/challenge',
      method: 'GET',
    );
    return result;
  }

  /// Verifies an OTP / security code via `GET /verify`.
  ///
  /// When [VerifyCodeRequest.to] is set, it is normalized with
  /// [normalizeEthiopianPhone].
  Future<VerifyCodeResponse> verifyCode(VerifyCodeRequest request) async {
    if (request.code.isEmpty) {
      throw AfroMessageException(
        'code is required.',
        endpoint: '/verify',
        method: 'GET',
      );
    }

    final params = request.toQueryParameters();
    if (request.to != null && request.to!.isNotEmpty) {
      params['to'] = normalizeEthiopianPhone(request.to!);
    }

    final json = await _getJson('/verify', params);
    final result = VerifyCodeResponse.fromJson(json);
    _ensureAcknowledgeSuccess(
      acknowledge: result.acknowledge,
      error: result.error,
      json: json,
      endpoint: '/verify',
      method: 'GET',
    );
    return result;
  }

  /// Closes the underlying HTTP client. Call when disposing long-lived instances.
  void close() {
    _log(AfroMessageLogLevel.info, 'Client closed');
    _client.close();
  }

  void _ensureAcknowledgeSuccess({
    required String acknowledge,
    required String? error,
    required Map<String, dynamic> json,
    required String endpoint,
    required String method,
  }) {
    if (acknowledge == 'success') {
      _log(
        AfroMessageLogLevel.info,
        'API success',
        context: {'method': method, 'endpoint': endpoint},
      );
      return;
    }

    final detail = error ??
        json['error']?.toString() ??
        _nestedError(json['response']) ??
        'API returned acknowledge=$acknowledge';

    _log(
      AfroMessageLogLevel.error,
      'API acknowledge error',
      context: {
        'method': method,
        'endpoint': endpoint,
        'acknowledge': acknowledge,
        'detail': detail,
        if (config.logLevel == AfroMessageLogLevel.debug) 'body': json,
      },
    );

    if (config.throwOnApiError) {
      throw AfroMessageException(
        detail,
        endpoint: endpoint,
        method: method,
        acknowledge: acknowledge,
        body: jsonEncode(json),
      );
    }
  }

  String? _nestedError(Object? raw) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map) {
      return raw['errors']?.toString() ??
          raw['error']?.toString() ??
          raw['message']?.toString();
    }
    return raw.toString();
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${config.baseUrl}$path');
    _log(
      AfroMessageLogLevel.info,
      'HTTP request',
      context: {'method': 'POST', 'endpoint': path},
    );
    _log(
      AfroMessageLogLevel.debug,
      'HTTP request body',
      context: AfroMessageLog.sanitize({
        'method': 'POST',
        'endpoint': path,
        'body': body,
      }),
    );

    try {
      final response = await _client.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );
      return _decodeResponse(response, endpoint: path, method: 'POST');
    } on AfroMessageException {
      rethrow;
    } on http.ClientException catch (e, st) {
      _log(
        AfroMessageLogLevel.error,
        'HTTP client error',
        error: e,
        stackTrace: st,
        context: {'method': 'POST', 'endpoint': path},
      );
      throw AfroMessageException(
        'HTTP client error: $e',
        endpoint: path,
        method: 'POST',
        cause: e,
      );
    } catch (e, st) {
      _log(
        AfroMessageLogLevel.error,
        'Request failed',
        error: e,
        stackTrace: st,
        context: {'method': 'POST', 'endpoint': path},
      );
      throw AfroMessageException(
        'Request failed: $e',
        endpoint: path,
        method: 'POST',
        cause: e,
      );
    }
  }

  Future<Map<String, dynamic>> _getJson(
    String path,
    Map<String, String> query,
  ) async {
    final uri = Uri.parse('${config.baseUrl}$path').replace(
      queryParameters: query,
    );
    _log(
      AfroMessageLogLevel.info,
      'HTTP request',
      context: {'method': 'GET', 'endpoint': path},
    );
    _log(
      AfroMessageLogLevel.debug,
      'HTTP request query',
      context: AfroMessageLog.sanitize({
        'method': 'GET',
        'endpoint': path,
        'query': query,
      }),
    );

    try {
      final response = await _client.get(uri, headers: _headers);
      return _decodeResponse(response, endpoint: path, method: 'GET');
    } on AfroMessageException {
      rethrow;
    } on http.ClientException catch (e, st) {
      _log(
        AfroMessageLogLevel.error,
        'HTTP client error',
        error: e,
        stackTrace: st,
        context: {'method': 'GET', 'endpoint': path},
      );
      throw AfroMessageException(
        'HTTP client error: $e',
        endpoint: path,
        method: 'GET',
        cause: e,
      );
    } catch (e, st) {
      _log(
        AfroMessageLogLevel.error,
        'Request failed',
        error: e,
        stackTrace: st,
        context: {'method': 'GET', 'endpoint': path},
      );
      throw AfroMessageException(
        'Request failed: $e',
        endpoint: path,
        method: 'GET',
        cause: e,
      );
    }
  }

  Map<String, dynamic> _decodeResponse(
    http.Response response, {
    required String endpoint,
    required String method,
  }) {
    _log(
      AfroMessageLogLevel.debug,
      'HTTP response',
      context: {
        'method': method,
        'endpoint': endpoint,
        'statusCode': response.statusCode,
        'body': response.body,
      },
    );

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
          endpoint: endpoint,
          method: method,
        );
      }
    } on FormatException catch (e) {
      _log(
        AfroMessageLogLevel.error,
        'Invalid JSON response',
        error: e,
        context: {
          'method': method,
          'endpoint': endpoint,
          'statusCode': response.statusCode,
        },
      );
      throw AfroMessageException(
        'Invalid JSON response',
        statusCode: response.statusCode,
        body: response.body,
        endpoint: endpoint,
        method: method,
        cause: e,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = json['error']?.toString() ??
          json['message']?.toString() ??
          _nestedError(json['response']) ??
          'Request failed';
      _log(
        AfroMessageLogLevel.error,
        'HTTP error',
        context: {
          'method': method,
          'endpoint': endpoint,
          'statusCode': response.statusCode,
          'detail': detail,
        },
      );
      throw AfroMessageException(
        detail,
        statusCode: response.statusCode,
        body: response.body,
        endpoint: endpoint,
        method: method,
        acknowledge: json['acknowledge']?.toString(),
      );
    }

    return json;
  }
}
