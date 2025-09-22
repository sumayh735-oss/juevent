import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});
  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  bool _loading = true;
  bool _dark = false;
  String _lang = 'en';

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
      _dark = (d['darkMode'] ?? false) as bool;
      _lang = (d['language'] ?? 'en') as String;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _prefsDoc.set({
      'darkMode': _dark,
      'language': _lang,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: _dark,
            onChanged: (v) => setState(() => _dark = v),
          ),
          const SizedBox(height: 4),
          const Text('Language'),
          DropdownButton<String>(
            value: _lang,
            items: const [
              DropdownMenuItem(value: 'en', child: Text('English')),
              DropdownMenuItem(value: 'so', child: Text('Somali')),
            ],
            onChanged: (v) => setState(() => _lang = v!),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
    );
  }
}
