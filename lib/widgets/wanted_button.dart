import 'package:audioplayers/audioplayers.dart';
import 'package:final_4330/screens/audio.dart';
import 'package:flutter/material.dart';
import '../screens/instruction.dart';

Widget buildButtons(BuildContext context) {
  final AudioPlayer clickPlayer = AudioPlayer();
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
    child: Column(
      children: [
        // ENTER THE BAR BUTTON
        GestureDetector(
          onTap: () async {
            await clickPlayer.play(AssetSource('sound/click-4.mp3'));
            await AudioManager()
                .player
                .setSource(AssetSource('sound/back2.mp3'));
            await AudioManager().player.setReleaseMode(ReleaseMode.loop);
            await AudioManager().player.resume();
            Navigator.pushNamed(context, '/roles');
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/wanted_button_bg.png',
                height: 100,
                fit: BoxFit.contain,
              ),
              const Text(
                'Enter the Bar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0),
                  shadows: [Shadow(offset: Offset(1, 1), blurRadius: 2)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // INSTRUCTIONS BUTTON
        GestureDetector(
          onTap: () async {
            await clickPlayer.play(AssetSource('sound/click-4.mp3'));
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Instruction()),
            );
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/wanted_button_bg.png',
                height: 100,
                fit: BoxFit.contain,
              ),
              const Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                  shadows: [Shadow(offset: Offset(1, 1), blurRadius: 2)],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
