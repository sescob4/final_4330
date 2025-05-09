import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:final_4330/screens/audio.dart';

//This is a placeholder screen for now, not fully implemented

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double musicVolume = 0.5;
  double sfxVolume = 0.5;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  // Load saved settings
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      musicVolume = prefs.getDouble('musicVolume') ?? 0.5;
      sfxVolume = prefs.getDouble('sfxVolume') ?? 0.5;
    });
  }

  // Save settings
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('musicVolume', musicVolume);
    await prefs.setDouble('sfxVolume', sfxVolume);
  }

  // Add logout function
  void logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: Colors.amber)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Log Out')),
        ],
      ),
    );
  }

  void quitGame() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quit Game', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to quit?',
            style: TextStyle(color: Colors.amber)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Quit')), // Hook into your quit logic here
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
                AudioManager().setVolume(val);
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
              onPressed: quitGame,
              child: const Text('Quit Game'),
            ),
            // Logout button
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: logout,
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
