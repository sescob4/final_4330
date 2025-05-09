import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'instruction.dart'; // Make sure this path is correct for your project

class Instruction2 extends StatelessWidget {
  const Instruction2({super.key});

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
                        "Welcome to Liar's Dice",
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
                              builder: (context) => const Instruction(),
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
                      border: Border.all(color: Colors.amber.shade800, width: 2),
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
                              "A classic twist on Liar's Dice! Roll your dice in secret and make bold claims about the total. Challenge others' claims or raise the stakes. The art of deception is your greatest weapon.",
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInstructionSection(
                              "The Stakes",
                              "Aside from calling a bluff or raising the bet, there's another option: If you believe the previous player's guess about the dice count is exactly right you say 'Spot On!' The tension rises with each round.",
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInstructionSection(
                              "Victory",
                              "If you are right, everyone else drinks a bottle of poison. Otherwise, you drink! Master the balance of truth and deception to outlast your opponents and claim victory in this game of chance.",
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 0, 0, 0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber, width: 1),
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
              fontSize: 17.5,
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
          const SizedBox(height: 7),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              height: 1.4,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
