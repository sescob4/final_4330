import 'package:flutter/material.dart';
import '../liars_deck_game_ai.dart';
import '/dice_page.dart';
import 'roles_screen.dart';
import '../Databaseservice.dart';

class GameSelectionPage extends StatelessWidget {
  const GameSelectionPage({super.key});

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
            /* This is commented out for now, but can be used later if needed
            TextButton.icon(
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Resume', 
                  style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context);
              },
            ), */
            TextButton.icon(
              icon: const Icon(Icons.settings, color: Colors.white),
              label:
                  const Text('Settings', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
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
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/table.png", fit: BoxFit.cover),
          ),
          // Menu button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 32),
              onPressed: () => _showGameMenu(context),
              tooltip: 'Game Menu',
            ),
          ),
          // Title
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
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
          // Game selection container
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.brown.shade800,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      //changed
                      final dbService = DatabaseService(); // new
                      String gameId = await dbService
                          .createNewGame(); //create a new game session
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LiarsDeckGamePage(
                                gameId: gameId)), //removed const
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.brown.shade900,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                    ),
                    child: const Text(
                      'Card Game',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DicePage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.brown.shade900,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                    ),
                    child: const Text(
                      'Dice Game',
                      style: TextStyle(fontSize: 20),
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
