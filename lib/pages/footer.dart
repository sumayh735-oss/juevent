import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FooterPage extends StatelessWidget {
  const FooterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF002F6C),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo and Title
          Column(
            children: [
              Image.asset(
                'assets/logo.png', // Make sure this image exists
                height: 60,
              ),
              const SizedBox(height: 10),
              const Text(
                'Jazeera University',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Hall Management App v1.0',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // ExpansionTiles
          ExpansionTile(
            title: const Text(
              'Help & Support',
              style: TextStyle(color: Colors.white),
            ),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            children: const [
              ListTile(
                title: Text('FAQs', style: TextStyle(color: Colors.white70)),
              ),
              ListTile(
                title: Text(
                  'Contact Support',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text(
              'Legal & About',
              style: TextStyle(color: Colors.white),
            ),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            children: const [
              ListTile(
                title: Text(
                  'Terms of Service',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ListTile(
                title: Text(
                  'Privacy Policy',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Contact Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Contact Information',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Jazeera University Campus, Main Street',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '+123 456 7890',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email, color: Colors.white70, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'events@jazeerauniversity.edu',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Social Media Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(FontAwesomeIcons.twitter, color: Colors.white70, size: 20),
              SizedBox(width: 20),
              Icon(FontAwesomeIcons.facebookF, color: Colors.white70, size: 20),
              SizedBox(width: 20),
              Icon(FontAwesomeIcons.instagram, color: Colors.white70, size: 20),
              SizedBox(width: 20),
              Icon(
                FontAwesomeIcons.linkedinIn,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Footer Text
          const Text(
            '© 2025 Jazeera University',
            style: TextStyle(color: Colors.white70),
          ),
          const Text(
            'All rights reserved',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
