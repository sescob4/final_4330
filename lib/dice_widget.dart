import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiceRoller extends StatefulWidget {
  const DiceRoller({super.key});

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
         // ← swap the number for an SVG:
        SizedBox(
          width: 100,
          height: 100,
          child: SvgPicture.asset(
            'assets/face$_currentRoll.svg',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: _rollDice, child: const Text('Roll Dice')),
      ],
    );
  }
}