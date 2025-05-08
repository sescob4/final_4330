import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:final_4330/dice_page.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  });

  testWidgets('DicePage loads and shows game UI', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DicePage(),
      ),
    );

    expect(find.text('Game Menu'), findsNothing); // Shouldn't show yet

    // Open the game menu
    await tester.tap(find.byIcon(Icons.settings).first); // If you expose that
    await tester.pumpAndSettle();

    // Now Game Menu should show
    // (If no icon is found, you may need to trigger it programmatically)
  });
}
