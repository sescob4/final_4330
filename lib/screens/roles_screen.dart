import 'package:final_4330/Databaseservice.dart';
import 'package:final_4330/main.dart';
import 'package:flutter/material.dart';
import 'game_selection_screen.dart';
import 'game_selection_screen2.dart';
//needs more UI design

class RolesScreen extends StatelessWidget {
  const RolesScreen({super.key});

  final List<Map<String, String>> roles = const [
    {"name": "Girl", "image": "assets/role1.png"},
    {"name": "Bartender", "image": "assets/role2.png"},
    {"name": "Outlaw", "image": "assets/role3.png"},
    {"name": "Sheriff", "image": "assets/role4.png"},
  ];

  @override
  Widget build(BuildContext context) {
    int characterID = 0;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
    elevation: 0,
    backgroundColor: Colors.transparent,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.amberAccent),
      onPressed: () {
        Navigator.pop(context);
        Navigator.pushReplacementNamed(context, '/home');
      }
    ),
    centerTitle: true,
    title: const Text(
      'Select Your Role',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.amber,
        shadows: [
          Shadow(
            blurRadius: 10,
            color: Colors.black87,
            offset: Offset(2, 2),
          )
        ],
      ),
    ),
  ),
      
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/floor.png',
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
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 30,
                      runSpacing: 30,
                      children: roles.map((role) {
                        return GestureDetector(
                          onTap: () {
                            DatabaseService dp = new DatabaseService();
                            characterID = roles.indexOf(role);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                //pass the selected role if needed
                                builder: (context) => GameSelectionPage2(),
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
                                      color: Colors.transparent,
                                      blurRadius: 10,
                                      offset: Offset(4, 4),
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: 140,
                                  height: 250,
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
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
      ),
    );
  }
}
