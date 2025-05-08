import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/game_selection_screen.dart';
import 'screens/instruction.dart';
import 'screens/login_screen';
import 'screens/signup_screen';
import 'screens/settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'screens/audio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'screens/roles_screen.dart';
import 'screens/user_stats_screen.dart';
import 'Databaseservice.dart';

//
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔄 Force landscape orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseFirestore.instance.clearPersistence();
    await FirebaseFirestore.instance.enableNetwork();
    // Force sign out any existing user on app start
    await FirebaseAuth.instance.signOut();
    print("Firestore network enabled.");
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      rethrow;
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final database = FirebaseDatabase.instance;
    DatabaseReference reference = database.ref();

    void writeToDatabase(String card) {
      reference.set({
        'current': card,
      });
    }

    return MaterialApp(
      title: 'Liar\'s Bar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.pressStart2pTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => HomePage(),
        '/roles': (context) => RolesScreen(),
        '/gameselection': (context) => const GameSelectionPage(),
        '/userstats': (context) => const UserStatsScreen(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        return HomePage();
      },
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({super.key});
  final AudioPlayer clickPlayer = AudioPlayer();
  // Create an instance of DatabaseService
  final DatabaseService _databaseService = DatabaseService();

  Future<String?> _getUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.isAnonymous) {
        return 'Guest Player'; // "Guest Player" instead of "Unknown Player"
      }
      // Read username from database
      return await _databaseService.getCurrentUsername();
    }
    return null;
  }

  Widget _buildButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(33, 17, 0, .8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade800, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, .3),
            blurRadius: 10,
            offset: Offset(0, 5),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Column(children: [
        ElevatedButton(
          onPressed: () async {
            // Play click sound
            await clickPlayer.play(AssetSource('sound/click-4.mp3'));
            await AudioManager()
                .player
                .setSource(AssetSource('sound/back2.mp3'));
            await AudioManager().player.setReleaseMode(ReleaseMode.loop);
            await AudioManager().player.resume();
            Navigator.pushNamed(context, '/roles');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.brown.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Enter the Bar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            await clickPlayer.play(AssetSource('sound/click-4.mp3'));
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const Instruction()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.brown.shade800,
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Instructions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUsername(),
      builder: (context, snapshot) {
        final String? username = snapshot.data;
        final String centerTitle = (username != null && username.isNotEmpty)
            ? "Welcome, $username"
            : "Liar's Bar";

        return Scaffold(
          body: Stack(
            children: [
              // Full-screen background
              Positioned.fill(
                child: Image.asset(
                  'assets/main2.png',
                  fit: BoxFit.cover,
                ),
              ),
              // Main center content
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Center title
                      Text(
                        centerTitle,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black,
                              offset: Offset(2, 2),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeInDown(
                        delay: const Duration(milliseconds: 500),
                        child: const Text(
                          'A roll of the dice. A twist of the truth.',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color.fromARGB(255, 238, 235, 235),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ZoomIn(
                        delay: const Duration(milliseconds: 1000),
                        child: _buildButtons(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Logout button in the top-right
              if (FirebaseAuth.instance.currentUser != null)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () async {
                        await clickPlayer
                            .play(AssetSource('sound/click-4.mp3'));
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ),
                ),
              // User Stats button in the top-left
              if (FirebaseAuth.instance.currentUser != null)
                SafeArea(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () async {
                          await clickPlayer
                              .play(AssetSource('sound/click-4.mp3'));
                          Navigator.pushNamed(context, '/userstats');
                        },
                        child: const Text(
                          'User Stats',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
