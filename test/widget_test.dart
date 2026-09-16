import 'package:flutter_test/flutter_test.dart';
import 'package:timbitwire_school/main.dart';

void main() {
  testWidgets('Login screen renders in demo mode', (tester) async {
    await tester.pumpWidget(const TimbitwireApp());
    await tester.pump();
    expect(find.text('Sign in'), findsOneWidget);
  });
}
