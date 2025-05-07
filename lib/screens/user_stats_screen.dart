import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Databaseservice.dart';

class UserStatsScreen extends StatelessWidget {
  const UserStatsScreen({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _getUserStats() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      // Use DatabaseService to get the current username (same as home screen)
      String? usernameFromService =
          await DatabaseService().getCurrentUsername();

      final snapshot = await docRef.get();
      if (snapshot.exists && snapshot.data() != null) {
        Map<String, dynamic> data = snapshot.data()!;
        // Override the username with the value from the DatabaseService,
        // in case the document has an email stored.
        data['username'] = usernameFromService != null &&
                usernameFromService.trim().isNotEmpty &&
                !usernameFromService.contains('@')
            ? usernameFromService
            : data['username'] ?? 'Unknown';
        return data;
      } else {
        Map<String, dynamic> defaultData = {
          'username': usernameFromService != null &&
                  usernameFromService.trim().isNotEmpty &&
                  !usernameFromService.contains('@')
              ? usernameFromService
              : 'Unknown',
          'gamesPlayed': 0,
          'gamesWon': 0,
        };
        await docRef.set(defaultData);
        return defaultData;
      }
    }
    // For non-logged in users, return guest stats.
    return {
      'username': 'Guest',
      'gamesPlayed': 0,
      'gamesWon': 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              Column(
                children: [
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.amberAccent),
                            onPressed: () {
                              Navigator.pop(context); 
                            },
                          ),
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(0, 0, 0, 0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'User Stats',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          const SizedBox(width: 48), 
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(33, 17, 0, 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber, width: 2),
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
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Games Won: $gamesWon',
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Win Percentage: $winPerc%',
                              style: const TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}