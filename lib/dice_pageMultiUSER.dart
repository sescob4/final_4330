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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _loadDice();
  }

  Future<void> _loadDice() async {
    final dice = await _dbService.getDice(widget.userID, widget.gameID);
    setState(() {
      _diceValues = dice;
    });
  }

  Future<void> _rollDice() async {
    setState(() => _isRolling = true);
    _controller.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 800));

    final newDice = await _dbService.writeDiceForAll(widget.userID, widget.gameID);
    setState(() {
      _diceValues = newDice;
      _isRolling = false;
    });
  }

  Future<void> _placeBet() async {
    await _dbService.placeDiceBet(widget.userID, widget.gameID, _betAmount, _betFace);
    setState(() {
      _statusMessage = "Bet Placed: $_betAmount of $_betFace";
    });
  }

  Future<void> _callBluff() async {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            Text("Your Dice", style: Theme.of(context).textTheme.headline6?.copyWith(color: Colors.white)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _diceValues.map((d) => _buildDiceFace(d)).toList(),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _isRolling ? null : _rollDice,
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
                  onChanged: (val) => setState(() => _betAmount = val ?? 1),
                ),
                const SizedBox(width: 20),
                const Text("Face:", style: TextStyle(color: Colors.white)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _betFace,
                  dropdownColor: Colors.black,
                  items: List.generate(6, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                  onChanged: (val) => setState(() => _betFace = val ?? 1),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _placeBet,
              child: const Text("Place Bet"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _callBluff,
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
