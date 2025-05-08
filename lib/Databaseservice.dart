import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String getCurrentUserId() {
    return _auth.currentUser?.uid ??
      "guest_${DateTime.now().millisecondsSinceEpoch}";
  }

  Future<String> getCurrentUsername() async {
    final uid = getCurrentUserId();
    return await _getUsernameByUid(uid);
  }
  // Game session management
  Future<String> createNewGame() async {
    final newGameRef = _db.child('deck/gameSessions').push();
    final gameId = newGameRef.key!;
    await newGameRef.set({
      'gameLock': false,
      'playersAndCards':  {}, // Initialize as empty map
      'cardDeclared' : '',
      'cardDownStack': '',
      'createdAt': ServerValue.timestamp,
      'createdBy': getCurrentUserId(),
      'timeStamp': ServerValue.timestamp,
    });
    return gameId;
  }

  // Game lock state management
  Stream<bool> listenToLock(String gameId) {
    final lockRef = _db.child('deck/gameSessions/$gameId/gameLock');
    return lockRef.onValue.map((event) {
      final lockValue = event.snapshot.value;
      return lockValue is bool ? lockValue : false;
    });
  }

  Future<void> lockGame(String gameId) async {
    await _db.child('deck/gameSessions/$gameId/gameLock').set(true);
  }

  Future<void> unlockGame(String gameId) async {
    await _db.child('deck/gameSessions/$gameId/gameLock').set(false);
  }

  Future<bool> canAct(String gameId) async {
    final snapshot = await _db.child('deck/gameSessions/$gameId/gameLock').get();
    return !(snapshot.value as bool? ?? false);
  }

  // Card actions
  Future<void> writeCardPutDown(String card, String gameId) async {
    final userId = getCurrentUserId();
    final username = await _getUsernameByUid(userId);

    // Add to game history with timestamp
    await _db.child("deck/gameSessions/$gameId/cardActions").push().set({
      'userId': userId,
      'username': username,
      'card': card,
      'timestamp': ServerValue.timestamp,
    });

    // Update current state
    await _db.child("deck/gameSessions/$gameId/playersAndCards/$userId").set({
      'username': username,
      'card': card,
      'updatedAt': ServerValue.timestamp,
    });
  }

Future<String?> joinQueueAndCheck(String username) async {
  final userId = getCurrentUserId();
  final queueRef = _db.child("deck/queue");
  final newEntry = await queueRef.push();

  await newEntry.set({
    "uid": userId,
    "username": username,
    "joinedAt": ServerValue.timestamp,
  });

  // Get queue lock reference
  final lockRef = _db.child("deck/queueLock");

  // Try to acquire the lock first
  final lockSnapshot = await lockRef.get();
  if (lockSnapshot.exists && lockSnapshot.value == true) {
    return null; // Someone else has the lock, bail out
  }

  // Set the lock
  await lockRef.set(true);

  try {
    // Check if we have enough players
    final snapshot = await queueRef.get();
    final players = snapshot.children.toList();

    if (players.length >= 4) {
      // Create game session
      final gameRef = _db.child("deck/gameSessions").push();
      final gameId = gameRef.key!;
      final playersData = <String, dynamic>{};

      // Get first 4 players
      for (var p in players.take(4)) {
        final uid = p.child("uid").value.toString();
        final uname = p.child("username").value.toString();
        playersData[uid] = {
          'username': uname,
          'joinedAt': ServerValue.timestamp,
          'lastAction': null
        };
      }

      // Set up new game
      await gameRef.set({
        "gameLock": false,
        "playersAndCards": playersData,
        "cardDeclared": "",
        "cardDownStack": "",
        "createdAt": ServerValue.timestamp
      });

      // Remove players from queue
      for (var p in players.take(4)) {
        await queueRef.child(p.key!).remove();
      }

      // Unlock queue and return game ID
      await lockRef.set(false);
      return gameId;
    }

    // Not enough players, unlock and return null
    await lockRef.set(false);
    return null;
  } catch (e) {
    // Ensure we unlock on error
    await lockRef.set(false);
    rethrow;
  }
}
  // Helper method to get username
  Future<String> _getUsernameByUid(String uid) async {
    if (uid.startsWith('guest_')) {
      return 'Guest Player';
    }

    try {
      final snapshot = await _db.child('users/$uid/username').get();
      return snapshot.exists ? snapshot.value.toString() : 'Guest Player';
    } catch (e) {
      return 'Guest Player';
    }
  }



  //////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////// DICE GAME FIREBASE DATABASE FUNCTIONS /////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////

