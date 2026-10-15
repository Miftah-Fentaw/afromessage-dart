import 'package:afromessage_dart/afromessage_dart.dart';

/// Replace these with values from https://api.afromessage.com/
const apiKey = String.fromEnvironment('AFROMESSAGE_TOKEN');
const senderName = String.fromEnvironment('AFROMESSAGE_SENDER_NAMES');
const identifierId = String.fromEnvironment('AFROMESSAGE_IDENTIFIER_ID');

Future<void> main() async {
  if (apiKey.isEmpty) {
    print(
      'Pass credentials with --define, e.g.\n'
      '  dart run example/afromessage_dart_example.dart '
      '--define=AFROMESSAGE_TOKEN=... '
      '--define=AFROMESSAGE_SENDER_NAMES=... '
      '--define=AFROMESSAGE_IDENTIFIER_ID=...',
    );
    return;
  }

  final sms = AfroMessage(
    AfroMessageConfig(
      apiKey: apiKey,
      senderName: senderName,
      identifierId: identifierId,
    ),
  );

  try {
    final result = await sms.sendSms(
      const SendSmsRequest(
        to: '09XXXXXXXX',
        message: 'Hello from afromessage_dart!',
      ),
    );
    print('acknowledge: ${result.acknowledge}');
    print('messageId: ${result.response?.messageId}');
  } on AfroMessageException catch (e) {
    print('Error: $e');
  } finally {
    sms.close();
  }
}
