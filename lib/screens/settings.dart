import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';

//This is a placeholder screen for now, not fully implemented

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double musicVolume = 0.5;
  double sfxVolume = 0.5;
  double brightness = 1.0;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  // Load saved settings
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      brightness = prefs.getDouble('brightness') ?? 1.0;

      musicVolume = prefs.getDouble('musicVolume') ?? 0.5;
      sfxVolume = prefs.getDouble('sfxVolume') ?? 0.5;
    });
  }

  // Save settings
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('brightness', brightness);
    await prefs.setDouble('musicVolume', musicVolume);
    await prefs.setDouble('sfxVolume', sfxVolume);
  }

  final AudioPlayer player = AudioPlayer();
  void quitGame() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quit Game'),
        content: const Text('Are you sure you want to quit?',
            style: TextStyle(color: Colors.amber)),
        actions: [
          TextButton(
            onPressed: () async {
              await player.play(AssetSource('sound/click-4.mp3'));
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await player.play(AssetSource('sound/click-4.mp3'));
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Quit'),
          ), // Hook into your quit logic here
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        'Settings',
        style: TextStyle(color: Colors.amber),
      )),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Music Volume',
                style: TextStyle(fontSize: 18, color: Colors.white)),
            Slider(
              value: musicVolume,
              onChanged: (val) {
                setState(() {
                  musicVolume = val;
                });
                saveSettings(); // Save immediately when changed
              },
              min: 0,
              max: 1,
              divisions: 10,
              label: '${(musicVolume * 100).round()}%',
            ),
            const SizedBox(height: 20),
            const Text('SFX Volume',
                style: TextStyle(fontSize: 18, color: Colors.white)),
            Slider(
              value: sfxVolume,
              onChanged: (val) {
                setState(() {
                  sfxVolume = val;
                });
                saveSettings();
              },
              min: 0,
              max: 1,
              divisions: 10,
              label: '${(sfxVolume * 100).round()}%',
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                await player.play(AssetSource('sound/click-4.mp3'));
                quitGame();
              },
              child: const Text('Quit Game'),
            ),
          ],
        ),
      ),
    );
  }
}