// Removes a player from the game session.
// If the user is the creator, update the creator to the next player.
  Future<String?> getCurrentTurnPlayer(String gameID) async {
    final ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID/currentPlayer");
    final snapshot = await ref.get();
    return snapshot.value?.toString();
  }
  Future<void> deleteUser(String userID, String gameID, String gameChosen) async {
    final ref = await FirebaseDatabase.instance.ref("$gameChosen/gameSessions/$gameID/createdBy").once();
    final data = ref.snapshot.value;

    if (data == userID) {
      // If user is the creator, get a new creator
      DatabaseReference ref = FirebaseDatabase.instance.ref("$gameChosen/gameSessions/$gameID");
      String newCreated = await getNextPlayer(userID, gameID);
      ref.update({"createdBy": newCreated});
      await FirebaseDatabase.instance.ref("$gameChosen/gameSessions/$gameID/playersAndDice/$userID").remove();
    } else {
      // If user is not the creator, just remove them
      await FirebaseDatabase.instance.ref("$gameChosen/gameSessions/$gameID/playersAndDice/$userID").remove();
    }
  }

// Deletes an entire game session from the database
  Future<void> deleteGame(String userID, String gameID, String gameChosen) async {
    final ref = FirebaseDatabase.instance.ref("$gameChosen/gameSessions/$gameID");
    ref.remove();
  }

// Writes new dice values for all players if the current user is the game creator
  Future<void> writeDiceForAll(String userID, String gameID) async {

      DatabaseReference ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID/playersAndDice");
      DatabaseEvent event = await ref.once();
      final data = event.snapshot.value;
      final Random rand = Random();

      // Iterate over each player and assign random dice values
      if (data is Map) {
        for (var entry in (data as Map).entries) {
          final playerID = entry.key;
          final diceList = entry.value;

          // Randomize each dice value (1–6)
          if (diceList is List) {
            final updatedDiceList = List.generate(diceList.length, (_) => rand.nextInt(6) + 1);
            await ref.child(playerID).set(updatedDiceList);
          }
        }
      }else {
        print("error in writeDiceForALL");
      }
  }



// Sets the current bet made by a player and transitions the turn
  Future<void> placeDiceBet(String userID, String gameID, int amount, int faceValue) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID");
    await ref.update({"betDeclared": [amount, faceValue]});
    await setPlayer(userID, gameID);
  }

// Rotates turn by moving to the next player in the list
  Future<void> setPlayer(String userID, String gameID) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID");
    DatabaseEvent event = await ref.once();
    final data = event.snapshot.value;

    if (data is Map) {
      String? previousPlayer = data["currentPlayer"];
      String? nextPlayer = await getNextPlayer(userID, gameID);
      await ref.update({
        "currentPlayer": nextPlayer,
        "lastPlayer": previousPlayer
      });
    }
  }

// Determines which player should go next in the sequence
  Future<String> getNextPlayer(String currentUserID, String gameID) async {
    final ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID/playersAndDice");
    final snapshot = await ref.once();
    final data = snapshot.snapshot.value;

    if (data is Map) {
      final playerMap = data.keys.toList();
      int index = playerMap.indexOf(currentUserID);
      int next = (index + 1) % playerMap.length;
      return playerMap[next];
    }

    print("error in the get next player database service!!");
    return "errorrrr";
  }

// Verifies if a call on a bet was valid by counting matching dice
  Future<bool> checkDiceCall(String userID, String gameID) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID");
    DatabaseEvent event = await ref.once();
    final data = event.snapshot.value;

    if (data is Map) {
      List<int> betDeclare = List<int>.from(data["betDeclared"]);
      int ones =0;
      int twos=0;
      int threes=0;
      int fours=0;
      int fives=0;
      int sixs=0;

      final playersAndDice = Map<String,dynamic>.from(data["playersAndDice"]);

      playersAndDice.forEach((playerID, dicelist){
        final dice = List<int>.from(dicelist);
        var di;
        for(di in dice){
          if(di==1){ones++;}
          if(di==2){twos++;}
          if(di == 3){threes++;}
          if(di == 4){fours++;}
          if(di == 5){fives++;}
          if(di == 6){sixs++;}
        }
      });

      if(betDeclare[1] == 1){ if(betDeclare[0]==ones){ return true;}}
      if(betDeclare[1]== 2){ if(betDeclare[0]==twos){return true;}}
      if(betDeclare[1]==3){ if(betDeclare[0]==threes){return true;}}
      if(betDeclare[1]==4){ if(betDeclare[0]==fours){return true;}}
      if(betDeclare[1]==5){ if(betDeclare[0]==fives){return true;}}
      if(betDeclare[1]==6){ if(betDeclare[0]==sixs){return true;}}
      return false;
    }
    print("error in check call!!!!!!!");
    return false;
  }
// Retrieves a list of dice values for the current user
  Future<List<int>> getDice(String userID, String gameID) async {
    final data = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID/playersAndDice/$userID");
    final snap = await data.get();
    final list = snap.value;

    if (list is List) {
      return List<int>.from(list);
    }

    print("error in getDice");
    return [];
  }

  // this will take a life and return how many they have left
  Future<int> loseLifeDB(String userId, String gameId) async{
    final ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameId/playersLife/$userId");
    final snapshot = await ref.once();
    final data = snapshot.snapshot.value;
    int playerLives = 0;
    if(data is int) {
      playerLives = data - 1;
      //to prevent negative lives
      if(playerLives <0){
        playerLives = 0;
      }
      await ref.set(playerLives);
      return playerLives;

    }
    return playerLives;

  }
  Future<int> getLifesDB(String userId, String gameId) async {
    final ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameId/playersLife/$userId");
    final snapshot = await ref.once();
    final data = snapshot.snapshot.value;
    int playerLives = 0;

    if(data is int){
      playerLives = data;
    }

    return playerLives;
  }
  Future<int> getNumOfPlayerDB(String gameId) async {
    final ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameId/playersAndDice");
    final snapshot = await ref.once();
    final data = snapshot.snapshot.value;
    int playerLives = 0;

    if(data is int){
      playerLives = data;
    }

    return playerLives;
  }

  //ACTIONS TODOS
