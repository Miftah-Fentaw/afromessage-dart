import 'dart:convert';

import 'package:afromessage_dart/afromessage_dart.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('AfroMessage', () {
    test('throws when apiKey is empty', () {
      expect(
        () => AfroMessage(const AfroMessageConfig(apiKey: '')),
        throwsA(isA<AfroMessageException>()),
      );
    });

    test('sendSms posts to /send with auth and defaults', () async {
      late http.Request captured;

      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'acknowledge': 'success',
            'response': {
              'status': 'Sent',
              'message_id': 'msg-1',
              'message': 'Hi',
              'to': '0912345678',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final sms = AfroMessage(
        const AfroMessageConfig(
          apiKey: 'test-token',
          senderName: 'MySender',
          identifierId: 'id-1',
        ),
        client: client,
      );

      final result = await sms.sendSms(
        const SendSmsRequest(to: '0912345678', message: 'Hi'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.response?.messageId, 'msg-1');
      expect(captured.method, 'POST');
      expect(captured.url.path, endsWith('/send'));
      expect(captured.headers['Authorization'], 'Bearer test-token');

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['to'], '+251912345678');
      expect(body['message'], 'Hi');
      expect(body['sender'], 'MySender');
      expect(body['from'], 'id-1');
    });

    test('sendBulkSms posts recipients to /bulk_send', () async {
      late http.Request captured;

      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'acknowledge': 'success',
            'response': {
              'message': 'queued',
              'campaign_id': 'camp-1',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final sms = AfroMessage(
        const AfroMessageConfig(apiKey: 'token', senderName: 'Sender'),
        client: client,
      );

      final result = await sms.sendBulkSms(
        const BulkSmsRequest(
          to: ['0911111111', '0922222222'],
          message: 'Bulk hello',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.response?.campaignId, 'camp-1');
      expect(captured.url.path, endsWith('/bulk_send'));

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['to'], ['+251911111111', '+251922222222']);
      expect(body['message'], 'Bulk hello');
      expect(body['sender'], 'Sender');
    });

    test('sendSecurityCode calls GET /challenge', () async {
      late http.Request captured;

      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'acknowledge': 'success',
            'response': {
              'status': 'Sent',
              'message_id': 'm1',
              'message': 'Your code is 1234',
              'to': '0912345678',
              'code': '1234',
              'verificationId': 'vc-1',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final sms = AfroMessage(
        const AfroMessageConfig(apiKey: 'token', senderName: 'Sender'),
        client: client,
      );

      final result = await sms.sendSecurityCode(
        const SendSecurityCodeRequest(
          to: '0912345678',
          length: 4,
          postfix: 'is your code',
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.response?.code, '1234');
      expect(result.response?.verificationId, 'vc-1');
      expect(captured.method, 'GET');
      expect(captured.url.path, endsWith('/challenge'));
      expect(captured.url.queryParameters['to'], '+251912345678');
      expect(captured.url.queryParameters['len'], '4');
      expect(captured.url.queryParameters['ps'], 'is your code');
      expect(captured.url.queryParameters['sa'], '1');
      expect(captured.url.queryParameters['sb'], '1');
      expect(captured.url.queryParameters['sender'], 'Sender');
    });

    test('verifyCode calls GET /verify', () async {
      late http.Request captured;

      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'acknowledge': 'success',
            'response': {
              'phone': '0912345678',
              'code': '1234',
              'verificationId': 'vc-1',
              'sentAt': '2024-01-01T00:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final sms = AfroMessage(
        const AfroMessageConfig(apiKey: 'token'),
        client: client,
      );

      final result = await sms.verifyCode(
        const VerifyCodeRequest(to: '0912345678', code: '1234'),
      );

      expect(result.isSuccess, isTrue);
      expect(result.response?.phone, '0912345678');
      expect(captured.url.path, endsWith('/verify'));
      expect(captured.url.queryParameters['code'], '1234');
      expect(captured.url.queryParameters['to'], '+251912345678');
    });

    test('throws AfroMessageException on non-2xx', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Unauthorized'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final sms = AfroMessage(
        const AfroMessageConfig(apiKey: 'bad'),
        client: client,
      );

      expect(
        () => sms.sendSms(
          const SendSmsRequest(to: '0912345678', message: 'x'),
        ),
        throwsA(
          isA<AfroMessageException>().having(
            (e) => e.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
    });

    test('returns failed response when acknowledge is error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'acknowledge': 'error',
            'response': {'message': 'Invalid sender'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final sms = AfroMessage(
        const AfroMessageConfig(apiKey: 'token', senderName: 'X'),
        client: client,
      );

      final result = await sms.sendSms(
        const SendSmsRequest(to: '0912345678', message: 'Hi'),
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, 'Invalid sender');
    });

    test('throwOnApiError throws on acknowledge error', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'acknowledge': 'error',
            'response': {'message': 'Invalid sender'},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final sms = AfroMessage(
        const AfroMessageConfig(
          apiKey: 'token',
          throwOnApiError: true,
        ),
        client: client,
      );

      expect(
        () => sms.sendSms(
          const SendSmsRequest(to: '0912345678', message: 'Hi'),
        ),
        throwsA(
          isA<AfroMessageException>()
              .having((e) => e.acknowledge, 'acknowledge', 'error')
              .having((e) => e.message, 'message', 'Invalid sender'),
        ),
      );
    });

    test('logs requests when logLevel is info', () async {
      final lines = <String>[];
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'acknowledge': 'success',
            'response': {
              'status': 'Sent',
              'message_id': 'm',
              'message': 'Hi',
              'to': '+251912345678',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final sms = AfroMessage(
        AfroMessageConfig(
          apiKey: 'token',
          logLevel: AfroMessageLogLevel.info,
          logger: (level, message, {error, stackTrace, context}) {
            lines.add('$level:$message');
          },
        ),
        client: client,
      );

      await sms.sendSms(
        const SendSmsRequest(to: '0912345678', message: 'Hi'),
      );

      expect(lines.any((l) => l.contains('HTTP request')), isTrue);
      expect(lines.any((l) => l.contains('API success')), isTrue);
    });
  });
}
