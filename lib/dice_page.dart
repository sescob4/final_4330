import 'dart:math';
import 'package:flutter/material.dart';
import 'widgets/dice_face.dart';

class Dice_page extends StatefulWidget {
  const Dice_page({super.key});

  @override
  State<Dice_page> createState() => _DiceRollerPageState();
}

class _DiceRollerPageState extends State<Dice_page>
    with SingleTickerProviderStateMixin {
  int diceValue = 1;
  final random = Random();
  late AnimationController _controller;
  late Animation<double> _animation;

  void rollDice() {
    _controller.forward(from: 0);
    setState(() {
      diceValue = random.nextInt(6) + 1;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
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
      backgroundColor: Colors.brown.shade900,
      appBar: AppBar(
        title: const Text("Dice Game"),
        backgroundColor: Colors.brown.shade700,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: DiceFace(value: diceValue),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: rollDice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.brown.shade900,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              ),
              child: const Text("Roll Dice", style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
      ),
    );
  }
}
