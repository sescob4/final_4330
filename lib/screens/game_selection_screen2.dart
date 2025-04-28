import 'package:flutter/material.dart';
import '../liars_deck_game_ai.dart';
import '/dice_page.dart';
import 'roles_screen.dart';
import '../widgets/frame_button.dart';


class GameSelectionPage2 extends StatelessWidget {
  const GameSelectionPage2({super.key});

  void _showGameMenu(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3E2723),
        title: const Text('Game Menu', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.settings, color: Colors.white),
              label:
                  const Text('Settings', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context);
                // Navigate to settings page when implemented
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.home, color: Colors.white),
              label: const Text('Main Menu',
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top + 8;
    final double buttonPadding =
        MediaQuery.of(context).size.width * 0.05; // 5% of screen width
    final double buttonCornerRadius = 20.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/table.png", fit: BoxFit.cover),
          ),
          // Menu button
          Positioned(
            top: topPadding,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 32),
              onPressed: () => _showGameMenu(context),
              tooltip: 'Game Menu',
            ),
          ),
          // Title
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "Choose Your Game",
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Game selection row
          Positioned.fill(
            top: topPadding + 70,
            child: Padding(
              padding: EdgeInsets.all(buttonPadding),
              child: Row(
                children: [
                  Expanded(
                    child: ImageButton(
                      label: "Liar's Deck",
                      scaleFactor: 30,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LiarsDeckGamePage()),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: buttonPadding),
                  Expanded(
                    child: ImageButton(
                      label: "Liar's Dice",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DicePage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
