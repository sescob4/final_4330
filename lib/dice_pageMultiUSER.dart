import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:final_4330/Databaseservice.dart';
import 'package:firebase_database/firebase_database.dart';

class DicePageMultiUSER extends StatefulWidget {
  final String userID;
  final String gameID;
  

  const DicePageMultiUSER({super.key, required this.userID, required this.gameID});

  @override
  State<DicePageMultiUSER> createState() => _DicePageMultiUSERState();
}

class _DicePageMultiUSERState extends State<DicePageMultiUSER> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _controller;
  late Animation<double> _animation;
  List<int> _diceValues = [];
  bool _isRolling = false;
  String? _currentPlayer;
  StreamSubscription<DatabaseEvent>? _turnSubscription;
  StreamSubscription<DatabaseEvent>? _betSub;
  int? _bidQuantity;
  int? _bidFace;

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
    final ref = FirebaseDatabase.instance.ref("dice/gameSessions/${widget.gameID}/currentPlayer");
    _turnSubscription = ref.onValue.listen((event) {
      setState(() {
        _currentPlayer = event.snapshot.value?.toString();
      });
    });
  }

void _listenToBetChanges() {
  final ref = FirebaseDatabase.instance
    .ref("dice/gameSessions/${widget.gameID}/betDeclared");
  _betSub = ref.onValue.listen((evt) {
    final v = evt.snapshot.value;
    if (v is List && v.length == 2) {
      setState(() {
        _bidQuantity = v[0] as int;
        _bidFace     = v[1] as int;
      });
    }
  });
}

Future<void> _callBluff() async {
  if (_currentPlayer != widget.userID || _bidQuantity == null) return;

  // 1) Check the bet
  final wasCorrect = await _dbService.checkDiceCall(widget.userID, widget.gameID);
  final msg = wasCorrect
    ? 'Call failed: bet was correct!'
    : 'You caught a bluff!';

  // 2) Show the result
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg))
  );

  // 3) Clear local bet state
  setState(() {
    _bidQuantity = null;
    _bidFace     = null;
  });

  // 4) Advance the turn in the DB
  await _dbService.setPlayer(widget.userID, widget.gameID);
}


  Future<void> _rollDice() async {
  // 1) only the current player can roll
  if (_currentPlayer != widget.userID) return;

  setState(() => _isRolling = true);
  _controller.forward(from: 0);
  await Future.delayed(const Duration(milliseconds: 800));

  // 2) use your real writeDiceForAll:
  await _dbService.writeDiceForAll(widget.userID, widget.gameID);

  // 3) fetch *your* new dice faces:
  final mine = await _dbService.getDice(widget.userID, widget.gameID);
  setState(() => _diceValues = mine);

  // 4) rotate the turn:
  await _dbService.setPlayer(widget.userID, widget.gameID);

  setState(() => _isRolling = false);
}

  

  @override
  void dispose() {
    _controller.dispose();
    _turnSubscription?.cancel();
    super.dispose();
    _betSub?.cancel();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/table1.png',
            fit: BoxFit.cover,
          ),
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
                fontWeight: FontWeight.bold
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
              children: _diceValues.map((d) => _buildDiceFace(d)).toList(),
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

          ElevatedButton(
            onPressed: _isRolling ? null : _rollDice,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text("Roll Dice"),
            ),

            // ─── Roll Dice Button ───────────────────────────────
            ElevatedButton(
              onPressed: _isRolling ? null : _rollDice,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
              child: const Text("Roll Dice"),
            ),

            // ─── Place Bet Button ───────────────────────────────
            if (!_isRolling && _currentPlayer == widget.userID)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  onPressed: _showBetDialog,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: Text(
                    _bidQuantity != null
                      ? "Bet: ${_bidQuantity}×${_bidFace}"
                      : "Place Bet"
                  ),
                ),
              ),

            // ─── Call Bluff Button ───────────────────────────────
            if (!_isRolling && _currentPlayer == widget.userID && _bidQuantity != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  onPressed: _callBluff,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text("Call Bluff"),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}


  Widget _buildDiceFace(int value) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Text(
          value.toString(),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }


  /// Push a new bet [qty] × [face] into the DB, then advance the turn.
Future<void> _placeBet(int qty, int face) async {
  if (_currentPlayer != widget.userID) return;      // only on your turn

  // 1) write the bet + advance turn in the DB
  await _dbService.placeDiceBet(widget.userID, widget.gameID, qty, face);

  // 2) (optional) explicitly rotate here if placeDiceBet didn't:
  // await _dbService.setPlayer(widget.userID, widget.gameID);

  // 3) update your local state so UI shows the new bet immediately
  setState(() {
    _bidQuantity = qty;
    _bidFace     = face;
  });
}


void _showBetDialog() {
  int qty  = 1;
  int face = 1;
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Place Your Bet"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Text("Qty:"),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: qty,
            items: List.generate( (5*4)+1, (i)=> i+1 )
                     .map((n) => DropdownMenuItem(value: n, child: Text("$n"))).toList(),
            onChanged: (v) => qty = v!,
          )
        ]),
        Row(children: [
          const Text("Face:"),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: face,
            items: List.generate(6, (i)=> i+1)
                     .map((n) => DropdownMenuItem(value: n, child: Text("$n"))).toList(),
            onChanged: (v) => face = v!,
          )
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: () {
            _placeBet(qty, face);
            Navigator.pop(context);
          },
          child: const Text("Bet"),
        ),
      ],
    ),
  );
}

// Future<void> _callBluff() async {
//   // only while there’s a bet outstanding
//   if (_bidQuantity == null) return;

//   final wasTrue = await _dbService.checkDiceCall(widget.userID, widget.gameID);
//   final msg = wasTrue
//     ? "Bluff failed—bet was correct!"
//     : "Bluff succeeded—bet was false!";
//   ScaffoldMessenger.of(context)
//     .showSnackBar(SnackBar(content: Text(msg)));

//   // advance to next round (you'll want to reset _bidQuantity/_bidFace)
//   setState(() {
//     _bidQuantity = null;
//     _bidFace     = null;
//   });
//   await _dbService.setPlayer(widget.userID, widget.gameID);
// }

// In your DBService, add:
Future<void> clearBet(String gameID) async {
  await FirebaseDatabase.instance
    .ref("dice/gameSessions/$gameID")
    .update({"betDeclared": [0,0]});
}



}
