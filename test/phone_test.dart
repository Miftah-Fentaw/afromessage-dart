import 'package:afromessage_dart/afromessage_dart.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeEthiopianPhone', () {
    const cases = <String, String>{
      // Ethio Telecom
      '0912345678': '+251912345678',
      '912345678': '+251912345678',
      '251912345678': '+251912345678',
      '+251912345678': '+251912345678',
      '+251 91 234 5678': '+251912345678',
      '09-123-45678': '+251912345678',
      // Safaricom Ethiopia
      '0712345678': '+251712345678',
      '712345678': '+251712345678',
      '251712345678': '+251712345678',
      '+251712345678': '+251712345678',
      '+251 71 234 5678': '+251712345678',
    };

    for (final entry in cases.entries) {
      test('normalizes ${entry.key} → ${entry.value}', () {
        expect(normalizeEthiopianPhone(entry.key), entry.value);
      });
    }

    test('rejects empty', () {
      expect(
        () => normalizeEthiopianPhone(''),
        throwsA(isA<AfroMessageException>()),
      );
    });

    test('rejects landline-like prefixes', () {
      expect(
        () => normalizeEthiopianPhone('0111234567'),
        throwsA(isA<AfroMessageException>()),
      );
    });

    test('rejects too short', () {
      expect(
        () => normalizeEthiopianPhone('09123'),
        throwsA(isA<AfroMessageException>()),
      );
    });
  });
}
