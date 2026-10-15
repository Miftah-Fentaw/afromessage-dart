import 'exceptions.dart';

/// Normalizes an Ethiopian mobile number to E.164 (`+251XXXXXXXXX`).
///
/// Accepts common local and international forms for Ethio Telecom (`09` / `9`)
/// and Safaricom Ethiopia (`07` / `7`):
///
/// - `+251912345678`, `251912345678`
/// - `0912345678`, `912345678`
/// - `+251712345678`, `0712345678`, `712345678`
///
/// Spaces, dashes, and parentheses are ignored.
String normalizeEthiopianPhone(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    throw AfroMessageException('Phone number is required.');
  }

  var digits = trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  if (digits.startsWith('+')) {
    digits = digits.substring(1);
  }
  digits = digits.replaceAll(RegExp(r'\D'), '');

  if (digits.startsWith('251') && digits.length == 12) {
    final national = digits.substring(3);
    _assertMobileNational(national, input);
    return '+$digits';
  }

  if (digits.startsWith('0') && digits.length == 10) {
    final national = digits.substring(1);
    _assertMobileNational(national, input);
    return '+251$national';
  }

  if (digits.length == 9) {
    _assertMobileNational(digits, input);
    return '+251$digits';
  }

  throw AfroMessageException(
    'Invalid Ethiopian phone number: "$input". '
    'Use formats like 09XXXXXXXX, 07XXXXXXXX, 9XXXXXXXX, 7XXXXXXXX, '
    'or +251XXXXXXXXX.',
  );
}

void _assertMobileNational(String national, String original) {
  if (national.length != 9 || !RegExp(r'^[79]\d{8}$').hasMatch(national)) {
    throw AfroMessageException(
      'Invalid Ethiopian mobile number: "$original". '
      'Expected Ethio Telecom (9…) or Safaricom (7…) after country code.',
    );
  }
}
