import 'package:flutter/material.dart';
import '../Databaseservice.dart';

class GameLobbyScreen extends StatefulWidget {
  const GameLobbyScreen({super.key});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  final DatabaseService dbService = DatabaseService();
  String? gameId;

  @override
  void initState() {
    super.initState();
    _createGame();
  }

  Future<void> _createGame() async {
    final id = await dbService.createNewGame();
    setState(() {
      gameId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (gameId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<bool>(
              stream: dbService.listenToLock(gameId!),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final isLocked = snapshot.data!;
                return Text(
                  isLocked ? "🔒 Locked" : "✅ Unlocked",
                  style: const TextStyle(fontSize: 24),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => dbService.lockGame(gameId!),
              child: const Text('Lock Game'),
            ),
            ElevatedButton(
              onPressed: () => dbService.unlockGame(gameId!),
              child: const Text('Unlock Game'),
            ),
          ],
        ),
      ),
    );
  }
}
