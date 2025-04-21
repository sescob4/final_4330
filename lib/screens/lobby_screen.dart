/*
// ───────── Connectivity LobbyScreen (comment back in to enable) ─────────
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override State<LobbyScreen> createState() => _LobbyState();
}

class _LobbyState extends State<LobbyScreen> {
  final nameCtrl = TextEditingController();
  final idCtrl   = TextEditingController();

  @override Widget build(BuildContext ctx) => Scaffold(
    appBar: AppBar(title: const Text('Lobby')),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Display name')),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.add), label: const Text('Host Room'),
          onPressed: () async {
            final id = await _hostRoom(nameCtrl.text.trim());
            if (!ctx.mounted) return;
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => RoomScreen(id)));
          },
        ),
        const Divider(height: 40),
        TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Room ID')),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.login), label: const Text('Join Room'),
          onPressed: () async {
            await _joinRoom(idCtrl.text.trim(), nameCtrl.text.trim());
            if (!ctx.mounted) return;
            Navigator.push(ctx, MaterialPageRoute(builder: (_) => RoomScreen(idCtrl.text.trim())));
          },
        ),
      ]),
    ),
  );

  Future<String> _hostRoom(String name) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = FirebaseFirestore.instance.collection('rooms').doc();
    await doc.set({
      'createdAt': FieldValue.serverTimestamp(),
      'hostUid': uid,
      'members': [{'uid': uid, 'displayName': name, 'joinedAt': FieldValue.serverTimestamp()}],
      'phase': 'waiting',
    });
    return doc.id;
  }

  Future<void> _joinRoom(String id, String name) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance.doc('rooms/$id').update({
      'members': FieldValue.arrayUnion([
        {'uid': uid, 'displayName': name, 'joinedAt': FieldValue.serverTimestamp()}
      ])
    });
  }
}
// ──────────────────────────────────────────────────────────────────────────────
*/
