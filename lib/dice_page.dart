import 'dart:math';
import 'package:flutter/material.dart';

class Dice_page extends StatefulWidget {
  const Dice_page({super.key});

  @override
  State<Dice_page> createState() => _DiceRollerPageState();
}

class _DiceRollerPageState extends State<Dice_page> {
  List<int> diceValues = [];

  void rollDice() {
    final random = Random();
    setState(() {
      diceValues = List.generate(5, (_) => random.nextInt(6) + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade900,
      appBar: AppBar(
        title: const Text("Dice Roller"),
        backgroundColor: Colors.brown.shade700,
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Just take the space it needs
              children: [
                // Dice Display
                Wrap(
                  spacing: 16,
                  children: diceValues.map((value) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade200,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        value.toString(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                // Roll Button
                ElevatedButton(
                  onPressed: rollDice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.brown.shade900,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 20),
                  ),
                  child: const Text(
                    "Roll Dice",
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
