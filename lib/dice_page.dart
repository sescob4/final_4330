import 'dart:math';
import 'package:flutter/material.dart';
import 'widgets/dice_face.dart'; // your existing DiceFace widget

class DicePage extends StatefulWidget {
  const DicePage({super.key});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage>
    with SingleTickerProviderStateMixin {
  late List<int> diceValues;
  final random = Random();

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    diceValues = List.generate(5, (_) => 1);
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

  void rollDice() {
    _controller.forward(from: 0);
    setState(() {
      diceValues = List.generate(5, (_) => random.nextInt(6) + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown.shade900,
      appBar: AppBar(
        title: const Text("Liar's Dice Demo"),
        backgroundColor: Colors.brown.shade700,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top player
            PlayerArea(name: 'Player 3', isCurrent: false),
            const SizedBox(height: 24),

            // Middle row: left, you, right
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left opponent
                const PlayerArea(name: 'Player 2', isCurrent: false),
                const SizedBox(width: 24),

                // You (current player)
                Column(
                  children: [
                    ScaleTransition(
                      scale: _animation,
                      child: PlayerArea(
                        name: 'You',
                        isCurrent: true,
                        diceValues: diceValues,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: rollDice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.brown.shade900,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                      ),
                      child: const Text("Roll Dice",
                          style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),

                const SizedBox(width: 24),
                // Right opponent
                const PlayerArea(name: 'Player 4', isCurrent: false),
              ],
            ),
            const SizedBox(height: 24),

            // Bottom player
            const PlayerArea(name: 'Player 5', isCurrent: false),
          ],
        ),
      ),
    );
  }
}

// Widget to display a hand (either visible or covered)
class PlayerArea extends StatelessWidget {
  final String name;
  final bool isCurrent;
  final List<int>? diceValues;

  const PlayerArea({
    required this.name,
    required this.isCurrent,
    this.diceValues,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final diceWidgets = isCurrent
        ? diceValues!
            .map((v) => DiceFace(value: v))
            .toList()
        : List.generate(5, (_) => const CoveredDice());

    return Column(
      children: [
        Text(name,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(mainAxisSize: MainAxisSize.min, children: diceWidgets),
      ],
    );
  }
}

// A “covered” die showing a placeholder instead of its face
class CoveredDice extends StatelessWidget {
  const CoveredDice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Icon(Icons.help_outline, color: Colors.white, size: 28),
      ),
    );
  }
}
