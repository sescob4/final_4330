import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Helper to get current user ID or generate guest ID
  String _getCurrentUserId() {
    return _auth.currentUser?.uid ?? 
      "guest_${DateTime.now().millisecondsSinceEpoch}";
  }
  Future<String> getCurrentUsername() async {
  final uid = _getCurrentUserId();
  return await _getUsernameByUid(uid);
}
  // Game session management
  Future<String> createNewGame() async {
    final newGameRef = _db.child('deck/gameSessions').push();
    final gameId = newGameRef.key!;
    await newGameRef.set({
      'gameLock': false,
      'playersAndCards': {},  // Initialize as empty map
      'cardDeclared': '',
      'cardDownStack': '',
      'createdAt': ServerValue.timestamp,
      'createdBy': _getCurrentUserId(),
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
    final userId = _getCurrentUserId();
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
  final userId = _getCurrentUserId();
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
      return snapshot.exists ? snapshot.value.toString() : 'Unknown Player';
    } catch (e) {
      return 'Unknown Player';
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
}