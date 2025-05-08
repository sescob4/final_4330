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
  
  // Game state management
  Stream<Map<String, dynamic>> listenToGameState(String gameId) {
    return _db.child('deck/gameSessions/$gameId').onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return <String, dynamic>{};
      }
      
      // Convert DataSnapshot to Map
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data;
    });
  }


  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////// amy dice below||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
  Future<void> deleteUser(String userID, String gameID, String gameChosen)async{
    final ref = await FirebaseDatabase.instance.ref("$gameChosen/gameSessions/$gameID/createdBy").once();
    final data = ref.snapshot.value;
    if(data == userID){
      DatabaseReference ref = FirebaseDatabase.instance.ref("$gameChosen/gameSessions/$gameID");
      String newCreated = await getNextPlayer(userID, gameID);
      ref.update({"createdBy": newCreated});
      await FirebaseDatabase.instance.ref("$gameChosen/gameSessions/$gameID/playersAndDice/$userID").remove();


    }else{
      await FirebaseDatabase.instance.ref("$gameChosen/gameSessions/$gameID/playersAndDice/$userID").remove();

    }
    /* ACTION ask team what should be edited for when user is out and also figure out how to account for lives on user side--*/

  }
  Future<void> deleteGame(String userID, String gameID, String gameChosen) async{
    final ref = await FirebaseDatabase.instance.ref("$gameChosen/gameSessions/$gameID");
    ref.remove();
  }
  Future<void> writeDiceForAll(String userID, String gameID) async{
    final canWrite = await FirebaseDatabase.instance.ref("dice/gameSessions/$gameID/createdBy").once();
    final canWrite2 = canWrite.snapshot.value;
    if(canWrite2 == userID){
      DatabaseReference ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID/playersAndDice");

      DatabaseEvent event = await ref.once();
      final data = event.snapshot.value;
      final Random rand = Random();
      if(data is Map){
        for(var entry in (data as Map).entries){
          final playerID = entry.key;
          final diceList = entry.value;
          if(diceList is List){
            final updatedDiceList = List.generate(diceList.length, (_) => rand.nextInt(6)+1);
            await ref.child(playerID).set(updatedDiceList);
          }
        }
      }
    }
  }

  Future<void> placeDiceBet(String userID, String gameID, int amount, int faceValue) async{
    DatabaseReference ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID");
    await ref.update({"betDeclared": [amount, faceValue]});
    await setPlayer(userID, gameID);

  }
  Future<void> setPlayer(String userID, String gameID)async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID");
    DatabaseEvent event = await ref.once();
    final data = event.snapshot.value;
    if(data is Map){
      String? previousPlayer = data["currentPlayer"];
      String? nextPlayer = await getNextPlayer(userID, gameID);
      await ref.update({"currentPlayer": nextPlayer,
        "lastPlayer":previousPlayer});
    }
  }
  Future<String> getNextPlayer(String currentUserID, String gameID)async{
    final ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID/playersAndDice");
    final snapshot = await ref.once();
    final data = snapshot.snapshot.value;

    if(data is Map){
      final playerMap = data.keys.toList();
      int index = playerMap.indexOf(currentUserID);
      int next = (index+1 )% playerMap.length;
      return playerMap[next];
    }
    print("error in the get next player database service!!");
    return "errorrrr";
  }
  Future<bool> checkDiceCall(String userID, String gameID) async{
    DatabaseReference ref = FirebaseDatabase.instance.ref("dice/gameSessions/$gameID");
    DatabaseEvent event = await ref.once();
    final data = event.snapshot.value;
    if(data is Map){
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
/* ACTION: ASK TEAM about logic for this does the bet have to be exact or less or greater???????
*
*
*
* */
      return false;
    }
    return false;
  }

//|||||||||||||||||||||||||||||||||||||||||dice amy database above|||||||||||||||||||||||||||||
//+++++++++++++++++++++++++++++++++++++++++deck amy datavase below+++++++++++++++++++++++++++++++++++++


//+++++++++++++++++++++++++++++++++++++++++deck amy datavase above+++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Lora's Functions
  Future<void> putDownCards(String userID, String gameID, List<String> cards) async {
  DatabaseReferenc ref = FirebaseDatabase.instance.ref("deck/gameSessions/$gameID/playersAndCards/$userID");

  await ref.set(cards);
}

}
