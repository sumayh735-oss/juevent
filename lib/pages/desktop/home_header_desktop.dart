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
    required this.onMenuTap, required String title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  // -------- Helper function to handle Admin button ----------
  Future<void> _handleAdminTap(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Haddii user aanu login ahayn
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginpageDesktop()),
      );
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data()?['role'] != 'admin') {
        // User exists laakiin ma aha admin
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ You are not allowed to access Admin.")),
        );
        return;
      }

      // Haddii uu admin yahay
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
    String formattedDate = DateFormat('EEE, MMM d').format(DateTime.now());

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

          // Login button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginpageDesktop()),
              );
            },
            icon: const Icon(Icons.person, size: 18),
            label: const Text("Login"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
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
