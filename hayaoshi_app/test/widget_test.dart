import 'package:flutter_test/flutter_test.dart';

import 'package:hayaoshi_app/main.dart';

void main() {
  testWidgets('Home screen shows host/client buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const HayaoshiApp());

    expect(find.text('親機として始める'), findsOneWidget);
    expect(find.text('子機として参加する'), findsOneWidget);
  });
}
