// lib/screens/dice_page_multiuser.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:final_4330/Databaseservice.dart';
import 'package:firebase_database/firebase_database.dart';
import 'widgets/dice_face.dart';

// Inline bet control modes
enum _LockMode { none, qty, face }
const int numPlayers = 4;
const int dicePerPlayer = 5;

class DicePageMultiUSER extends StatefulWidget {
  final String userID;
  final String gameID;

  const DicePageMultiUSER({super.key, required this.userID, required this.gameID});

  @override
  State<DicePageMultiUSER> createState() => _DicePageMultiUSERState();
}

class _DicePageMultiUSERState extends State<DicePageMultiUSER>
    with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _controller;
  late Animation<double> _animation;

  List<int> _diceValues = [];
  bool _isRolling = false;
  bool _hasRolled = false;
  String? _currentPlayer;

  StreamSubscription<DatabaseEvent>? _turnSubscription;
  StreamSubscription<DatabaseEvent>? _betSubscription;

  int? _bidQuantity;
  int? _bidFace;

  // Inline bet UI state
  bool _showBetControls = false;
  _LockMode _lockMode = _LockMode.none;
  late int _tempQty, _tempFace, _origQty, _origFace;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _loadGameData();
    _listenToTurnChanges();
    _listenToBetChanges();
  }

  Future<void> _loadGameData() async {
    final dice = await _dbService.getDice(widget.userID, widget.gameID);
    final currentPlayer = await _dbService.getCurrentTurnPlayer(widget.gameID);
    setState(() {
      _diceValues = dice;
      _currentPlayer = currentPlayer;
    });
  }

  void _listenToTurnChanges() {
  final ref = FirebaseDatabase.instance
      .ref("dice/gameSessions/${widget.gameID}/currentPlayer");
  _turnSubscription = ref.onValue.listen((evt) {
    setState(() {
      _currentPlayer = evt.snapshot.value?.toString();
    });
  });
}

  void _listenToBetChanges() {
    final ref = FirebaseDatabase.instance
        .ref("dice/gameSessions/${widget.gameID}/betDeclared");
    _betSubscription = ref.onValue.listen((evt) {
      final v = evt.snapshot.value;
      if (v is List && v.length == 2) {
        setState(() {
          _bidQuantity = v[0] as int;
          _bidFace = v[1] as int;
        });
      } else {
        setState(() {
          _bidQuantity = 1;
          _bidFace = 1;
        });
      }
    });
  }

  Future<void> _rollDice() async {
    if (_currentPlayer != widget.userID) return;
    setState(() {
      _isRolling = true;
    });
    _controller.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));

    await _dbService.writeDiceForAll(widget.userID, widget.gameID);
    final mine = await _dbService.getDice(widget.userID, widget.gameID);

    

    setState(() {
      _diceValues = mine;
      _isRolling = false;
      _hasRolled = true;
    });
  }

  Future<void> _callBluff() async {
  if (_currentPlayer != widget.userID || _bidQuantity == null) return;
  await _resolveCall();
}


  Future<void> _resolveCall() async {
  final qty = _bidQuantity!;
  final face = _bidFace!;

  // 1) Load all players' dice
  final refPlayers = FirebaseDatabase.instance
      .ref("dice/gameSessions/${widget.gameID}/playersAndDice");
  final snap = await refPlayers.once();
  final data = snap.snapshot.value;
  if (data is! Map) return;

  // 2) Count how many of that face were rolled
  int actualCount = 0;
  for (var entry in data.entries) {
    final diceList = entry.value;
    if (diceList is List) {
      for (var d in List<int>.from(diceList)) {
        if (d == face) actualCount++;
      }
    }
  }

  // 3) Find who made the bet
  final lastSnap = await FirebaseDatabase.instance
      .ref("dice/gameSessions/${widget.gameID}/lastPlayer")
      .once();
  final bettorId = lastSnap.snapshot.value?.toString();

  // 4) Decide who loses a life
  final callerId = widget.userID;
  final loserId = (actualCount >= qty) ? callerId : bettorId;
  if (loserId == null) return;

  // 5) Subtract a life in the DB
  final livesLeft = await _dbService.loseLifeDB(loserId, widget.gameID);

  // 6) Notify everyone
  final youCalled = (loserId == callerId);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(
      youCalled
        ? "Your call was wrong! You lose a life ($livesLeft left)."
        : "Bluff caught! Opponent loses a life ($livesLeft left)."
    ),
  ));

  // 7) Reset local state
  setState(() {
    _bidQuantity = null;
    _bidFace = null;
    _hasRolled = false;
    _showBetControls = false;
  });

  // 8) Advance to next turn
  await _dbService.setPlayer(callerId, widget.gameID);
}

  void _userBet() {
    _origQty = 1;
    _origFace = 1;
    _tempQty = 1;
    _tempFace = 1;
    _lockMode = _LockMode.none;
    setState(() => _showBetControls = true);
  }

  Future<void> _confirmBet() async {
    await _dbService.placeDiceBet(
      widget.userID,
      widget.gameID,
      _tempQty,
      _tempFace,
    );
    setState(() {
      _bidQuantity = _tempQty;
      _bidFace = _tempFace;
      _showBetControls = false;
    });
  }

  void _cancelBet() {
    setState(() => _showBetControls = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    _turnSubscription?.cancel();
    _betSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/table1.png', fit: BoxFit.cover),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                "Your Turn",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Your Dice",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _diceValues.map((value) {
                  return ScaleTransition(
                    scale: _animation,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: DiceFace(value: value),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              if (_bidQuantity != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Current Bet: ${_bidQuantity}×${_bidFace}",
                    style: const TextStyle(color: Colors.amber, fontSize: 16),
                  ),
                ),
              if (_currentPlayer == widget.userID && !_isRolling && !_hasRolled)
                ElevatedButton(
                  onPressed: _rollDice,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent),
                  child: const Text("Roll Dice"),
                ),
              const SizedBox(height: 12),
              if (_showBetControls)
                _buildInlineBetControls()
              else if (!_isRolling && _currentPlayer == widget.userID)
                ElevatedButton(
                  onPressed: _userBet,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber),
                  child: const Text("Place Bet"),
                ),
              if (!_isRolling &&
                  _currentPlayer == widget.userID &&
                  _bidQuantity != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ElevatedButton(
                    onPressed: _callBluff,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent),
                    child: const Text("Call Bluff"),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInlineBetControls() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.brown.shade800,
        border: Border.all(color: Colors.amber),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Qty display
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.brown.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text('$_tempQty',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_drop_up, color: Colors.amber, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 20),
                onPressed: () {
                  setState(() {
                    _tempFace = _origFace;
                    _lockMode = _LockMode.qty;
                    if (_tempQty < dicePerPlayer * numPlayers) _tempQty++;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.arrow_drop_down, color: Colors.amber, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 20),
                onPressed: () {
                  setState(() {
                    _tempFace = _origFace;
                    _lockMode = _LockMode.qty;
                    if (_tempQty > _origQty + 1) _tempQty--;
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Text('×', style: TextStyle(color: Colors.amber, fontSize: 24)),
          const SizedBox(width: 8),
          // Face display
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.brown.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text('$_tempFace',
                  style: const TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_drop_up, color: Colors.amber, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 20),
                onPressed: () {
                  setState(() {
                    _tempQty = _origQty;
                    _lockMode = _LockMode.face;
                    if (_tempFace < 6) _tempFace++;
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.arrow_drop_down, color: Colors.amber, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minHeight: 20),
                onPressed: () {
                  setState(() {
                    _tempQty = _origQty;
                    _lockMode = _LockMode.face;
                    if (_tempFace > _origFace + 1) _tempFace--;
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: (_tempQty > _origQty || _tempFace > _origFace || true)
                ? _confirmBet
                : null,
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            child: const Text('Confirm'),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _cancelBet,
            style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
