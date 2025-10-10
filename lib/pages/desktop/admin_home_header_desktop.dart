import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:withfbase/pages/desktop/BlockedUsersPage_desktop.dart';
import 'package:withfbase/pages/desktop/admin_events_mgmt_desktop.dart';
import 'package:withfbase/pages/desktop/admin_venues_mgmt_page_desktop.dart';
import 'package:withfbase/pages/desktop/admindashboard_desktop.dart';
import 'package:withfbase/pages/desktop/categories_page_desktop.dart';
import 'package:withfbase/pages/desktop/homepage_desktop.dart';
import 'package:withfbase/pages/desktop/loginpage_desktop.dart';
import 'package:withfbase/pages/desktop/report_desktop.dart';

class AdminHomeHeaderDesktop extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuTap;

  const AdminHomeHeaderDesktop({
    super.key,
    required this.onMenuTap, required String title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  // -------- Helper function to handle Admin role ----------
  Future<void> _handleAdminTap(BuildContext context, Widget page) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User aan login ahayn
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
        // User ma aha admin
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ You are not allowed to access Admin.")),
        );
        return;
      }

      // Haddii uu admin yahay → navigate page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
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
            "JU HALL  EVENT  SYSTEM - Admin",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),

          // Navigation Links (Admin)
          _navLink("Dashboard", () {
            _handleAdminTap(context, const AdminDashboardDesktop());
          }),
          _navLink("Home", () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) =>   HomepageDesktop( )),
            );
          }),
          _navLink("Events Mgmt", () {
            _handleAdminTap(context, const AdminEventsMgmtDesktop());
          }),
          _navLink("Venues Mgmt", () {
            _handleAdminTap(context, const AdminVenuesMgmtPageDesktop());
          }),
          _navLink("Blocked Users", () {
            _handleAdminTap(context, const BlockedUsersPageDesktop());
          }),
          _navLink("Reports", () {
            _handleAdminTap(context, const ReportDesktop());
          }),
          
          _navLink("Categories", () {

            _handleAdminTap(context, const CategoriesPageDesktop());
          }),

          const SizedBox(width: 20),

          // Date
          Text(
            formattedDate,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(width: 20),

          // Logout / Login button
          ElevatedButton.icon(
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginpageDesktop()),
              );
            },

            icon: const Icon(Icons.logout, size: 18),
            label: const Text("Logout"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
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
