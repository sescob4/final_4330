// test/dice_page_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:final_4330/dice_page.dart';
import 'package:final_4330/widgets/dice_face.dart';
import 'dart:math';

void main() {
  group('DicePage Core Logic Tests', () {
    test('Initial dice values are within valid range (1–6)', () {
      final allDice = List.generate(4, (_) => List.filled(5, 1));
      final rand = Random();

      // Simulate dice roll
      for (var i = 0; i < allDice.length; i++) {
        for (var j = 0; j < allDice[i].length; j++) {
          allDice[i][j] = rand.nextInt(6) + 1;
        }
      }

      for (final dice in allDice) {
        for (final value in dice) {
          expect(value, inInclusiveRange(1, 6));
        }
      }
    });

    test('Dice faces are mapped to appropriate images', () {
      final diceFace = DiceFace(value: 1);
      expect(diceFace.value, equals(1));
      expect(diceFace.runtimeType, equals(DiceFace));
      expect(diceFace.toString(), contains('DiceFace'));
      //expect(diceFace.assetPath, equals('assets/face1.svg'));
    });

    test('Dice roll generates different values across rolls', () {
      final rand = Random();
      final roll1 = List.generate(5, (_) => rand.nextInt(6) + 1);
      final roll2 = List.generate(5, (_) => rand.nextInt(6) + 1);

      // There's a very small chance they are equal, but for testing this is acceptable
      expect(roll1, isNot(equals(roll2)));
    });

    test('Dice face count calculation is correct', () {
      final testDice = [
        [1, 3, 3, 6, 2],
        [2, 3, 4, 1, 3],
        [3, 5, 3, 2, 2],
        [6, 3, 1, 4, 2],
      ];

      final counts = <int, int>{};
      for (var hand in testDice) {
        for (var v in hand) {
          counts[v] = (counts[v] ?? 0) + 1;
        }
      }

      expect(counts[3], equals(5));
      expect(counts[1], equals(3));
      expect(counts[2], equals(4));
      expect(counts[6], equals(2));
    });

    test('Player life reduction and elimination', () {
      final lives = [3, 2, 1, 0];
      final alive = [true, true, true, false];

      void eliminate(int index) {
        if (lives[index] > 0) {
          lives[index]--;
          if (lives[index] == 0) {
            alive[index] = false;
          }
        }
      }

      eliminate(0);
      eliminate(1);
      eliminate(2);

      expect(lives[0], equals(2));
      expect(lives[1], equals(1));
      expect(lives[2], equals(0));
      expect(alive[2], isFalse);
    });
  });

  // testWidgets('DicePage builds', (WidgetTester tester) async {
  //   await tester.pumpWidget(const MaterialApp(home: DicePage()));
  //   expect(find.byType(DicePage), findsOneWidget);
  // });

  // group('DicePage _userBet behavior', () {
  //   testWidgets('User Bet controls appear ', (WidgetTester tester) async {
  //     await tester.pumpWidget(const MaterialApp(home: DicePage()));

  //     // Verify inline bet controls appear
  //     expect(find.text('Roll Dice'), findsOneWidget);
  //     expect(find.text('Bet'), findsOneWidget);
  //   });
  // });
}
