import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityHistoryPage extends StatelessWidget {
  const ActivityHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('activity')
        .orderBy('ts', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No activity yet'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 0),
            itemBuilder: (_, i) {
              final d = docs[i].data();
              final type = d['type'] ?? 'event';
              final ts = (d['ts'] as Timestamp?)?.toDate();
              final detail = (d['data'] ?? {}).toString();
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(type),
                subtitle: Text(detail),
                trailing: Text(ts != null ? _fmt(ts) : ''),
              );
            },
          );
        },
      ),
    );
  }
}

String _fmt(DateTime dt) {
  return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
}
