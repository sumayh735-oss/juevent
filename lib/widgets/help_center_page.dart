import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  Future<void> _mail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
      query: 'subject=App Support&body=Hi, I need help with...',
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('FAQ'),
            subtitle: Text('Common questions and answers'),
          ),
          ExpansionTile(
            title: const Text('How do I edit my profile?'),
            children: const [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Go to Profile → Edit, change fields, and Save.'),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('How to reset my password?'),
            children: const [
              Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Open Security → Update Password or use Reset link.',
                ),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Contact Support'),
            subtitle: const Text('support@example.com'),
            onTap: _mail,
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (_) => const AlertDialog(
                      title: Text('Terms of Service'),
                      content: SingleChildScrollView(
                        child: Text(
                          'Sample Terms... (replace with real content)',
                        ),
                      ),
                    ),
              );
            },
          ),
        ],
      ),
    );
  }
}
