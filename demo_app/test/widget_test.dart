import 'package:demo_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('demo loads with mock mode and warning banner', (tester) async {
    await tester.pumpWidget(const DemoApp());

    expect(find.textContaining('Demo only'), findsOneWidget);
    expect(find.text('Send SMS'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Verify OTP'), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
  });

  testWidgets('mock send sms shows result', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.enterText(find.byType(TextField).at(2), '0911000000');
    await tester.tap(find.text('Send SMS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Mock success'), findsOneWidget);
  });
}
