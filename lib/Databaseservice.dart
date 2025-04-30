import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

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
}
