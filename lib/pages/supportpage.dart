import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/help_center_desktop.dart';

class Supportpage extends StatefulWidget {
  const Supportpage({super.key});

  @override
  State<Supportpage> createState() => _SupportpageState();
}

class _SupportpageState extends State<Supportpage> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _category = 'General';

  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'category': _category,
        'uid': user?.uid,
        'email': user?.email,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'open',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket submitted. We’ll get back soon.')),
      );
      _formKey.currentState!.reset();
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() => _category = 'General');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        elevation: 0.8,
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            // Intro / CTA
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.indigo.shade50,
                border: Border.all(color: Colors.indigo.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent, color: Colors.indigo, size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Need help? Send us a message or create a support ticket.',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const _ContactOptionsSheet(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.call),
                    label: const Text('Contact options'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Ticket form
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: const [
                        Icon(Icons.report_problem_outlined,
                            size: 18, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text('Create a ticket',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'General', child: Text('General')),
                          DropdownMenuItem(value: 'Account', child: Text('Account')),
                          DropdownMenuItem(value: 'Events', child: Text('Events')),
                          DropdownMenuItem(value: 'Payments', child: Text('Payments')),
                        ],
                        onChanged: (v) => setState(() => _category = v ?? 'General'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _subjectCtrl,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          hintText: 'Short summary',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _messageCtrl,
                        minLines: 6,
                        maxLines: 10,
                        decoration: InputDecoration(
                          labelText: 'Message',
                          hintText: 'Describe the issue or request',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().length < 10)
                            ? 'Please add more details'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _sending ? null : _submit,
                          icon: _sending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.send),
                          label: Text(_sending ? 'Sending…' : 'Submit ticket'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // FAQ shortcut
            Card(
              elevation: 0.8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF2FF),
                  child: Icon(Icons.help_outline, color: Colors.indigo),
                ),
                title: const Text('Browse Help Center'),
                subtitle: const Text('Find quick answers to common questions'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HelpCenterDesktop(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey.shade50,
    );
  }
}

// Simple contact sheet page (phone / email / WhatsApp placeholders).
class _ContactOptionsSheet extends StatelessWidget {
  const _ContactOptionsSheet();

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String title, String subtitle) {
      return Card(
        elevation: 0.6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.indigo.withOpacity(.12),
            child: Icon(icon, color: Colors.indigo),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opening $title…')),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Contact options')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          tile(Icons.email, 'Email', 'support@example.com'),
          tile(Icons.call, 'Phone', '+252 61 000 0000'),
          tile(Icons.wifi_calling, 'WhatsApp', '+252 61 000 0001'),
        ],
      ),
    );
  }
}


