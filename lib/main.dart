import 'package:flutter/material.dart';
import 'screens/game_selection_screen.dart';
import 'screens/instruction.dart';
import 'screens/login_screen';
import 'screens/signup_screen';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'screens/audio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
      theme: ThemeData(
        textTheme: GoogleFonts.pressStart2pTextTheme(), // change the font to match style
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
        '/home': (context) => const HomePage(),
        '/gameselection': (context) => const GameSelectionPage(),
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
        return const HomePage();
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<String?> _getUsername() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (snapshot.exists && snapshot.data() is Map<String, dynamic>) {
        return (snapshot.data() as Map<String, dynamic>)['username'] as String?;
      }
    }
    return null;
  }

    @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUsername(),
      builder: (context, snapshot) {
        String appBarTitle = "Liar's Bar";
        if (snapshot.connectionState == ConnectionState.waiting) {
          appBarTitle = "Loading...";
        } else if (snapshot.hasData) {
          appBarTitle = "Welcome, ${snapshot.data!}";
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(appBarTitle),
            actions: [
              if (FirebaseAuth.instance.currentUser != null)
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
            ],
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/main2.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                // 1) Wrap in a scroll view
                child: SingleChildScrollView(
                  // 2) Add bottom padding so content never bumps the edge
                  padding: const EdgeInsets.only(bottom: 16),
                  
                  child: Center(
                    child: Column(
                      // 3) Let the column size itself to its children
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Liar's Bar",
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FadeInDown(
                          delay: const Duration(milliseconds: 500),
                          child: const Text(
                            'A roll of the dice. A twist of the truth.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 195, 187, 187),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ZoomIn(
                          delay: const Duration(milliseconds: 1000),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(33, 17, 0, 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.amber.shade800,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 20,
                            ),
                            child: Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () async {
                                    await AudioManager()
                                        .player
                                        .setSource(AssetSource('sound/back2.mp3'));
                                    await AudioManager()
                                        .player
                                        .setReleaseMode(ReleaseMode.loop);
                                    await AudioManager().player.resume();
                                    Navigator.pushNamed(
                                        context, '/gameselection');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.brown.shade900,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 50,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Enter the Bar',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const Instruction(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.amber,
                                    foregroundColor: Colors.brown.shade800,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 50,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text(
                                    'Instructions',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
