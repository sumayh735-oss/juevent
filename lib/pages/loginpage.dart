import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/pages/main_admin_page.dart';
import 'package:withfbase/pages/main_page.dart';
import 'package:withfbase/widgets/home_header.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  final bool isAdminLogin;
  const LoginPage({super.key, this.isAdminLogin = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String role = 'guest'; // default role, tusaale ahaan
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final email = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      setState(() {
        _isLoading = true;
      });

      try {
        // Login user with FirebaseAuth
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);

        User? user = userCredential.user;

        if (user != null) {
          // Fetch user data from Firestore to check role
          final userDoc =
              await FirebaseFirestore.instance
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

          // Redirect based on role (admin or user)
          if (role == 'admin') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const MainAdminPage(initialIndex: 0),
              ),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const MainPage(initialIndex: 0),
              ),
              (route) => false,
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Login failed: ${e.message}';

        // Customize error messages
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided.';
        }

        // Show error message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } finally {
        setState(() {
          _isLoading = false;
        });
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
          Scrollbar(
            thumbVisibility: true,
            thickness: 6.0,
            radius: const Radius.circular(10),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 100, bottom: 40),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(height: 290),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 500),
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Logo
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.rectangle,
                              ),
                              child: const Center(
                                child: Text(
                                  'JU',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text('JU', textAlign: TextAlign.center),
                            const SizedBox(height: 24),
                            // Email input field
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Please enter your email'
                                          : null,
                            ),
                            const SizedBox(height: 16),
                            // Password input field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                                suffixIcon: Icon(Icons.visibility),
                                border: OutlineInputBorder(),
                              ),
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Please enter your password'
                                          : null,
                            ),
                            const SizedBox(height: 24),
                            // Loading spinner or Login button
                            _isLoading
                                ? const CircularProgressIndicator()
                                : SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    child: const Text('Login'),
                                  ),
                                ),
                            const SizedBox(height: 16),
                            // Signup redirect
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account?"),
                                TextButton(
                                  onPressed: _navigateToSignup,
                                  child: const Text('Sign Up'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 200),
                    const FooterPage(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Builder(
              builder:
                  (context) => HomeHeader(
                    onMenuTap: () => Scaffold.of(context).openEndDrawer(),
                    title: '',
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
