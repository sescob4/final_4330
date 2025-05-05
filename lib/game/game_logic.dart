import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

enum LockMode { none, qty, face }

class GameLogic {
  static const int numPlayers = 4;
  static const int dicePerPlayer = 5;
  
  // Animation settings
  final Duration rollAnimDuration = const Duration(milliseconds: 1000);
  final Duration rollAnimInterval = const Duration(milliseconds: 50);
  
  // Game state
  List<List<int>> allDice = [];
  List<bool> alive = [];
  List<int> lives = [];
  int turnIndex = 0;
  bool hasRolled = false;
  int? bidQuantity;
  int? bidFace;
  bool rolling = false;
  
  // Betting state
  bool showBetControls = false;
  int tempQty = 0;
  int tempFace = 1;
  int origQty = 0;
  int origFace = 1;
  LockMode lockMode = LockMode.none;
  
  // History
  final List<String> history = [];
  final Random rand = Random();
  
  GameLogic() {
    initGameState();
  }
  
  void initGameState() {
    allDice = List.generate(numPlayers, (_) => List.filled(dicePerPlayer, 1));
    alive = List.filled(numPlayers, true);
    lives = List.filled(numPlayers, 3);
    turnIndex = 0;
    hasRolled = false;
    bidQuantity = null;
    bidFace = null;
    showBetControls = false;
    history.clear();
  }

  // Dice rolling methods
  void updateDiceRoll() {
    allDice[0] = List.generate(dicePerPlayer, (_) => rand.nextInt(6) + 1);
  }

  void finalizeDiceRoll(List<int> finalRoll) {
    allDice[0] = finalRoll;
    rolling = false;
    hasRolled = true;
  }

  // Betting methods
  void prepareBet() {
    tempQty = bidQuantity ?? 1;
    tempFace = bidFace ?? 1;
    origQty = tempQty;
    origFace = tempFace;
    lockMode = LockMode.none;
  }

  void confirmBet() {
    bidQuantity = tempQty;
    bidFace = tempFace;
    showBetControls = false;
    hasRolled = true;
    turnIndex = nextTurn();
  }

  void incrementTempQty() {
    if (tempQty < numPlayers * dicePerPlayer && lockMode != LockMode.face) {
      tempQty++;
      lockMode = LockMode.qty;
    }
  }

  void decrementTempQty() {
    if (tempQty > (bidQuantity ?? 0) + 1 && lockMode != LockMode.face) {
      tempQty--;
      lockMode = LockMode.qty;
    }
  }

  void incrementTempFace() {
    if (tempFace < 6 && lockMode != LockMode.qty) {
      tempFace++;
      lockMode = LockMode.face;
    }
  }

  void decrementTempFace() {
    if (tempFace > (bidFace ?? 1) + 1 && lockMode != LockMode.qty) {
      tempFace--;
      lockMode = LockMode.face;
    }
  }

  // CPU Actions
  void cpuAction() {
    if (!alive[turnIndex]) {
      turnIndex = nextTurn();
      cpuAction();
      return;
    }

    if (shouldCpuCall()) {
      resolveCall(turnIndex);
    } else {
      final bet = generateCpuBet();
      bidQuantity = bet['quantity'];
      bidFace = bet['face'];
      turnIndex = nextTurn();
      Future.delayed(const Duration(milliseconds: 400), cpuAction);
    }
  }

  void addLog(String entry) {
    history.add(entry);
  }
  
  List<int> rollDice() {
    return List.generate(dicePerPlayer, (_) => rand.nextInt(6) + 1);
  }
  
  bool shouldCpuCall() {
    if (bidQuantity == null || bidFace == null) return false;
    final totalDice = numPlayers * dicePerPlayer;
    final expected = totalDice / 6;
    final rawChance = (bidQuantity! - expected) / (totalDice - expected);
    return rand.nextDouble() < rawChance.clamp(0.0, 1.0);
  }
  
  Map<String, int> generateCpuBet() {
    final oldQty = bidQuantity ?? 0;
    final oldFace = bidFace ?? 1;
    bool raiseQty = rand.nextBool();
    if (!raiseQty && oldFace >= 6) raiseQty = true;
    
    return {
      'quantity': raiseQty ? oldQty + 1 : oldQty,
      'face': raiseQty ? oldFace : min(oldFace + 1, 6),
    };
  }
  
  Map<String, dynamic> resolveCall(int caller) {
    final counts = <int, int>{};
    for (var hand in allDice) {
      for (var v in hand) {
        counts[v] = (counts[v] ?? 0) + 1;
      }
    }
    
    final qty = bidQuantity!;
    final face = bidFace!;
    final actual = counts[face] ?? 0;
    final last = (turnIndex + numPlayers - 1) % numPlayers;
    final loser = actual < qty ? last : caller;
    
    lives[loser]--;
    if (lives[loser] <= 0) {
      alive[loser] = false;
    }
    
    return {
      'loser': loser,
      'actual': actual,
      'needed': qty,
      'face': face,
    };
  }
  
  int nextTurn() {
    do {
      turnIndex = (turnIndex + 1) % numPlayers;
    } while (!alive[turnIndex]);
    return turnIndex;
  }
  
  bool isGameOver() {
    int alivePlayers = alive.where((a) => a).length;
    return alivePlayers <= 1;
  }
}