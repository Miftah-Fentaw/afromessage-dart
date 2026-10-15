## 1.0.3

- Add Flutter `demo_app/` (path dependency, mock mode, runtime API key).
- Slim `example/main.dart` for the pub.dev Example tab.
- Ignore `doc/api/` and exclude `demo_app/` from the pub.dev upload.
- Add demo screenshot for pub.dev package preview.

## 1.0.2

- Remove maintainer release instructions from README (pub.dev landing page).

## 1.0.1

- Normalize Ethiopian mobiles (`09`/`07`/`9`/`7`/`+251`) to E.164 before send.
- Add CI, automated pub.dev publishing, and `scripts/release.sh`.
- Document phone formats and `issue_tracker` metadata.

## 1.0.0

- Initial AfroMessage client for Dart/Flutter.
- `sendSms`, `sendBulkSms`, `sendSecurityCode`, and `verifyCode`.
