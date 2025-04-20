import 'package:flutter/material.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'game_screen',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
