import 'package:flutter_test/flutter_test.dart';
import 'package:zakerly/app/app.dart';

void main() {
  testWidgets('App starts and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ZakerlyApp());
    expect(find.text('Zakerly'), findsOneWidget);
  });
}
