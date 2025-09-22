import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = u?.displayName ?? '';
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    setState(() => _saving = true);
    try {
      // Update Auth profile
      await u.updateDisplayName(_nameCtrl.text.trim());

      // Update Firestore users/{uid}.username
      await FirebaseFirestore.instance.collection('users').doc(u.uid).update({
        'username': _nameCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      await _logActivity(u.uid, 'profile_edit', {
        'username': _nameCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator:
                    (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child:
                      _saving
                          ? const CircularProgressIndicator()
                          : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _logActivity(String uid, String type, Map<String, dynamic> data) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('activity')
      .add({'type': type, 'data': data, 'ts': FieldValue.serverTimestamp()});
}
