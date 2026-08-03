import 'package:flutter_test/flutter_test.dart';

import 'package:pesaplan/app/app.dart';

void main() {
  testWidgets('Pesaplan app renders the welcome screen', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Pesaplan'), findsOneWidget);
  });
}
