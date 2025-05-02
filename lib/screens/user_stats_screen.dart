import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStatsScreen extends StatelessWidget {
  const UserStatsScreen({super.key});

  Future<Map<String, dynamic>> _getUserStats() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference<Map<String, dynamic>> docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data()!;
      } else {
        // If the user document doesn't exist, create default stats.
        Map<String, dynamic> defaultData = {
          'username': user.email ?? 'User',
          'gamesPlayed': 0,
          'gamesWon': 0,
        };
        await docRef.set(defaultData);
        return defaultData;
      }
    }
    // For non-logged in users, return default guest stats.
    return {
      'username': 'Guest',
      'gamesPlayed': 0,
      'gamesWon': 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Stats'),
        backgroundColor: Colors.brown.shade900,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getUserStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          // Use the default values if no stats found
          final data = snapshot.data!;
          final String username = data['username'] as String;
          final int gamesPlayed = data['gamesPlayed'] as int;
          final int gamesWon = data['gamesWon'] as int;
          final String winPerc = gamesPlayed > 0
              ? ((gamesWon / gamesPlayed) * 100).toStringAsFixed(1)
              : '0.0';

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/main2.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(33, 17, 0, 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.amber.shade800, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$username's Stats",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Games Played: $gamesPlayed',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Games Won: $gamesWon',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Win Percentage: $winPerc%',
                          style: const TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}