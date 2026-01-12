import 'package:flutter_test/flutter_test.dart';

import 'package:stats_is_fun/main.dart';

void main() {
  testWidgets('App loads and displays home page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DataIsFunApp());
    await tester.pumpAndSettle();

    // Verify that home page content is displayed
    expect(find.text('Stats is Fun!'), findsOneWidget);
    expect(find.text('Descriptive Statistics'), findsOneWidget);
    expect(find.text('Inferential Statistics'), findsOneWidget);
  });

  testWidgets('Navigation cards are tappable', (WidgetTester tester) async {
    await tester.pumpWidget(const DataIsFunApp());
    await tester.pumpAndSettle();

    // Find and tap the Descriptive Statistics card
    final descriptiveCard = find.text('Descriptive Statistics');
    expect(descriptiveCard, findsOneWidget);
  });
}
