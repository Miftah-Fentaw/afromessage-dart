# afromessage_dart demo

Flutter sample for [`afromessage_dart`](../). Path dependency — **not** published to pub.dev.

```bash
cd demo_app
cp .env.example .env   # then fill values
flutter pub get
flutter run
```

`.env` keys:

```env
API_Key=...
AFROMESSAGE_SENDER_NAMES=...
PHONE=0956291689
```

- API key is **not** shown in a text field — only a green/red status badge.
- Phone is loaded from `PHONE` (editable in the UI).
- Tabs: **SMS** / **OTP** — live API calls only.
