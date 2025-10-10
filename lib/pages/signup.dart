import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:withfbase/pages/loginpage.dart';
import 'package:withfbase/pages/main_page.dart';
import 'package:withfbase/services/privacy_policypage.dart';
import 'package:withfbase/widgets/home_header.dart';
import 'package:withfbase/pages/footer.dart';

// ✅ import dialog

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  // ✅ checkbox state
  bool _acceptedPolicy = false;

  // ✅ password hide/show state
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter email';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      // ✅ check if accepted policy
      if (!_acceptedPolicy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fadlan aqbal Privacy Policy & Terms kahor sign up.")),
        );
        return;
      }

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final phone = _phoneController.text.trim();
      final name = _nameController.text.trim();

      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        User? user = userCredential.user;

        if (user != null) {
          await user.updateDisplayName(name);

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'uid': user.uid,
                'email': email,
                'phone': phone,
                'displayName': name,
                'createdAt': Timestamp.now(),
                'isVerified': user.emailVerified,
                'role': 'user',
                'bookings': [],
              });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainPage(initialIndex: 0)),
          );
        }
      } on FirebaseAuthException catch (e) {
        String message = 'Signup failed: ${e.message}';
        if (e.code == 'email-already-in-use') {
          message = 'Email is already registered.';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak.';
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _openPolicy() {
    showDialog(
      context: context,
      builder: (context) => const PolicyTermsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blue),
              child: const Text(
                'Jazeera University',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: _navigateToLogin,
            ),
          ],
        ),
      ),
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
                    const SizedBox(height: 100),
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
                          children: [
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Enter full name' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                border: OutlineInputBorder(),
                              ),
                              validator: emailValidator,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Phone',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Enter phone number' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Enter password' : null,
                            ),
                            const SizedBox(height: 16),

                            // ✅ Checkbox + link
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptedPolicy,
                                  onChanged: (val) {
                                    setState(() {
                                      _acceptedPolicy = val ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Wrap(
                                    children: [
                                      const Text("I accept the "),
                                      GestureDetector(
                                        onTap: _openPolicy,
                                        child: const Text(
                                          "Privacy Policy & Terms",
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

                            const SizedBox(height: 24),
                            _isLoading
                                ? const CircularProgressIndicator()
                                : SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _handleSignup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: const Text('Sign Up'),
                                    ),
                                  ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _navigateToLogin,
                              child: const Text('Already have an account? Login'),
                            ),
                          ],
                        ),
                      ),
                    ),
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
