import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<String> createNewGame() async {
    final newGameRef = _db.child('deck/gameSessions').push();
    final gameId = newGameRef.key!;
    await newGameRef.set({
      'gameLock': false,
      'playersAndCards': '',
      'cardDeclared': '',
      'cardDownStack': '',
    });
    return gameId;
  }

  Stream<bool> listenToLock(String gameId) {
    final lockRef = _db.child('deck/gameSessions/$gameId/gameLock');
    return lockRef.onValue.map((event) {
      final lockValue = event.snapshot.value;
      if (lockValue is bool) {
        return lockValue;
      }
      return false;
    });
  }

  Future<void> writeCardPutDown(String card, String user, String gameID) async {
    await _db.child("deck/gameSessions/$gameID/playersAndCards").set({
      'user': user,
      'card': card,
    });
  }

  Future<void> lockGame(String gameId) async {
    await _db.child('deck/gameSessions/$gameId/gameLock').set(true);
  }
  //final lockRef = FirebaseFirestore.instance.collection('games'.doc(gameId).collection('meta').doc('lock'));

  Future<void> unlockGame(String gameId) async {
    await _db.child('deck/gameSessions/$gameId/gameLock').set(false);
  }

  Future<bool> canAct(String gameId) async {
    final snapshot =
        await _db.child('deck/gameSessions/$gameId/gameLock').get();
    final isLocked = snapshot.value as bool? ?? false;

    return !isLocked;
  }

  Future<String?> joinQueueAndCheck(String username) async {
    final db = FirebaseDatabase.instance.ref();
    final queueRef = db.child("deck/queue");
    final newEntry = await queueRef.push();
    final userId = FirebaseAuth.instance.currentUser?.uid ??
        "guest_${DateTime.now().millisecondsSinceEpoch}";
    await newEntry.set({
      "uid": userId,
      "username": username,
      "joinedAt": ServerValue.timestamp,
    });

    final snapshot = await queueRef.get();
    final players = snapshot.children.toList();

    if (players.length >= 4) {
      // Lock queue to prevent race condition
      final lockRef = db.child("deck/queueLock");
      final lockSnap = await lockRef.get();
      if (lockSnap.exists && lockSnap.value == true) return null;
      await lockRef.set(true);

      // Create game session
      final gameRef = db.child("deck/gameSessions").push();
      final gameId = gameRef.key!;
      final playersData = <String, dynamic>{};

      for (var p in players.take(4)) {
        final uid = p.child("uid").value;
        final uname = p.child("username").value;
        playersData[uid.toString()] = uname.toString();
      }

      await gameRef.set({
        "gameLock": false,
        "playersAndCards": playersData,
        "cardDeclared": "",
        "cardDownStack": ""
      });

      // Remove players from queue
      for (var p in players.take(4)) {
        await queueRef.child(p.key!).remove();
      }

      await lockRef.set(false);
      return gameId;
    }

    return null;
  }
}
