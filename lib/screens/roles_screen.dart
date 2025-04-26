import 'package:flutter/material.dart';
import 'game_selection_screen.dart';

//only initail update, 
//this page need a full body image for the character display and more UI design

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  final List<Map<String, String>> roles = const [
    {"name": "Cowboy", "image": "assets/cowboy.png"},
    {"name": "Girl", "image": "assets/galexport.png"},
    {"name": "Lawman", "image": "assets/lawman.png"},
    {"name": "Outlaw", "image": "assets/outlaw.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/emptybar.png',
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay to make characters pop
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // Role selection content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Select Your Role',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD580),
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black87,
                        offset: Offset(2, 2),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 30,
                      runSpacing: 30,
                      children: roles.map((role) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                //pass the selected role if needed
                                builder: (context) => GameSelectionPage(), 
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black45,
                                      blurRadius: 10,
                                      offset: Offset(4, 4),
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: 120,
                                  height: 160,
                                  child: Character(role["image"]!),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                role["name"]!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amberAccent,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
}
class Character extends StatelessWidget {
  final String imagePath;

  const Character(this.imagePath, {super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
      ),
    );
  }
}
