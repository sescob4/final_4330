import 'package:final_4330/main.dart';
import 'package:flutter/material.dart';
import 'game_selection_screen.dart';
import 'game_selection_screen2.dart';
import 'package:audioplayers/audioplayers.dart';
//needs more UI design

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  int? hoveredRoleIndex;
  int? selectedRoleIndex;

  final AudioPlayer player = AudioPlayer();
  final List<Map<String, String>> roles = const [
    {"name": "Girl", "image": "assets/role1.png"},
    {"name": "Bartender", "image": "assets/role2.png"},
    {"name": "Outlaw", "image": "assets/role3.png"},
    {"name": "Sheriff", "image": "assets/role4.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.amberAccent),
            onPressed: () async {
              await player.play(AssetSource('sound/click-4.mp3'));
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            }),
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
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Wrap(
                      spacing: 30,
                      runSpacing: 30,
                      children: List.generate(roles.length, (index) {
                        final role = roles[index];
                        final isHovered = hoveredRoleIndex == index;

                        return MouseRegion(
                          onEnter: (_) => setState(() => hoveredRoleIndex = index),
                          onExit: (_) => setState(() => hoveredRoleIndex = null),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => selectedRoleIndex = index);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GameSelectionPage2(),
                                ),
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isHovered ? Colors.amberAccent : Colors.transparent,
                                      width: 4,
                                    ),
                                    boxShadow: isHovered
                                        ? [
                                            BoxShadow(
                                              color: Colors.amber.withOpacity(0.6),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            )
                                          ]
                                        : [],
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
                          ),
                        );
                      }),
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
