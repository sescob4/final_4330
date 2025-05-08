import 'package:flutter_test/flutter_test.dart';
import 'package:final_4330/liars_deck_game_ai.dart';
import 'dart:math';

void main() {
  group('DeckCard Tests', () {
    test('assetPath is correct for each CardType', () {
      expect(DeckCard(CardType.ace).assetPath, 'assets/ace.svg');
      expect(DeckCard(CardType.king).assetPath, 'assets/king.svg');
      expect(DeckCard(CardType.queen).assetPath, 'assets/queen.svg');
      expect(DeckCard(CardType.joker).assetPath, 'assets/joker.svg');
    });
  });

  group('Player Tests', () {
    test('spin eliminates player correctly', () {
      final p = Player('Tester');
      final rng = Random(1);
      final eliminated = p.spin(rng);
      expect(p.rouletteChambers, 2);
      expect(p.eliminated, eliminated);
    });
  });

  group('LiarsDeckGameState Tests', () {
    test('startRound assigns cards properly', () {
      final game = LiarsDeckGameState();
      final players = game.players.where((p) => !p.eliminated);
      for (final p in players) {
        expect(p.hand.length, LiarsDeckGameState.cardsPerPlayer);
      }
      expect(game.tableCards, isEmpty);
      expect(game.roundOver, isFalse);
    });

    test('advanceTurn skips eliminated players', () {
      final game = LiarsDeckGameState();
      game.players[1].eliminated = true;
      final current = game.currentPlayer;
      game.advanceTurn();
      expect(game.currentPlayer != 1, true);
    });

    test('playCards updates player hand and tableCards', () {
      final game = LiarsDeckGameState();
      final player = game.players[0];
      final cardsToPlay = player.hand.take(2).toList();
      final handBefore = player.hand.length;
      final msg = game.playCards(player, cardsToPlay);
      expect(player.hand.length, handBefore - cardsToPlay.length);
      expect(game.tableCards, equals(cardsToPlay));
      expect(msg.contains(player.name), true);
    });

    test('callBluff logic and state update', () {
      final game = LiarsDeckGameState();
      final player = game.players[0];
      final correctCard = DeckCard(game.tableType);
      game.playCards(player, [correctCard]);
      final result = game.callBluff(game.players[1]);
      expect(game.roundOver, isTrue);
      expect(result.contains('called bluff'), isTrue);
    });
  });
}
