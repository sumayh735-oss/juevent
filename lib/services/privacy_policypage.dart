import 'package:flutter/material.dart';

class PolicyTermsDialog extends StatelessWidget {
  const PolicyTermsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          "App Policies",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 450,
          child: Column(
            children: [
              const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(icon: Icon(Icons.lock_outline), text: "Privacy"),
                  Tab(icon: Icon(Icons.rule), text: "Terms"),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: TabBarView(
                  children: [
                    // ✅ Privacy Policy Content
                    SingleChildScrollView(
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '''
📌 Privacy Policy

We are committed to protecting your privacy. This policy explains how we collect, use, and safeguard your data.

1. Information Collection:
   - We collect your name, email, phone number, and usage data only when necessary.
   - No sensitive information is stored without your consent.

2. Use of Information:
   - Your data is used strictly to improve services and provide better support.
   - We do not sell or share your personal data with third parties.

3. Data Security:
   - All user data is stored securely with encryption and access control.
   - Unauthorized access to user information is strictly prohibited.

4. Your Rights:

   - You may opt out of email notifications.

📧 For inquiries, contact us at: 
                                    +252618111140
                                    info@jazeerauniversity.edu.so
                                    jazeerauniversity.edu.so
                          ''',
                          style: TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ),
                    ),

                    // ✅ Terms & Conditions Content
                    SingleChildScrollView(
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '''
⚖️ Terms & Conditions

By using this app, you agree to the following terms and conditions:

1. General Usage:
   - You must provide accurate registration information.
   - Misuse of the app for illegal or harmful activities is prohibited.

2. User Responsibilities:
   - Respect other users and maintain appropriate behavior.
   - Sharing offensive, harmful, or false content is not allowed.

3. Violation Policy:
   - First Violation: Warning notification will be sent.
   - Second Violation: Account will be temporarily suspended (1–2 days).
   - Third Violation: Permanent block may be applied.

4. App Rights:
   - We reserve the right to update or modify these terms at any time.
   - Failure to comply with these rules may lead to restricted access.

❗ Important:
If violations occur repeatedly, your account may be terminated permanently without further notice.

📝 Last Updated: October 2025
                          ''',
                          style: TextStyle(fontSize: 14, height: 1.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
