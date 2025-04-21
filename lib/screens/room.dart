/*
// ───────── Connectivity RoomScreen (comment back in to enable) ─────────
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomScreen extends StatelessWidget {
  const RoomScreen(this.roomId, {super.key});
  final String roomId;

  @override Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.doc('rooms/$roomId');
    return Scaffold(
      appBar: AppBar(title: Text('Room $roomId')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data()!;
          final members = List<Map<String, dynamic>>.from(data['members']);
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Phase: ${data['phase']}'),
              const SizedBox(height: 16),
              const Text('Members:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...members.map((m) => ListTile(title: Text(m['displayName']))),
              const SizedBox(height: 32),
              if (FirebaseAuth.instance.currentUser!.uid == data['hostUid'])
                ElevatedButton(
                  onPressed: () => ref.update({'phase': 'started'}),
                  child: const Text('Change phase (demo)'),
                ),
            ],
          );
        },
      ),
    );
  }
}
// ──────────────────────────────────────────────────────────────────────────────
*/
