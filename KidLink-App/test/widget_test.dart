import 'package:flutter_test/flutter_test.dart';
import 'package:kidlink_app/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const KidLinkApp());
    expect(find.text('Registrar en KidLink'), findsOneWidget);
  });
}
