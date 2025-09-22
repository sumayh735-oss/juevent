import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _loading = true;
  bool _push = true;
  bool _email = false;

  DocumentReference<Map<String, dynamic>> get _prefsDoc {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('prefs')
        .doc('app');
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snap = await _prefsDoc.get();
    final d = snap.data() ?? {};
    setState(() {
      _push = (d['pushNotifications'] ?? true) as bool;
      _email = (d['emailUpdates'] ?? false) as bool;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _prefsDoc.set({
      'pushNotifications': _push,
      'emailUpdates': _email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Push notifications'),
            value: _push,
            onChanged: (v) => setState(() => _push = v),
          ),
          SwitchListTile(
            title: const Text('Email updates'),
            value: _email,
            onChanged: (v) => setState(() => _email = v),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(onPressed: _save, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}
