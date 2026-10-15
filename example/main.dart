import 'package:afromessage_dart/afromessage_dart.dart';

/// Minimal package example for the pub.dev Example tab.
///
/// ```sh
/// dart run example/main.dart
/// ```
Future<void> main() async {
  final sms = AfroMessage(
    const AfroMessageConfig(
      apiKey: 'YOUR_TOKEN',
      senderName: 'YOUR_SENDER',
    ),
  );

  try {
    final to = normalizeEthiopianPhone('0912345678');
    final result = await sms.sendSms(
      SendSmsRequest(to: to, message: 'Hello from afromessage_dart'),
    );
    print(result.isSuccess ? 'Sent: ${result.response?.messageId}' : result);
  } on AfroMessageException catch (e) {
    print(e);
  } finally {
    sms.close();
  }
}
