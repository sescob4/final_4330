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

  const DicePageMultiUSER({
    super.key,
    required this.userID,
    required this.gameID,
  });

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
  int _lives = 0;
  int _previousLives = 0;
  bool _isFirstRoll = true;
  bool _justLostLife = false;

  StreamSubscription<DatabaseEvent>? _turnSubscription;
  StreamSubscription<DatabaseEvent>? _betSubscription;
  StreamSubscription<DatabaseEvent>? _diceSubscription;

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

    _loadInitialData();
    _listenToTurnChanges();
    _listenToBetChanges();
    _listenToDiceChanges();
  }

  Future<void> _loadInitialData() async {
    print("🔄 Loading initial data...");
    await _refreshDice();
    await _refreshLives();
    final cp = await _dbService.getCurrentTurnPlayer(widget.gameID);
    print("🎯 Current player from DB: $cp");
    setState(() => _currentPlayer = cp);
  }

  Future<void> _refreshDice() async {
    print("🎲 Refreshing dice...");
    final dice = await _dbService.getDice(widget.userID, widget.gameID);
    print("🎲 Dice values: $dice");
    setState(() => _diceValues = dice);
  }

  Future<void> _refreshLives() async {
    print("❤️ Refreshing lives...");
    final lives = await _dbService.getLifesDB(widget.userID, widget.gameID);
    print("❤️ Lives: $lives");
    setState(() {
      _previousLives = _lives;
      _lives = lives;
    });
  }

  void _listenToDiceChanges() {
    final ref = FirebaseDatabase.instance
        .ref("dice/gameSessions/${widget.gameID}/playersAndDice");
    _diceSubscription = ref.onValue.listen((evt) {
      final data = evt.snapshot.value;
      print("📡 Dice change detected: $data");
      if (data is Map && data[widget.userID] is List) {
        setState(() {
          _diceValues = List<int>.from(data[widget.userID] as List);
        });
      }
    });
  }

  void _listenToTurnChanges() {
    final ref = FirebaseDatabase.instance
        .ref("dice/gameSessions/${widget.gameID}/currentPlayer");

    _turnSubscription = ref.onValue.listen((evt) async {
      final cp = evt.snapshot.value?.toString();
      setState(() => _currentPlayer = cp);
      print("📍 Current player updated: $cp");

      if (cp == widget.userID) {
        _hasRolled = false;
        await _refreshLives(); // updates _lives and _previousLives

        if (_lives < _previousLives) {
          _justLostLife = true;
          _isFirstRoll = true;
          print("⚠️ You lost a life — need to roll before betting");
        }
      }
    });
  }


  void _listenToBetChanges() {
    final ref = FirebaseDatabase.instance
        .ref("dice/gameSessions/${widget.gameID}/betDeclared");
    _betSubscription = ref.onValue.listen((evt) {
      final v = evt.snapshot.value;
      print("💬 Bet changed: $v");
      setState(() {
        if (v is List && v.length == 2) {
          _bidQuantity = v[0] as int;
          _bidFace = v[1] as int;
        } else {
          _bidQuantity = null;
          _bidFace = null;
        }
      });
    });
  }

  Future<void> _rollDice() async {
    if (_currentPlayer != widget.userID) return;

    if (!_justLostLife && !_isFirstRoll && _hasRolled) {
      // Already rolled this round, skip
      return;
    }
    print("🎲 Rolling dice for ${widget.userID}");
    setState(() => _isRolling = true);

    _controller.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));

    if (_isFirstRoll || _justLostLife) {
      print("🔄 Re-rolling all players' dice");
      await _dbService.writeDiceForAll(widget.userID, widget.gameID);
      _isFirstRoll = false;
      _justLostLife = false;
    }

    final mine = await _dbService.getDice(widget.userID, widget.gameID);
    print("🎲 Rolled dice: $mine");
    setState(() {
      _diceValues = mine;
      _hasRolled = true;
      _isRolling = false;
    });
  }

  Future<void> _callBluff() async {
    if (_currentPlayer != widget.userID || _bidQuantity == null) return;
    print("🕵️‍♂️ Calling bluff");
    await _resolveCall();
  }

  Future<void> _resolveCall() async {
    final qty = _bidQuantity!;
    final face = _bidFace!;
    print("🧾 Resolving call: bet was $qty × $face");

    final refPlayers = FirebaseDatabase.instance
        .ref("dice/gameSessions/${widget.gameID}/playersAndDice");
    final snap = await refPlayers.once();
    final data = snap.snapshot.value;
    if (data is! Map) return;

    int actualCount = 0;
    for (var entry in (data as Map).entries) {
      final diceList = entry.value;
      if (diceList is List) {
        for (var d in List<int>.from(diceList)) {
          if (d == face) actualCount++;
        }
      }
    }
    print("📊 Actual count of face $face: $actualCount");

    final lastSnap = await FirebaseDatabase.instance
        .ref("dice/gameSessions/${widget.gameID}/lastPlayer")
        .once();
    final bettorId = lastSnap.snapshot.value?.toString();
    final callerId = widget.userID;
    final loserId = (actualCount >= qty) ? callerId : bettorId;
    if (loserId == null) return;

    final livesLeft = await _dbService.loseLifeDB(loserId, widget.gameID);
    print("☠️ $loserId lost a life. Remaining: $livesLeft");

    if (loserId == widget.userID) {
      _justLostLife = true;
    }

    setState(() {
      _bidQuantity = null;
      _bidFace = null;
      _hasRolled = false;
    });
    await _dbService.setPlayer(widget.userID, widget.gameID);
  }

  void _userBet() {
    if (!_hasRolled) return;
    _origQty = 0;
    _origFace = 0;
    _tempQty = 1;
    _tempFace = 1;
    _lockMode = _LockMode.none;
    print("🎯 Ready to place bet");
    setState(() => _showBetControls = true);
  }

  Future<void> _confirmBet() async {
    print("🎯 Confirming bet: $_tempQty × $_tempFace");

    // Optional: enforce increasing bet rule
    if (_bidQuantity != null) {
      final currentQty = _bidQuantity!;
      final currentFace = _bidFace!;
      final isInvalid = _tempQty < currentQty ||
          (_tempQty == currentQty && _tempFace <= currentFace);
      if (isInvalid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You must raise the bet!")),
        );
        return;
      }
    }

    await _dbService.placeDiceBet(
      widget.userID,
      widget.gameID,
      _tempQty,
      _tempFace,
    );

    // Set turn to next player
    await _dbService.setPlayer(widget.userID, widget.gameID);

    setState(() {
      _bidQuantity = _tempQty;
      _bidFace = _tempFace;
      _showBetControls = false;
      _hasRolled = false;
      _justLostLife = false;
      _isFirstRoll = false;
    });
  }



  void _cancelBet() {
    print("❌ Cancelled bet UI");
    setState(() => _showBetControls = false);
  }

  @override
  void dispose() {
    print("🧹 Disposing listeners and controller");
    _controller.dispose();
    _turnSubscription?.cancel();
    _betSubscription?.cancel();
    _diceSubscription?.cancel();
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
          _buildHeartBox(_lives),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Your Turn",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
              if (_currentPlayer == widget.userID &&
                  !_isRolling &&
                  !_hasRolled)
                ElevatedButton(
                  onPressed: _rollDice,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent),
                  child: const Text("Roll Dice"),
                ),
              const SizedBox(height: 12),
              if (_showBetControls)
                _buildInlineBetControls()
              else if (_currentPlayer == widget.userID && _hasRolled)
                ElevatedButton(
                  onPressed: _userBet,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber),
                  child: const Text("Place Bet"),
                ),
              const SizedBox(height: 12),
              if (_currentPlayer == widget.userID &&
                  _bidQuantity != null &&
                  !_showBetControls)
                ElevatedButton(
                  onPressed: _callBluff,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent),
                  child: const Text("Call Bluff"),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Adjust Your Bet",
            style: TextStyle(color: Colors.amber, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  const Text("Qty", style: TextStyle(color: Colors.white)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: () {
                          if (_tempQty > 1) {
                            setState(() => _tempQty--);
                          }
                        },
                      ),
                      Text(
                        '$_tempQty',
                        style: const TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          setState(() => _tempQty++);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  const Text("Face", style: TextStyle(color: Colors.white)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.white),
                        onPressed: () {
                          if (_tempFace > 1) {
                            setState(() => _tempFace--);
                          }
                        },
                      ),
                      Text(
                        '$_tempFace',
                        style: const TextStyle(color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          if (_tempFace < 6) {
                            setState(() => _tempFace++);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _confirmBet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text("Confirm"),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _cancelBet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text("Cancel"),
              ),
            ],
          ),
        ],
      ),
    );
  }


  /// Heart box showing current lives at top
  Widget _buildHeartBox(int lives) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.brown.shade800,
            border: Border(
              left: const BorderSide(color: Colors.amber, width: 3),
              right: const BorderSide(color: Colors.amber, width: 3),
              bottom: const BorderSide(color: Colors.amber, width: 3),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              lives,
              (_) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  Icons.favorite,
                  size: 30,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
