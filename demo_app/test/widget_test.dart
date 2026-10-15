import 'package:demo_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows logo header, tabs, and API key flag', (tester) async {
    await tester.pumpWidget(const DemoApp());

    expect(find.text('AfroMessage'), findsOneWidget);
    expect(find.text('SMS'), findsOneWidget);
    expect(find.text('OTP'), findsOneWidget);
    expect(find.text('API key missing'), findsOneWidget);
    expect(find.text('Send SMS'), findsOneWidget);
    expect(find.text('API key'), findsNothing);
  });

  testWidgets('switches to OTP tab', (tester) async {
    await tester.pumpWidget(const DemoApp());

    await tester.tap(find.text('OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Verify OTP'), findsOneWidget);
    expect(find.text('Send SMS'), findsNothing);
  });
}
