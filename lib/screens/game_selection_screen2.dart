import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../liars_deck_game_ai.dart';
import '/dice_page.dart';
import 'roles_screen.dart';
import '../widgets/frame_button.dart';
import '../Databaseservice.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

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

  Future<Map<String, String>> getUserInfo() async {
    await FirebaseAuth.instance.authStateChanges().first;
    final user = FirebaseAuth.instance.currentUser;
    final userId =
        user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    String userName = user?.displayName ?? 'Guest';
    try {
      await firestore.FirebaseFirestore.instance.enableNetwork();
      await Future.delayed(
          const Duration(milliseconds: 500)); // optional buffer

      final doc = await firestore.FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['username'] != null) {
          userName = data['username'];
        }
      }
    } catch (e) {
      debugPrint(
          "⚠️ Firestore fetch failed: $e — using fallback name: $userName");
    }

    return {'uid': userId, 'username': userName};
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
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  "Choose Your Game",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
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
                      crownImagePath: "assets/handofcards.png",
                      // fontScale: .5,
                      onTap: () async {
                        final dbService = DatabaseService();
                        final gameId = await dbService.createNewGame();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UserClassification(gameChosen: "deck"),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: buttonPadding),
                  Expanded(
                    child: ImageButton(
                      label: "Liar's Dice",
                      crownImagePath: "assets/dice.png",
                      // fontScale: .5,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => UserClassification(
                                  gameChosen: "dice")), //CHANGE T
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

class UserClassification extends StatelessWidget {
  final String gameChosen;
  const UserClassification({super.key, required this.gameChosen});

  void _showUserClasses(BuildContext context) {
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
              onPressed: () => _showUserClasses(context),
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
                "Choose Who To Trick",
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
                      label: "Multiple\nUsers",
                      crownImagePath: "assets/group.png",
                      scaleFactor: 30,
                      onTap: () async {
                        final info = await GameSelectionPage2().getUserInfo();
                        //final user = FirebaseAuth.instance.currentUser;
                        final userId = info['uid']!;
                        //"guest_${DateTime.now().millisecondsSinceEpoch}";
                        final userName = info['username']!;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameQUEUE(
                              gameChosen: gameChosen,
                              userID: userId,
                              userName: userName,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: buttonPadding),
                  // AI Bot
                  Expanded(
                    child: ImageButton(
                      label: "AI Bot",
                      crownImagePath: "assets/single.png",
                      onTap: () async {
                        final info = await GameSelectionPage2().getUserInfo();
                        final userId = info['uid']!;
                        final userName = info['username']!;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GameQUEUE(
                              gameChosen: gameChosen,
                              userID: userId,
                              userName: userName,
                            ),
                          ),
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


class GameQUEUE extends StatefulWidget{
  final gameChosen;
  final userID;
  final userName;

  const GameQUEUE({ super.key,
  required this.gameChosen,
  required this.userID,
  required this.userName});

  @override
  State<GameQUEUE> createState() => _GameLoadingQueue();
}

class _GameLoadingQueue extends State<GameQUEUE>{
  final QueueDeck _queueManager = QueueDeck();
  StreamSubscription<DatabaseEvent>? _assignementListener;

  @override
  void initState(){
    super.initState();
    _beginQueueProcess();
  }
  Future<void> _beginQueueProcess() async {
    await _queueManager.tryJoinQueue(
      widget.userID,
      widget.userName,
      widget.gameChosen,
    );

    // Listen to the queue path
    final queuePath = widget.gameChosen == "deck"
        ? "deck/deckQueue"
        : "dice/deckQueue";

    _assignementListener = FirebaseDatabase.instance
        .ref(queuePath)
        .onValue
        .listen((DatabaseEvent event) {
      final data = event.snapshot.value;

      if (data is Map) {
        final found = data.values.any((entry) {
          if (entry is Map && entry['userId'] == widget.userID) {
            return true;
          }
          return false;
        });

        if (found) {
          print("✅ User ${widget.userID} is in the queue!");

          // Stop listening
          _assignementListener?.cancel();

          // Proceed to game (you can choose what happens next)
          if (widget.gameChosen == "deck") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LiarsDeckGamePage(gameId: "placeholder_game_id"),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DicePage(),
              ),
            );
          }
        }
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.amber),
      ),
    );
  }

}





//class with functions to get lock and add to a game/queue
class QueueDeck {

  final DatabaseReference _lockRefDECK = FirebaseDatabase.instance.ref("deck/queueLock");
  final DatabaseReference _lockRefDICE = FirebaseDatabase.instance.ref("dice/queueLock");

  final DatabaseReference _queueRefDeck = FirebaseDatabase.instance.ref("deck/deckQueue");
  final DatabaseReference _queueRefDice = FirebaseDatabase.instance.ref("dice/deckQueue");

  Future<bool> acquireQueueLock(String gameChosen) async {
    if(gameChosen == "dice") {
      final result = await _lockRefDICE.runTransaction((currentData) {
        if (currentData == true) {
          print("locked" + ServerValue.timestamp.toString());
          return Transaction.abort();
        } else {
          print("free" + ServerValue.timestamp.toString());
          return Transaction.success(true);
        }
      });
      return result.committed;
    }else if(gameChosen == "deck"){
      final result = await _lockRefDECK.runTransaction((currentData) {
        if (currentData == true) {
          print("locked" + ServerValue.timestamp.toString());
          return Transaction.abort();
        } else {
          print("free" + ServerValue.timestamp.toString());
          return Transaction.success(true);
        }
      });
      return result.committed;
    }
    print("hitting false ");
    return false;
  }

  Future<void> tryJoinQueue(String userId, String name, String gameChosen) async {
    bool joined = false;

    while (!joined) {
      final lockAcquired = await acquireQueueLock(gameChosen);
      if(gameChosen == "dice") {////////////////////////////
        if (!lockAcquired) {
          print("Still locked");
          await Future.delayed(const Duration(seconds: 5));
        } else {
          try {
            await _queueRefDice.push().set({
              "userId": userId,
              "name": name,
              "timestamp": ServerValue.timestamp,
            });
            joined = true;
          } finally {
            await _lockRefDICE.set(false); // Always release the lock
          }
        }
      }else if(gameChosen == "deck"){//////////////////////////
        if (!lockAcquired) {
          print("Still locked");
          await Future.delayed(const Duration(seconds: 5));
        } else {
          try {
            //////////// THIS LOGIC holder is for when the user in in the queue to be added
            // the user should be looking for a gameID with a false lock or add a new one
            //if we you are the fourth player you lock the game

            await _queueRefDeck.push().set({
              "userId": userId,
              "name": name,
              "timestamp": ServerValue.timestamp,
            });
            joined = true;
          } finally {
            await _lockRefDECK.set(false); // Always release the lock
          }
        }
      }
    }
  }
}
