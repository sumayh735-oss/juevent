import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// RegisterEventPage
/// ---------------------------------------------------------------------------
/// Dialog-style event registration form with a blue→black gradient background
/// (edges) while keeping AppBar and BottomNavigationBar visible.
class RegisterEventPage extends StatefulWidget {
  const RegisterEventPage({super.key});

  @override
  State<RegisterEventPage> createState() => _RegisterEventPageState();
}

class _RegisterEventPageState extends State<RegisterEventPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String? selectedDepartment;
  String role = 'Student';
  bool termsAccepted = false;

  final List<String> departments = const [
    'Computer Science',
    'Business',
    'Engineering',
    'Law',
    'Medicine',
  ];

  void _submitForm() {
    if (_formKey.currentState?.validate() != true) return;
    if (!termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept terms and conditions.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Registration Successful'),
            content: const Text('Thank you for registering for the event.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D47A1), Colors.black87],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 650),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Register for Event',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete the form below to register for this event.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        'Full Name',
                        'Enter your full name',
                        fullNameController,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Email Address',
                        'Enter your email',
                        emailController,
                        isEmail: true,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        'Phone Number',
                        'Enter your phone number',
                        phoneController,
                        isPhone: true,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField(),
                      const SizedBox(height: 16),
                      _buildRoleSelector(),
                      const SizedBox(height: 16),
                      _buildNotesField(),
                      const SizedBox(height: 16),
                      _buildTermsCheckbox(),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Confirm Registration',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isEmail = false,
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration(hint),
          keyboardType:
              isEmail
                  ? TextInputType.emailAddress
                  : isPhone
                  ? TextInputType.phone
                  : TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) return '$label is required';
            if (isEmail) {
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Department/Faculty'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: selectedDepartment,
          hint: const Text('Select Department'),
          items:
              departments
                  .map(
                    (dept) => DropdownMenuItem(value: dept, child: Text(dept)),
                  )
                  .toList(),
          onChanged: (val) => setState(() => selectedDepartment = val),
          validator:
              (value) =>
                  (value == null || value.isEmpty)
                      ? 'Please select a department'
                      : null,
          decoration: _inputDecoration(null),
        ),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Role'),
        Column(
          children: [
            RadioListTile<String>(
              title: const Text('Student'),
              value: 'Student',
              groupValue: role,
              onChanged: (val) => setState(() => role = val!),
            ),
            RadioListTile<String>(
              title: const Text('Faculty Member'),
              value: 'Faculty Member',
              groupValue: role,
              onChanged: (val) => setState(() => role = val!),
            ),
            RadioListTile<String>(
              title: const Text('Other'),
              value: 'Other',
              groupValue: role,
              onChanged: (val) => setState(() => role = val!),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Special Requirements/Notes'),
        const SizedBox(height: 6),
        TextFormField(
          controller: notesController,
          maxLines: 4,
          decoration: _inputDecoration(
            'Enter any special requirements or notes',
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: termsAccepted,
          onChanged: (val) => setState(() => termsAccepted = val ?? false),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => termsAccepted = !termsAccepted),
            child: const Text.rich(
              TextSpan(
                text: 'I agree to the ',
                children: [
                  TextSpan(
                    text: 'terms and conditions',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' and consent to the processing of my data for event registration purposes.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: const OutlineInputBorder(),
    );
  }
}

Future<Object?> showRegisterEventDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierColor: Colors.transparent,
    barrierDismissible: true,
    pageBuilder: (context, anim1, anim2) {
      return const RegisterEventPage();
    },
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
    transitionDuration: const Duration(milliseconds: 200),
  );
}