//ACTION: Make next player (other user ID) be able to also roll the dice after the bluff call
  //DONE IN GAME SELECTION LINES 491 and 495
//ACTION: Need to make total dice for each player = 5
  //DONE IN GAME SELECTION LINES 524 and 493
//ACTION:Need to add lives feature
  //DONE IN DATABASESERVICE

//ACTION:need to add chat box feature that records what player did what bet or call, who lost a life because of it
//ACTION: player id add it
////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////EXAMPLES BELOW///////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////
// void _addLog(String entry) {
//     history.add(entry);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
//       }
//     });
//   }

// _addLog('You rolled: ${allDice[0].join(', ')}')

// if (turnIndex == 0) {
//             _addLog('Your turn: Bet or Call');
//           } else {
//             _addLog('CPU $turnIndex starts betting');
//             Future.delayed(const Duration(milliseconds: 400), _cpuAction);
//           }
//         });
//       }
//     });
//   }

  // _addLog('You bet $bidQuantity × $bidFace');

// _addLog('You called bluff on ${bidQuantity!} × ${bidFace!}');

// void _handleCpuCall() {
//     final cpuIdx = turnIndex;
//     _addLog('CPU $cpuIdx calls bluff');
//     // immediately resolve the call (this resets turnIndex, hasRolled, etc.)
//     _resolveCall(turnIndex);
//   }

//   void _handleCpuBet() {
//     final cpuIdx = turnIndex;
//     final oldQty = bidQuantity ?? 0;
//     final oldFace = bidFace ?? 1;
//     bool raiseQty = _rand.nextBool();
//     if (!raiseQty && oldFace >= 6) raiseQty = true;
//     final newQty = raiseQty ? oldQty + 1 : oldQty;
//     final newFace = raiseQty ? oldFace : min(oldFace + 1, 6);
//     setState(() { bidQuantity = newQty; bidFace = newFace; });
//     final msg = 'CPU $cpuIdx bets $newQty × $newFace';
//     _addLog(msg);
//     ScaffoldMessenger.of(context)
//       .showSnackBar(SnackBar(content: Text(msg)))
//       .closed
//       .then((_) => _nextTurn());
//   }


  //////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////// DECK GAME FIREBASE DATABASE FUNCTIONS /////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////

  //Lora's Functions
  Future<void> putDownCardsAndLog(String userID, String gameID, List<String> cards) async {
    final DatabaseReference playerRef = FirebaseDatabase.instance.ref("deck/gameSessions/$gameID/playersAndCards/$userID");
    final DatabaseReference logRef = FirebaseDatabase.instance.ref("deck/gameSessions/$gameID/cardActions");
    final username = await _getUsernameByUid(userID);

    // Save card list to current state
    await playerRef.set(cards);

    // Log each card with timestamp and metadata
    for (final card in cards) {
      await logRef.push().set({
        'userId': userID,
        'username': username,
        'card': card,
        'timestamp': ServerValue.timestamp,
      });
    }
  }
  // This is saving the wins/losses to the database
  Future<void> recordGameResult({required bool didWin}) async {
  final userId = getCurrentUserId();
  final userStatsRef = _db.child('deck/userStats/$userId');
   final firestoreRef = FirebaseFirestore.instance.collection('users').doc(userId);

  // ---- Update Realtime Database (if needed) ----
  final snapshot = await userStatsRef.get();
  int wins = 0;
  int losses = 0;
  if (snapshot.exists) {
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    wins = data['wins'] ?? 0;
    losses = data['losses'] ?? 0;
  }

  if (didWin) {
    wins += 1;
  } else {
    losses += 1;
  }

  await userStatsRef.set({
    'wins': wins,
    'losses': losses,
    'lastUpdated': ServerValue.timestamp,
  });

  // ---- Update Firestore for UserStatsScreen ----
  final doc = await firestoreRef.get();
  int gamesPlayed = 0;
  int gamesWon = 0;
  if (doc.exists) {
    final data = doc.data()!;
    gamesPlayed = (data['gamesPlayed'] ?? 0) + 1;
    gamesWon = (data['gamesWon'] ?? 0) + (didWin ? 1 : 0);
  } else {
    gamesPlayed = 1;
    gamesWon = didWin ? 1 : 0;
  }

  await firestoreRef.set({
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
  }, SetOptions(merge: true)); // merge to avoid overwriting other user fields
}



}