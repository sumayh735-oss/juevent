import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/pages/main_admin_page.dart';
import 'package:withfbase/pages/main_page.dart';
import 'package:withfbase/services/privacy_policypage.dart';
import 'package:withfbase/widgets/home_header.dart';

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
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  bool _isLoading = false;
  bool _acceptedPolicy = false;
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _openPolicy() {
    showDialog(
      context: context,
      builder: (context) => const PolicyTermsDialog(),
    );
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fadlan aqbal Privacy Policy kahor login.")),
      );
      return;
    }

    final email = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user == null) throw FirebaseAuthException(code: 'user-not-found');

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw FirebaseAuthException(code: 'user-data-missing');

      final role = userDoc.data()?['role'] ?? 'guest';

      if (role == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainAdminPage(initialIndex: 0)),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainPage(initialIndex: 0)),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _emailError = null;
        _passwordError = null;

        // User-friendly messages
        switch (e.code) {
          case 'wrong-password':
            _passwordError = 'Password-kaaga waa khalad, fadlan ku qor si sax ah';
            _passwordFocus.requestFocus();
            break;
          case 'user-not-found':
            _emailError = 'Email-kan lama helin, fadlan hubi';
            _emailFocus.requestFocus();
            break;
          case 'invalid-email':
            _emailError = 'Email-kan waa mid aan sax ahayn';
            _emailFocus.requestFocus();
            break;
          default:
            _passwordError = "ncorrect password, please enter valid password";
            _passwordFocus.requestFocus();
        }
      });
    } finally {
      setState(() => _isLoading = false);
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
            thickness: 6,
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
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text('JU', textAlign: TextAlign.center),
                            const SizedBox(height: 24),

                            // Email Field
                            TextFormField(
                              controller: _usernameController,
                              focusNode: _emailFocus,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: const OutlineInputBorder(),
                                errorText: _emailError,
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty ? 'Fadlan geli email-kaaga' : null,
                              onChanged: (_) {
                                if (_emailError != null) setState(() => _emailError = null);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              focusNode: _passwordFocus,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: const OutlineInputBorder(),
                                errorText: _passwordError,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Fadlan geli password-kaaga';
                                }
                                return null;
                              },
                              onChanged: (_) {
                                if (_passwordError != null) setState(() => _passwordError = null);
                              },
                            ),
                            const SizedBox(height: 16),

                            // Privacy Policy
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _acceptedPolicy,
                                  onChanged: (val) {
                                    setState(() => _acceptedPolicy = val ?? false);
                                  },
                                ),
                                Expanded(
                                  child: Wrap(
                                    children: [
                                      const Text("I accept the "),
                                      GestureDetector(
                                        onTap: _openPolicy,
                                        child: const Text(
                                          "Privacy Policy and Terms & Conditions",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Login Button
                            _isLoading
                                ? const CircularProgressIndicator()
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: const Text('Login'),
                                    ),
                                  ),
                            const SizedBox(height: 16),

                            // Signup
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
              builder: (context) => HomeHeader(
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
