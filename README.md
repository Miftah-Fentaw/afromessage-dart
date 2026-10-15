![afromessage_dart](assets/banner.png)

# afromessage_dart

Dart/Flutter client for [AfroMessage](https://afromessage.com) - Ethiopia's SMS API.

Same capabilities as the Node.js [`afromessage`](https://www.npmjs.com/package/afromessage) package:

- Send single SMS
- Send bulk / personalized SMS
- Send OTP / security codes
- Verify security codes

Docs: [AfroMessage developers](https://afromessage.com/developers)

## Install

```bash
dart pub add afromessage_dart
# or in Flutter:
flutter pub add afromessage_dart
```

## Credentials

From your [AfroMessage dashboard](https://api.afromessage.com/):

| Value | Description |
| --- | --- |
| API token | Bearer token for requests |
| Sender name | Verified sender label |
| Identifier ID | Short-code / identifier (optional if you have one) |

> **Security:** Do not ship your API token inside a public Flutter app. Prefer calling AfroMessage from your backend (Dart, Node, etc.) and expose only your own authenticated endpoints to the mobile client.

## Phone numbers

Numbers are normalized to E.164 (`+251XXXXXXXXX`) before each request.
Ethio Telecom (`09` / `9`) and Safaricom Ethiopia (`07` / `7`) are both accepted:

`0912345678`, `912345678`, `0712345678`, `+251912345678`, `251712345678`, etc.

## Usage

```dart
import 'package:afromessage_dart/afromessage_dart.dart';

final sms = AfroMessage(
  AfroMessageConfig(
    apiKey: 'YOUR_TOKEN',
    senderName: 'YOUR_SENDER',
    identifierId: 'YOUR_IDENTIFIER', // optional
  ),
);

// Single SMS (09…, 07…, +251… all work)
final sent = await sms.sendSms(
  SendSmsRequest(
    to: '0912345678',
    message: 'Hello from Flutter/Dart',
  ),
);

// Bulk SMS
final bulk = await sms.sendBulkSms(
  BulkSmsRequest(
    to: ['0911111111', '0922222222'],
    message: 'Hello everyone',
  ),
);

// OTP
final otp = await sms.sendSecurityCode(
  SendSecurityCodeRequest(
    to: '0912345678',
    length: 6,
    postfix: 'is your verification code',
  ),
);

// Verify OTP
final verified = await sms.verifyCode(
  VerifyCodeRequest(
    to: '0912345678',
    code: '123456',
  ),
);

sms.close();
```

## API map

| Method | HTTP | Endpoint |
| --- | --- | --- |
| `sendSms` | POST | `/api/send` |
| `sendBulkSms` | POST | `/api/bulk_send` |
| `sendSecurityCode` | GET | `/api/challenge` |
| `verifyCode` | GET | `/api/verify` |

## Flutter vs Dart

This is a **pure Dart** package (HTTP only). It works in Flutter apps, Flutter web, Dart CLI, and server-side Dart — no platform plugins needed.

## Demo app

A Flutter sample lives in [`demo_app/`](demo_app/) on GitHub (not published to pub.dev). It has **SMS** / **OTP** tabs, loads `API_Key` + `PHONE` from `.env` (key shown only as a green/red badge), and makes live AfroMessage calls.

```bash
cd demo_app
flutter pub get
flutter run
```

> Demo only — call AfroMessage from your backend in production. Never commit API keys.

## Owner & maintainer

**Miftah Fentaw** ([@Miftah-Fentaw](https://github.com/Miftah-Fentaw))

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [BSD 3-Clause License](LICENSE).
