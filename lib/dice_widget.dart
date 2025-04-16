import 'dart:math';
import 'package:flutter/material.dart';

class DiceRoller extends StatefulWidget {
  @override
  _DiceRollerState createState() => _DiceRollerState();
}

class _DiceRollerState extends State<DiceRoller> {
  int _currentRoll = 1;
  final _random = Random();

  void _rollDice() {
    setState(() {
      _currentRoll = _random.nextInt(6) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'You rolled:',
          style: TextStyle(fontSize: 24),
        ),
        SizedBox(height: 16),
        Text(
          '$_currentRoll',
          style: TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 32),
        ElevatedButton(
          onPressed: _rollDice,
          child: Text('Roll Dice'),
        ),
      ],
    );
  }
}
