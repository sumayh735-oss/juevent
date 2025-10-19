import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:withfbase/pages/desktop/admindashboard_desktop.dart';
import 'package:withfbase/pages/desktop/booking_form_desktop.dart';
import 'package:withfbase/pages/desktop/events_page_desktop.dart';
import 'package:withfbase/pages/desktop/homepage_desktop.dart';
import 'package:withfbase/pages/desktop/loginpage_desktop.dart';
import 'package:withfbase/pages/desktop/profile_desktop.dart';
import 'package:withfbase/pages/desktop/venues_page_desktop.dart';

class HomeHeaderDesktop extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuTap;

  const HomeHeaderDesktop({
    super.key,
    required this.onMenuTap,
    required String title, // still accepted to keep your calls intact
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  // -------- Helper function to handle Admin button ----------
  Future<void> _handleAdminTap(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginpageDesktop()),
      );
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!doc.exists || doc.data()?['role'] != 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ You are not allowed to access Admin.")),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardDesktop()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error checking admin role: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEE, MMM d').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      color: Colors.blue.shade900,
      child: Row(
        children: [
          // Logo
          Image.asset('assets/logo.png', height: 50),
          const SizedBox(width: 12),
          const Text(
            "JU HALL  EVENT  SYSTEM",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          // Navigation Links
          _navLink("Home", () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomepageDesktop()),
            );
          }),
          _navLink("Events", () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const EventsPageDesktop()),
            );
          }),
          _navLink("Venues", () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const VenuesPageDesktop()),
            );
          }),
          _navLink("Booking", () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BookingFormDesktop()),
            );
          }),
          _navLink("Profile", () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ProfileDesktop()),
            );
          }),
          _navLink("Admin", () {
            _handleAdminTap(context);
          }),

          const SizedBox(width: 20),

          // Date
          Text(
            formattedDate,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(width: 20),

          // Login / Logout (auth-aware)
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snap) {
              final user = snap.data;

              if (user == null) {
                // Not logged in -> show Login
                return ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginpageDesktop()),
                    );
                  },
                  icon: const Icon(Icons.person, size: 18),
                  label: const Text("Login"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                );
              }

              // Logged in -> show avatar + Logout
              final display = (user.displayName?.trim().isNotEmpty ?? false)
                  ? user.displayName!.trim()
                  : (user.email ?? 'User');
              final initial = display.trim().isNotEmpty
                  ? display.trim()[0].toUpperCase()
                  : 'U';

              return Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white24,
                    child: Text(initial,
                        style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out')),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HomepageDesktop()),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, size: 18, color: Colors.white),
                    label: const Text(
                      "Logout",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _navLink(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }
}
