import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});
  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _form = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _changePassword() async {
    if (!_form.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _saving = true);
    try {
      final providers = user.providerData;
      final usesPassword = providers.any((p) => p.providerId == 'password');

      if (usesPassword) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentCtrl.text.trim(),
        );
        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(_newCtrl.text.trim());
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Password updated')));
      } else {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset link sent to your email')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Error';
      if (e.code == 'wrong-password') msg = 'Current password incorrect';
      if (e.code == 'weak-password') msg = 'Password too weak';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _currentCtrl,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _newCtrl,
                decoration: const InputDecoration(labelText: 'New password'),
                obscureText: true,
                validator:
                    (v) => (v != null && v.length >= 6) ? null : 'Min 6 chars',
              ),
              TextFormField(
                controller: _confirmCtrl,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                obscureText: true,
                validator:
                    (v) =>
                        (v == _newCtrl.text) ? null : 'Passwords do not match',
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _changePassword,
                  child:
                      _saving
                          ? const CircularProgressIndicator()
                          : const Text('Update Password'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user?.email != null) {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: user!.email!,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reset link sent')),
                      );
                    }
                  }
                },
                child: const Text('Send reset link to my email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
