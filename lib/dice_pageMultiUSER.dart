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

  int _lives = 0;
  int _prevLives = 0;
  bool _justLostLife = false;

  StreamSubscription<DatabaseEvent>? _diceSubscription;
  StreamSubscription<DatabaseEvent>? _livesSubscription;
  StreamSubscription<DatabaseEvent>? _turnSubscription;
  StreamSubscription<DatabaseEvent>? _betSubscription;

  int? _bidQuantity;
  int? _bidFace;

  bool _showBetControls = false;
  late int _tempQty, _tempFace, _origQty, _origFace;
  _LockMode _lockMode = _LockMode.none;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _listenToDice();
    _listenToLives();
    _listenToTurnChanges();
    _listenToBetChanges();
  }

  /// Stream this player's dice array continuously
  void _listenToDice() {
    final ref = FirebaseDatabase.instance
        .ref('dice/gameSessions/${widget.gameID}/playersAndDice/${widget.userID}');
    _diceSubscription = ref.onValue.listen((evt) {
      final v = evt.snapshot.value;
      if (v is List) {
        setState(() => _diceValues = List<int>.from(v));
      }
    });
  }

  /// Stream this player's lives continuously
  void _listenToLives() {
    final ref = FirebaseDatabase.instance
        .ref('dice/gameSessions/${widget.gameID}/playersLife/${widget.userID}');
    _livesSubscription = ref.onValue.listen((evt) {
      final v = evt.snapshot.value;
      if (v is int) {
        setState(() {
          _lives = v;
          if (_prevLives > 0 && v < _prevLives) {
            _justLostLife = true;
          }
          _prevLives = v;
        });
      }
    });
  }

  void _listenToTurnChanges() {
    final ref = FirebaseDatabase.instance
        .ref('dice/gameSessions/${widget.gameID}/currentPlayer');
    _turnSubscription = ref.onValue.listen((evt) {
      final cp = evt.snapshot.value?.toString();
      setState(() {
        _currentPlayer = cp;
        if (cp == widget.userID) {
          _hasRolled = false;
          _justLostLife = false;
        }
      });
    });
  }

  void _listenToBetChanges() {
    final ref = FirebaseDatabase.instance
        .ref('dice/gameSessions/${widget.gameID}/betDeclared');
    _betSubscription = ref.onValue.listen((evt) {
      final v = evt.snapshot.value;
      setState(() {
        if (v is List && v.length == 2) {
          _bidQuantity = v[0] as int;
          _bidFace = v[1] as int;
        } else {
          _bidQuantity = 1;
          _bidFace = 1;
        }
      });
    });
  }

  /// Rolls or reads dice, then allows betting
    bool _creatorRolled = false;

  /// Rolls or reads dice, then allows betting
  Future<void> _rollDice() async {
    if (_currentPlayer != widget.userID) return;
    // Fetch creator ID
    final createdBySnap = await FirebaseDatabase.instance
        .ref('dice/gameSessions/${widget.gameID}/createdBy')
        .once();
    final creatorId = createdBySnap.snapshot.value?.toString();

    // Determine if we can randomize
    bool canRandomizeCreator = widget.userID == creatorId && !_creatorRolled;
    bool canRandomizeAfterLifeLoss = _justLostLife;
    final canRandomize = canRandomizeCreator || canRandomizeAfterLifeLoss;

    setState(() => _isRolling = true);
    _controller.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));

    if (canRandomize) {
      // Randomize and push new dice for everyone
      await _dbService.writeDiceForAll(widget.userID, widget.gameID);
      // Mark that creator has rolled once
      if (canRandomizeCreator) _creatorRolled = true;
      _justLostLife = false; // reset life-loss flag
    } else {
      // Just load the existing values
      final mine = await _dbService.getDice(widget.userID, widget.gameID);
      setState(() => _diceValues = mine);
    }

    // Enable betting after dice are in place
    setState(() {
      _hasRolled = true;
      _isRolling = false;
    });
  }

  Future<void> _resolveCall() async {
  final bool callerWasRight = await _dbService.checkDiceCall(widget.userID, widget.gameID);

  final lastSnap = await FirebaseDatabase.instance
      .ref("dice/gameSessions/${widget.gameID}/lastPlayer")
      .once();
  final String? bettorId = lastSnap.snapshot.value?.toString();
  final String callerId = widget.userID;

  final String? loserId = callerWasRight ? bettorId : callerId;
  if (loserId == null) return;

  final int livesLeft = await _dbService.loseLifeDB(loserId, widget.gameID);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        loserId == callerId
          ? "You lose a life! ($livesLeft left)"
          : "Opponent loses a life! ($livesLeft left)",
      ),
    ),
  );

  setState(() {
    _bidQuantity     = 1;
    _bidFace         = 1;
    _showBetControls = false;
    _hasRolled       = false;
  });


  await _dbService.setPlayer(widget.userID, widget.gameID);
}

  Future<void> _callBluff() async {
    if (_currentPlayer != widget.userID || _bidQuantity == null) return;
    await _resolveCall();
    await _dbService.setPlayer(widget.userID, widget.gameID);
  }

  void _userBet() {
  if (!_hasRolled) return;
  _origQty  = (_bidQuantity == null || _bidQuantity! < 1) ? 1 : _bidQuantity!;
  _origFace = (_bidFace     == null || _bidFace!     < 1) ? 1 : _bidFace!;
  _tempQty  = _origQty;
  _tempFace = _origFace;
  setState(() => _showBetControls = true);
}
    Future<void> _confirmBet() async {
    if (_currentPlayer != widget.userID) return;
    // Write the bet and advance turn
    await _dbService.placeDiceBet(
      widget.userID,
      widget.gameID,
      _tempQty,
      _tempFace,
    );
    // Rotate to next player
    await _dbService.setPlayer(widget.userID, widget.gameID);
    setState(() {
      _bidQuantity = _tempQty;
      _bidFace = _tempFace;
      _showBetControls = false;
      _hasRolled = false;
    });
  }

  void _cancelBet() => setState(() => _showBetControls = false);

  @override
  void dispose() {
    _controller.dispose();
    _diceSubscription?.cancel();
    _livesSubscription?.cancel();
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
          _buildHeartBox(_lives),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 20),
              Text('Your Turn', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Your Dice', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _diceValues.map((value) => ScaleTransition(
                      scale: _animation,
                      child: SizedBox(width: 60, height: 60, child: DiceFace(value: value)),
                    )).toList(),
              ),
              SizedBox(height: 30),
              if (_bidQuantity != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Current Bet: ${_bidQuantity}×${_bidFace}', style: TextStyle(color: Colors.amber, fontSize: 16)),
                ),
              if (_currentPlayer == widget.userID && !_isRolling && !_hasRolled)
                ElevatedButton(onPressed: _rollDice, style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent), child: Text('Roll Dice')),
              SizedBox(height: 12),
              if (_showBetControls) _buildInlineBetControls()
              else if (_currentPlayer == widget.userID && _hasRolled)
                ElevatedButton(onPressed: _userBet, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber), child: Text('Place Bet')),
              SizedBox(height: 12),
              if (_currentPlayer == widget.userID && _bidQuantity != null && !_showBetControls)
                ElevatedButton(onPressed: _callBluff, style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: Text('Call Bluff')),
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
        // Quantity
        Container(
          width: 40, height: 20,
          decoration: BoxDecoration(
            color: Colors.brown.shade700,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(child: Text('$_tempQty', style: const TextStyle(color: Colors.white, fontSize: 18))),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_drop_up, size: 20, color: Colors.amber),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(minHeight: 20),
              onPressed: () {
                setState(() {
                  _lockMode = _LockMode.qty;
                  if (_tempQty < dicePerPlayer * numPlayers) _tempQty++;
                  _tempFace = _origFace;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_drop_down, size: 20, color: Colors.amber),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(minHeight: 20),
              onPressed: () {
                setState(() {
                  _lockMode = _LockMode.qty;
                  if (_tempQty > _origQty) _tempQty--;
                  _tempFace = _origFace;
                });
              },
            ),
          ],
        ),

        const SizedBox(width: 8),
        const Text('×', style: TextStyle(color: Colors.amber, fontSize: 24)),
        const SizedBox(width: 8),

        // Face
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Colors.brown.shade700,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(child: Text('$_tempFace', style: const TextStyle(color: Colors.white, fontSize: 18))),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_drop_up, size: 20, color: Colors.amber),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(minHeight: 20),
              onPressed: () {
                setState(() {
                  _lockMode = _LockMode.face;
                  if (_tempFace < 6) _tempFace++;
                  _tempQty = _origQty;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_drop_down, size: 20, color: Colors.amber),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(minHeight: 20),
              onPressed: () {
                setState(() {
                  _lockMode = _LockMode.face;
                  if (_tempFace > _origFace) _tempFace--;
                  _tempQty = _origQty;
                });
              },
            ),
          ],
        ),

        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: ((_tempQty > _origQty && _tempFace == _origFace) ||
                      (_tempFace > _origFace && _tempQty == _origQty))
              ? _confirmBet
              : null,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          child: const Text('Confirm'),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: _cancelBet,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

  /// Heart box showing current lives at top
  Widget _buildHeartBox(int lives) {
    return Positioned(
      top: MediaQuery.of(context).padding.top,
      left: 0, right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical:6,horizontal:12),
          decoration: BoxDecoration(color:Colors.brown.shade800, border: Border(left:BorderSide(color:Colors.amber,width:3), right:BorderSide(color:Colors.amber,width:3), bottom:BorderSide(color:Colors.amber,width:3)), borderRadius: BorderRadius.only(bottomLeft:Radius.circular(16), bottomRight:Radius.circular(16))),
          child: Row(mainAxisSize:MainAxisSize.min, children:List.generate(lives,(_)=>Padding(padding:EdgeInsets.symmetric(horizontal:1),child:Icon(Icons.favorite,size:30,color:Colors.redAccent))))
        ),
      ),
    );
  }
}