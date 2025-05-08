import 'dart:async';

import 'package:flutter/material.dart';
import 'package:final_4330/Databaseservice.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/animation.dart';

class LiarsDiceGamePage extends StatefulWidget {
  final String userID;
  final String gameID;

  const LiarsDiceGamePage({super.key, required this.userID, required this.gameID});

  @override
  State<LiarsDiceGamePage> createState() => _LiarsDiceGamePageState();
}

class _LiarsDiceGamePageState extends State<LiarsDiceGamePage> with SingleTickerProviderStateMixin {
  final DatabaseService _dbService = DatabaseService();
  late AnimationController _controller;
  late Animation<double> _animation;
  List<int> _diceValues = [];
  bool _isRolling = false;
  int _betAmount = 1;
  int _betFace = 1;
  String _statusMessage = '';
  String? _currentPlayer;
  StreamSubscription<DatabaseEvent>? _turnSubscription;

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

  Future<void> _rollDice() async {
    if (_currentPlayer != widget.userID) return;
    setState(() => _isRolling = true);
    _controller.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));


    await _dbService.writeDiceForAll(widget.userID, widget.gameID);
    final newDice = await _dbService.getDice(widget.userID, widget.gameID);
    setState(() {
      _diceValues = newDice;
      _isRolling = false;
    });
  }

  Future<void> _placeBet() async {
    if (_currentPlayer != widget.userID) return;
    await _dbService.placeDiceBet(widget.userID, widget.gameID, _betAmount, _betFace);
    setState(() {
      _statusMessage = "Bet Placed: $_betAmount of $_betFace";
    });
  }

  Future<void> _callBluff() async {
    if (_currentPlayer != widget.userID) return;
    final success = await _dbService.checkDiceCall(widget.userID, widget.gameID);
    setState(() {
      _statusMessage = success ? "Bluff failed! Enough dice found." : "Bluff successful! Not enough dice.";
    });
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

  @override
  void dispose() {
    _controller.dispose();
    _turnSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMyTurn = _currentPlayer == widget.userID;
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      appBar: AppBar(
        title: const Text("Liar's Dice Game"),
        backgroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              isMyTurn ? "Your Turn" : "Waiting for Turn...",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Your Dice", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _diceValues.map((d) => _buildDiceFace(d)).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isMyTurn && !_isRolling ? _rollDice : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
              child: const Text("Roll Dice"),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Amount:", style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _betAmount,
                  dropdownColor: Colors.black,
                  items: List.generate(10, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                  onChanged: isMyTurn ? (val) => setState(() => _betAmount = val ?? 1) : null,
                ),
                const SizedBox(width: 20),
                const Text("Face:", style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _betFace,
                  dropdownColor: Colors.black,
                  items: List.generate(6, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                  onChanged: isMyTurn ? (val) => setState(() => _betFace = val ?? 1) : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isMyTurn ? _placeBet : null,
              child: const Text("Place Bet"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isMyTurn ? _callBluff : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("Call Bluff"),
            ),
            const SizedBox(height: 20),
            Text(_statusMessage, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
