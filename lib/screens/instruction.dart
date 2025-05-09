import 'package:flutter/material.dart';
import 'package:final_4330/screens/instruction2.dart';
import 'package:audioplayers/audioplayers.dart';

class Instruction extends StatelessWidget {
  const Instruction({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 31, 28),
      body: Stack(
        children: [
          Image.asset(
            'assets/wood.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.home, color: Colors.amber, size: 32),
                        onPressed: () {
                          final player = AudioPlayer();
                          player.play(AssetSource('sound/click-4.mp3'));
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                      ),
                      const Text(
                        "Welcome to Liar's Deck",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward, color: Colors.amber, size: 32),
                        onPressed: () {
                          final player = AudioPlayer();
                          player.play(AssetSource('sound/click-4.mp3'));
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Instruction2(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(33, 17, 0, 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.amber.shade800,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(33, 17, 0, 0.8),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildInstructionSection(
                              "The Basics",
                              "A twisted game of cards where every bluff could be your last! Play a card and claim its value. Be careful, your opponents might call your bluff!",
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInstructionSection(
                              "The Stakes",
                              "Get caught lying, and you'll play Russian Roulette. Survive the one bullet out of 6 rounds, or it's game over. The stakes are high, and every decision matters.",
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInstructionSection(
                              "Victory",
                              "Outlast everyone at the table to win. Will you dare to deceive? Master the art of bluffing and strategic play to emerge victorious in this game of deception.",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.amber,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              shadows: [
                Shadow(
                  blurRadius: 5.0,
                  color: Colors.black,
                  offset: Offset(1.0, 1.0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
