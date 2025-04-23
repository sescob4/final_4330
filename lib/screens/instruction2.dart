import 'package:flutter/material.dart';

//basic layout, need to add design later
class Instruction2 extends StatelessWidget {
  const Instruction2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 50, 31, 28),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.amber),
                        onPressed: () => Navigator.pop(context),
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
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(33, 17, 0, 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.amber.shade800,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(33, 17, 0, 0.8),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              SizedBox(width: 10),
                              Text(
                                "Game Overview",
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black,
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInstructionSection(
                            "The Basic",
                            "A classic twist on Liar's Dice! Guess right, and everyone else pays the price.",
                          ),
                          const SizedBox(height: 20),
                          _buildInstructionSection(
                            "The Stakes",
                            "In this classic version, aside from calling a bluff or raising the bet, there's another option: If you believe the previous player's guess about the dice count is exactly right you say 'Spot On!' ",
                          ),
                          const SizedBox(height: 20),
                          _buildInstructionSection(
                            "Victory",
                            "If you are right, everyone else drinks a bottle of poison. Otherwise, you drink!                                                                             ",
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color.fromRGBO(0, 0, 0, 0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color:Colors.amber,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.3),
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
              fontSize: 20,
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
              fontSize: 16,
              height: 1.5,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}