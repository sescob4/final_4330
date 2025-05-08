import 'package:flutter/material.dart';
import 'package:final_4330/Databaseservice.dart';

class TestDiceFunctionsPage extends StatefulWidget {
  final String userID;
  final String gameID;

  const TestDiceFunctionsPage({
    super.key,
    required this.userID,
    required this.gameID,
  });

  @override
  State<TestDiceFunctionsPage> createState() => _TestDiceFunctionsPageState();
}

class _TestDiceFunctionsPageState extends State<TestDiceFunctionsPage> {
  final DatabaseService _db = DatabaseService();
  String _output = '';

  void _log(String message) {
    setState(() {
      _output += '$message\n';
    });
  }
  Future<void> _testWriteDice() async {
    await _db.writeDiceForAll(widget.userID, widget.gameID);
    final dice = _db.getDice(widget.userID,widget.gameID);
    _log('Dice written for ${widget.userID}: $dice ');
  }
  Future<void> _testPlaceBet() async {
    await _db.placeDiceBet(widget.userID, widget.gameID, 2, 5);
    _log('Bet placed: 2 of 5');
  }
  Future<void> _testCheckBluff() async {
    final result = await _db.checkDiceCall(widget.userID, widget.gameID);
    _log(result ? 'Bluff failed! (Bet was true)' : 'Bluff successful! (Bet was false)');
  }
  Future<void> _testTurnPlayer() async {
    final current = await _db.getCurrentTurnPlayer(widget.gameID);
    _log('Current Turn: $current');
  }

  Future<void> _testGetDice() async {
    final dice = await _db.getDice(widget.userID, widget.gameID);
    _log('Dice for ${widget.userID}: $dice');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Dice Function Tester")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(onPressed: _testWriteDice, child: const Text("Write Dice")),
                ElevatedButton(onPressed: _testPlaceBet, child: const Text("Place Bet")),
                ElevatedButton(onPressed: _testCheckBluff, child: const Text("Call Bluff")),
                ElevatedButton(onPressed: _testTurnPlayer, child: const Text("Current Turn")),
                ElevatedButton(onPressed: _testGetDice, child: const Text("Get Dice")),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                color: Colors.grey[900],
                child: SingleChildScrollView(
                  child: Text(
                    _output,
                    style: const TextStyle(color: Colors.white, fontFamily: 'Courier'),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }}
