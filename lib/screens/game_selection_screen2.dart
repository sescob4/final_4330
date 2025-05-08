import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../dice_pageMultiUSER.dart';
import '../liars_deck_game_ai.dart';
import '../testerAMY.dart';
import '/dice_page.dart';
import 'roles_screen.dart';
import 'settings.dart';
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
                Navigator.pushReplacementNamed(context, '/settings');
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
                        print("game selected::deck:");
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
                      crownImagePath: "assets/dice2.png",
                      // fontScale: .5,
                      onTap: () {
                        print("game selected::deck:");

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
/////////////////////////////////////working database do not touch below this pretty please !
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
                        if (gameChosen == "deck") {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LiarsDeckGamePage(gameId: "AI BOT"),
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
    print("Queue Process Begins !");
    final sessionID = await _queueManager.tryJoinQueue(
      widget.userID,
      widget.userName,
      widget.gameChosen,
    );
    print("queue process ENDSSSSSSSSSSSSSSSSSSSSSSSSSSSS");
    // Listen to the queue path
    final queuePath = widget.gameChosen == "deck"
        ? "deck/gameSessions/$sessionID/playersAndCards"
        : "dice/gameSessions/$sessionID/playersAndDice";

    _assignementListener = FirebaseDatabase.instance
        .ref(queuePath)
        .onValue
        .listen((event) {
      final data = event.snapshot.value;

      if (data is Map && data.length >= 1) {
        print("game full with players!!!!!!!!!!!!!! continue to game");

          // Stop listening
          _assignementListener?.cancel();

          if (widget.gameChosen == "deck") {
            ///ACTION ADD IN DECK PAGE
          } else {
            /// ACTIONS Front end may change the bottom section within the //
            /// This is make you go to the page after clicking multi user in dice
            /// //////////////// can change this////////////////////////////////////
            Navigator.push(
            context,
            MaterialPageRoute(
            builder: (context) => DicePageMultiUSER(userID: widget.userID, gameID: sessionID),
            ),
          );
            //////////////////////////////////////////////////////////////////////
            //////////////////////////////////////////////////////////////////////
          }
        }
      }
    );
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

  final DatabaseReference _DeckSessions = FirebaseDatabase.instance.ref("deck/gameSessions");
  final DatabaseReference _DiceSessions = FirebaseDatabase.instance.ref("dice/gameSessions");

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

  Future<String> tryJoinQueue(String userId, String name, String gameChosen) async {
    bool joined = false;
    Map<String, dynamic> newplayer = {

      "userName": name
    };
    while (!joined) {
      final lockAcquired = await acquireQueueLock(gameChosen);


      if(gameChosen == "dice") {////////////////////////////
        if (!lockAcquired) {
          print("Still locked");
          await Future.delayed(const Duration(seconds: 5));
        }

        else {
          try {
            final snapshot = await _DiceSessions.orderByChild("timestamp").limitToLast(5).get();
            int addedToGame = 0;
            //this is to see if a session van be added_____________________________________________________
            for(final session in snapshot.children){
              //loop through last 5 games to check to see if a spot is open for the players by checkin the lock
              final data = session.value as Map<dynamic,dynamic>;
              final sessionID = session.key;

              if(data["gameLock"] == true){
                print("gameLock found true continue to next game_>.>>>>>>>");
              }else{
                print("game lock false try adding player");
                if(sessionID != null){

                final DatabaseReference playerList = _DiceSessions.child(sessionID).child("playersAndDice");
                final playerSnap = await playerList.get();
                print("got player list");

                int players = 0;
                if(playerSnap.exists && playerSnap.value is Map){
                    final data = playerSnap.value as Map;
                    players = data.length;

                  }

                  if( players< 2){
                    print("Found game -> checking game to add player");
                    await playerList.child(userId).set([0,0,0,0]);

                    if((players+1)>= 2){
                      await _DiceSessions.child(sessionID).child("gameLock").set(true);
                    }

                    addedToGame = 1;
                    print("player added to game "+ sessionID);
                    return sessionID;

                  }else{
                    print("game full cant add to game players");
                    await _DiceSessions.child(sessionID).child("gameLock").set(true);
                  }
                }
              }
            }


            if(addedToGame == 0){//create new session game if none are open
              print("no game sessions available now creating new one");
              final newGameSessionRef = _DiceSessions.push();
              await newGameSessionRef.set({
                "createdBy": userId,
                "currentPlayer": userId,
                "lastPlayer": "",
                "chat": ["Starting Game Chat....."],
                "betDeclared": [0,0],// 2 dice of 3 this is how it would go
                "gameLock": false,
                "timestamp": ServerValue.timestamp,
                "playersAndDice":{
                  userId: [0,0,0,0]
                },
                "playersLife":{
                  userId: 3
                }
              }
              );

              final booleanSession = newGameSessionRef.key;
              if(booleanSession != null){
                return booleanSession;
              }
              return "error";
            }

            }finally{
                await _lockRefDICE.set(false);
              }
        }
      }else if(gameChosen == "deck"){////////////////////////////////////////////////////////////////////////////////////////////////////////
        if (!lockAcquired) {
          print("Still locked");
          await Future.delayed(const Duration(seconds: 5));
        }

        else {
          try {
            final snapshot = await _DeckSessions.orderByChild("timestamp").limitToLast(5).get();

            int addedToGame = 0;
            //this is to see if a session van be added_____________________________________________________
            for(final session in snapshot.children){
              //loop through last 5 games to check to see if a spot is open for the players by checkin the lock
              final data = session.value as Map<dynamic,dynamic>;
              final sessionID = session.key;

              if(data["gameLock"] == true){
                print("gameLock found true continue to next game_>.>>>>>>>");
              }else{
                print("game lock false try adding player");
                if(sessionID != null){

                  final DatabaseReference playerList = _DeckSessions.child(sessionID).child("playersAndCards");
                  final playerSnap = await playerList.get();
                  print("got player list");

                  int players = 0;
                  if(playerSnap.exists && playerSnap.value is Map){
                    final data = playerSnap.value as Map;
                    players = data.length;

                  }

                  if( players< 2){
                    print("Found game -> checking game to add player");
                    await playerList.child(userId).set([0,0,0]);

                    if((players+1)>= 2){
                      await _DeckSessions.child(sessionID).child("gameLock").set(true);
                    }

                    addedToGame = 1;
                    print("player added to game "+ sessionID);
                    return sessionID;

                  }else{
                    print("game full cant add to game players");
                    await _DeckSessions.child(sessionID).child("gameLock").set(true);
                  }
                }
              }
            }


            if(addedToGame == 0){//create new session game if none are open
              print("no game sessions available now creating new one");
              final newGameSessionRef = _DeckSessions.push();
              await newGameSessionRef.set({
                "createdBy": userId,
                'playerTurn': "",
                "chat": [],
              'gameLock': false,
              "playersAndCards":{
                userId: [0,0,0,0]
              },
                "playerLives": {
                  userId: 3
                },
              'cardDeclared': '',
              'cardDownStack': '',
              'timeStamp': ServerValue.timestamp,
              });


              final booleanSession = newGameSessionRef.key;
              if(booleanSession != null){
                return booleanSession;
              }
              return "error";
            }

          }finally{
            await _lockRefDECK.set(false);
          }
        }
      }
    }

  }
}
//
// import 'dart:async';
//
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import '../dice_pageMultiUSER.dart';
// import '../liars_deck_game_ai.dart';
// import '../testerAMY.dart';
// import '/dice_page.dart';
// import 'roles_screen.dart';
// import 'settings.dart';
// import '../widgets/frame_button.dart';
// import '../Databaseservice.dart';
// import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
//
// class GameSelectionPage2 extends StatelessWidget {
//   const GameSelectionPage2({super.key});
//
//   void _showGameMenu(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF3E2723),
//         title: const Text('Game Menu', style: TextStyle(color: Colors.white)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextButton.icon(
//               icon: const Icon(Icons.settings, color: Colors.white),
//               label:
//               const Text('Settings', style: TextStyle(color: Colors.white)),
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.pushReplacementNamed(context, '/settings');
//                 // Navigate to settings page when implemented
//               },
//             ),
//             TextButton.icon(
//               icon: const Icon(Icons.home, color: Colors.white),
//               label: const Text('Main Menu',
//                   style: TextStyle(color: Colors.white)),
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.pushReplacementNamed(context, '/home');
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<Map<String, String>> getUserInfo() async {
//     await FirebaseAuth.instance.authStateChanges().first;
//     final user = FirebaseAuth.instance.currentUser;
//     final userId =
//         user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
//     String userName = user?.displayName ?? 'Guest';
//     try {
//       await firestore.FirebaseFirestore.instance.enableNetwork();
//       await Future.delayed(
//           const Duration(milliseconds: 500)); // optional buffer
//
//       final doc = await firestore.FirebaseFirestore.instance
//           .collection('users')
//           .doc(userId)
//           .get();
//       if (doc.exists) {
//         final data = doc.data();
//         if (data != null && data['username'] != null) {
//           userName = data['username'];
//         }
//       }
//     } catch (e) {
//       debugPrint(
//           "⚠️ Firestore fetch failed: $e — using fallback name: $userName");
//     }
//
//     return {'uid': userId, 'username': userName};
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double topPadding = MediaQuery.of(context).padding.top + 8;
//     final double buttonPadding =
//         MediaQuery.of(context).size.width * 0.05; // 5% of screen width
//     final double buttonCornerRadius = 20.0;
//
//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: Image.asset("assets/table.png", fit: BoxFit.cover),
//           ),
//           // Menu button
//           Positioned(
//             top: topPadding,
//             left: 8,
//             child: IconButton(
//               icon: const Icon(Icons.menu, color: Colors.white, size: 32),
//               onPressed: () => _showGameMenu(context),
//               tooltip: 'Game Menu',
//             ),
//           ),
//           // Title
//           Positioned(
//             top: topPadding,
//             left: 0,
//             right: 0,
//             child: const Center(
//               child: Padding(
//                 padding: EdgeInsets.all(8.0),
//                 child: Text(
//                   "Choose Your Game",
//                   style: TextStyle(
//                     color: Colors.amber,
//                     fontSize: 36,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           // Game selection row
//           Positioned.fill(
//             top: topPadding + 70,
//             child: Padding(
//               padding: EdgeInsets.all(buttonPadding),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: ImageButton(
//                       label: "Liar's Deck",
//                       crownImagePath: "assets/handofcards.png",
//                       // fontScale: .5,
//                       onTap: () async {
//                         print("game selected::deck:");
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 UserClassification(gameChosen: "deck"),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   SizedBox(width: buttonPadding),
//                   Expanded(
//                     child: ImageButton(
//                       label: "Liar's Dice",
//                       crownImagePath: "assets/dice2.png",
//                       // fontScale: .5,
//                       onTap: () {
//                         print("game selected::deck:");
//
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) => UserClassification(
//                                   gameChosen: "dice")), //CHANGE T
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// /////////////////////////////////////working database do not touch below this pretty please !
// class UserClassification extends StatelessWidget {
//   final String gameChosen;
//   const UserClassification({super.key, required this.gameChosen});
//
//   void _showUserClasses(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: true,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF3E2723),
//         title: const Text('Game Menu', style: TextStyle(color: Colors.white)),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextButton.icon(
//               icon: const Icon(Icons.settings, color: Colors.white),
//               label:
//               const Text('Settings', style: TextStyle(color: Colors.white)),
//               onPressed: () {
//                 Navigator.pop(context);
//                 // Navigate to settings page when implemented
//               },
//             ),
//             TextButton.icon(
//               icon: const Icon(Icons.home, color: Colors.white),
//               label: const Text('Main Menu',
//                   style: TextStyle(color: Colors.white)),
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.pushReplacementNamed(context, '/home');
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double topPadding = MediaQuery.of(context).padding.top + 8;
//     final double buttonPadding =
//         MediaQuery.of(context).size.width * 0.05; // 5% of screen width
//     final double buttonCornerRadius = 20.0;
//
//     return Scaffold(
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child: Image.asset("assets/table.png", fit: BoxFit.cover),
//           ),
//           // Menu button
//           Positioned(
//             top: topPadding,
//             left: 8,
//             child: IconButton(
//               icon: const Icon(Icons.menu, color: Colors.white, size: 32),
//               onPressed: () => _showUserClasses(context),
//               tooltip: 'Game Menu',
//             ),
//           ),
//           // Title
//           Positioned(
//             top: topPadding,
//             left: 0,
//             right: 0,
//             child: const Center(
//               child: Text(
//                 "Choose Who To Trick",
//                 style: TextStyle(
//                   color: Colors.amber,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ),
//           // Game selection row
//           Positioned.fill(
//             top: topPadding + 70,
//             child: Padding(
//               padding: EdgeInsets.all(buttonPadding),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: ImageButton(
//                       label: "Multiple\nUsers",
//                       crownImagePath: "assets/group.png",
//                       onTap: () async {
//                         final info = await GameSelectionPage2().getUserInfo();
//                         //final user = FirebaseAuth.instance.currentUser;
//                         final userId = info['uid']!;
//                         //"guest_${DateTime.now().millisecondsSinceEpoch}";
//                         final userName = info['username']!;
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => GameQUEUE(
//                               gameChosen: gameChosen,
//                               userID: userId,
//                               userName: userName,
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   SizedBox(width: buttonPadding),
//                   // AI Bot
//                   Expanded(
//                     child: ImageButton(
//                       label: "AI Bot",
//                       crownImagePath: "assets/single.png",
//                       onTap: () async {
//                         final info = await GameSelectionPage2().getUserInfo();
//                         final userId = info['uid']!;
//                         final userName = info['username']!;
//                         if (gameChosen == "deck") {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => LiarsDeckGamePage(gameId: "AI BOT"),
//                             ),
//                           );
//                         } else {
//                           Navigator.pushReplacement(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) => DicePage(),
//                             ),
//                           );
//                         }
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
// class GameQUEUE extends StatefulWidget{
//   final gameChosen;
//   final userID;
//   final userName;
//
//   const GameQUEUE({ super.key,
//     required this.gameChosen,
//     required this.userID,
//     required this.userName});
//
//   @override
//   State<GameQUEUE> createState() => _GameLoadingQueue();
// }
//
// class _GameLoadingQueue extends State<GameQUEUE>{
//   final QueueDeck _queueManager = QueueDeck();
//   StreamSubscription<DatabaseEvent>? _assignementListener;
//
//   @override
//   void initState(){
//     super.initState();
//     _beginQueueProcess();
//   }
//   Future<void> _beginQueueProcess() async {
//     print("Queue Process Begins !");
//     final sessionID = await _queueManager.tryJoinQueue(
//       widget.userID,
//       widget.userName,
//       widget.gameChosen,
//     );
//     print("queue process ENDSSSSSSSSSSSSSSSSSSSSSSSSSSSS");
//     // Listen to the queue path
//     final queuePath = widget.gameChosen == "deck"
//         ? "deck/gameSessions/$sessionID/playersAndCards"
//         : "dice/gameSessions/$sessionID/playersAndDice";
//
//     _assignementListener = FirebaseDatabase.instance
//         .ref(queuePath)
//         .onValue
//         .listen((event) {
//       final data = event.snapshot.value;
//
//       if (data is Map && data.length >= 1) {
//         print("game full with players!!!!!!!!!!!!!! continue to game");
//
//         // Stop listening
//         _assignementListener?.cancel();
//
//         if (widget.gameChosen == "deck") {
//           ///ACTION ADD IN DECK PAGE
//         } else {
//           /// ACTIONS Front end may change the bottom section within the //
//           /// This is make you go to the page after clicking multi user in dice
//           /// //////////////// can change this////////////////////////////////////
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => TestDiceFunctionsPage(userID: widget.userID, gameID: sessionID,)),
//           );
//           //////////////////////////////////////////////////////////////////////
//           //////////////////////////////////////////////////////////////////////
//         }
//       }
//     }
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       backgroundColor: Colors.black,
//       body: Center(
//         child: CircularProgressIndicator(color: Colors.amber),
//       ),
//     );
//   }
//
// }
//
//
//
//
//
// //class with functions to get lock and add to a game/queue
// class QueueDeck {
//
//   final DatabaseReference _lockRefDECK = FirebaseDatabase.instance.ref("deck/queueLock");
//   final DatabaseReference _lockRefDICE = FirebaseDatabase.instance.ref("dice/queueLock");
//
//   final DatabaseReference _DeckSessions = FirebaseDatabase.instance.ref("deck/gameSessions");
//   final DatabaseReference _DiceSessions = FirebaseDatabase.instance.ref("dice/gameSessions");
//
//   Future<bool> acquireQueueLock(String gameChosen) async {
//     if(gameChosen == "dice") {
//       final result = await _lockRefDICE.runTransaction((currentData) {
//         if (currentData == true) {
//           print("locked" + ServerValue.timestamp.toString());
//           return Transaction.abort();
//         } else {
//           print("free" + ServerValue.timestamp.toString());
//           return Transaction.success(true);
//         }
//       });
//       return result.committed;
//     }else if(gameChosen == "deck"){
//       final result = await _lockRefDECK.runTransaction((currentData) {
//         if (currentData == true) {
//           print("locked" + ServerValue.timestamp.toString());
//           return Transaction.abort();
//         } else {
//           print("free" + ServerValue.timestamp.toString());
//           return Transaction.success(true);
//         }
//       });
//       return result.committed;
//     }
//     print("hitting false ");
//     return false;
//   }
//
//   Future<String> tryJoinQueue(String userId, String name, String gameChosen) async {
//     bool joined = false;
//     Map<String, dynamic> newplayer = {
//
//       "userName": name
//     };
//     while (!joined) {
//       final lockAcquired = await acquireQueueLock(gameChosen);
//
//
//       if(gameChosen == "dice") {////////////////////////////
//         if (!lockAcquired) {
//           print("Still locked");
//           await Future.delayed(const Duration(seconds: 5));
//         }
//
//         else {
//           try {
//             final snapshot = await _DiceSessions.orderByChild("timestamp").limitToLast(5).get();
//             int addedToGame = 0;
//             //this is to see if a session van be added_____________________________________________________
//             for(final session in snapshot.children){
//               //loop through last 5 games to check to see if a spot is open for the players by checkin the lock
//               final data = session.value as Map<dynamic,dynamic>;
//               final sessionID = session.key;
//
//               if(data["gameLock"] == true){
//                 print("gameLock found true continue to next game_>.>>>>>>>");
//               }else{
//                 print("game lock false try adding player");
//                 if(sessionID != null){
//
//                   final DatabaseReference playerList = _DiceSessions.child(sessionID).child("playersAndDice");
//                   final playerSnap = await playerList.get();
//                   print("got player list");
//
//                   int players = 0;
//                   if(playerSnap.exists && playerSnap.value is Map){
//                     final data = playerSnap.value as Map;
//                     players = data.length;
//
//                   }
//
//                   if( players< 4){
//                     print("Found game -> checking game to add player");
//                     await playerList.child(userId).set([0,0,0,0]);
//
//                     if((players+1)>= 4){
//                       await _DiceSessions.child(sessionID).child("gameLock").set(true);
//                     }
//
//                     addedToGame = 1;
//                     print("player added to game "+ sessionID);
//                     return sessionID;
//
//                   }else{
//                     print("game full cant add to game players");
//                     await _DiceSessions.child(sessionID).child("gameLock").set(true);
//                   }
//                 }
//               }
//             }
//
//
//             if(addedToGame == 0){//create new session game if none are open
//               print("no game sessions available now creating new one");
//               final newGameSessionRef = _DiceSessions.push();
//               await newGameSessionRef.set({
//                 "createdBy": userId,
//                 "currentPlayer": "",
//                 "lastPlayer": "",
//                 "chat": ["Starting Game Chat....."],
//                 "betDeclared": [0,0],// 2 dice of 3 this is how it would go
//                 "gameLock": false,
//                 "timestamp": ServerValue.timestamp,
//                 "playersAndDice":{
//                   userId: [0,0,0,0]
//                 }
//               });
//
//               final booleanSession = newGameSessionRef.key;
//               if(booleanSession != null){
//                 return booleanSession;
//               }
//               return "error";
//             }
//
//           }finally{
//             await _lockRefDICE.set(false);
//           }
//         }
//       }else if(gameChosen == "deck"){////////////////////////////////////////////////////////////////////////////////////////////////////////
//         if (!lockAcquired) {
//           print("Still locked");
//           await Future.delayed(const Duration(seconds: 5));
//         }
//
//         else {
//           try {
//             final snapshot = await _DeckSessions.orderByChild("timestamp").limitToLast(5).get();
//
//             int addedToGame = 0;
//             //this is to see if a session van be added_____________________________________________________
//             for(final session in snapshot.children){
//               //loop through last 5 games to check to see if a spot is open for the players by checkin the lock
//               final data = session.value as Map<dynamic,dynamic>;
//               final sessionID = session.key;
//
//               if(data["gameLock"] == true){
//                 print("gameLock found true continue to next game_>.>>>>>>>");
//               }else{
//                 print("game lock false try adding player");
//                 if(sessionID != null){
//
//                   final DatabaseReference playerList = _DeckSessions.child(sessionID).child("playersAndCards");
//                   final playerSnap = await playerList.get();
//                   print("got player list");
//
//                   int players = 0;
//                   if(playerSnap.exists && playerSnap.value is Map){
//                     final data = playerSnap.value as Map;
//                     players = data.length;
//
//                   }
//
//                   if( players< 4){
//                     print("Found game -> checking game to add player");
//                     await playerList.child(userId).set([0,0,0]);
//
//                     if((players+1)>= 4){
//                       await _DeckSessions.child(sessionID).child("gameLock").set(true);
//                     }
//
//                     addedToGame = 1;
//                     print("player added to game "+ sessionID);
//                     return sessionID;
//
//                   }else{
//                     print("game full cant add to game players");
//                     await _DeckSessions.child(sessionID).child("gameLock").set(true);
//                   }
//                 }
//               }
//             }
//
//
//             if(addedToGame == 0){//create new session game if none are open
//               print("no game sessions available now creating new one");
//               final newGameSessionRef = _DeckSessions.push();
//               await newGameSessionRef.set({
//                 "createdBy": userId,
//                 'playerTurn': "",
//                 "chat": ["Starting Game Chat....."],
//                 'gameLock': false,
//                 "playersAndCards":{
//                   userId: [0,0,0,0]
//                 },
//                 'cardDeclared': '',
//                 'cardDownStack': '',
//                 'timeStamp': ServerValue.timestamp,
//               });
//
//
//               final booleanSession = newGameSessionRef.key;
//               if(booleanSession != null){
//                 return booleanSession;
//               }
//               return "error";
//             }
//
//           }finally{
//             await _lockRefDECK.set(false);
//           }
//         }
//       }
//     }
//
//   }
// }
//
