import "package:cloud_firestore/cloud_firestore.dart";
import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/admindashboard_desktop.dart';
import 'package:withfbase/pages/desktop/home_header_desktop.dart';
import 'package:withfbase/pages/desktop/homepage_desktop.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/services/privacy_policypage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginpageDesktop extends StatefulWidget {
  final bool isAdminLogin;
  const LoginpageDesktop({super.key, this.isAdminLogin = false});

  @override
  State<LoginpageDesktop> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginpageDesktop> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _acceptedPolicy = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _openPolicy() {
    showDialog(
      context: context,
      builder: (context) => const PolicyTermsDialog(),
    );
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptedPolicy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fadlan aqbal Privacy Policy kahor login.")),
        );
        return;
      }

      final email = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      setState(() => _isLoading = true);

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        User? user = userCredential.user;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          if (!userDoc.exists) {
            throw FirebaseAuthException(
              code: 'user-data-missing',
              message: 'User data not found in database.',
            );
          }

          final role = userDoc.data()!['role'];
          if (role == 'admin') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardDesktop()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomepageDesktop()),
              (route) => false,
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = e.code == 'user-not-found'
            ? 'No user found for that email.'
            : e.code == 'wrong-password'
                ? 'Wrong password provided.'
                : 'Login failed: ${e.message}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToSignup() {
    Navigator.pushNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(top: 120, bottom: 40),
            child: Center(
              child: Column(
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            color: Colors.blue,
                            child: const Center(
                              child: Text('JU',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Login',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('JU'),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Enter email' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Enter password' : null,
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptedPolicy,
                                onChanged: (val) =>
                                    setState(() => _acceptedPolicy = val ?? false),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _openPolicy,
                                  child: const Text(
                                    "I accept Privacy Policy & Terms",
                                    style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(vertical: 14)),
                                    child: const Text('Login'),
                                  ),
                                ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account?"),
                              TextButton(
                                  onPressed: _navigateToSignup,
                                  child: const Text('Sign Up')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  const FooterPage(),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Builder(
              builder: (context) => HomeHeaderDesktop(
                  onMenuTap: () => Scaffold.of(context).openEndDrawer(), title: 'Login page',
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
