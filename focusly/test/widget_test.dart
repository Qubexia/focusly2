import 'package:flutter_test/flutter_test.dart';
import 'package:focusly/app/app.dart';

void main() {
  testWidgets('App starts and shows splash', (WidgetTester tester) async {
    await tester.pumpWidget(const FocuslyApp());
    expect(find.text('Focusly'), findsOneWidget);
  });
}
