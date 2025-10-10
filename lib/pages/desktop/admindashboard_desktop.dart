import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/admin_home_header_desktop.dart';
import 'package:withfbase/pages/desktop/events_management_desktop.dart';
import 'package:withfbase/pages/desktop/venues_management_desktop.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/pages/todaysevent.dart';

class AdminDashboardDesktop extends StatefulWidget {
  const AdminDashboardDesktop({super.key});

  @override
  State<AdminDashboardDesktop> createState() => _AdminDashboardDesktopState();
}

class _AdminDashboardDesktopState extends State<AdminDashboardDesktop> {
  int selectedTab = 0;

  int eventsCount = 0;
  int venuesCount = 0;
  int todayCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  Future<void> fetchCounts() async {
    try {
      final eventsSnapshot =
          await FirebaseFirestore.instance.collection('events').get();
      final venuesSnapshot =
          await FirebaseFirestore.instance.collection('venues').get();
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day, 0, 0, 0);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayEventsSnapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where('startDateTime', isGreaterThanOrEqualTo: todayStart)
              .where('startDateTime', isLessThan: todayEnd)
              .get();

      if (!mounted) return; // ✅ badbaado
      setState(() {
        eventsCount = eventsSnapshot.docs.length;
        venuesCount = venuesSnapshot.docs.length;
        todayCount = todayEventsSnapshot.docs.length;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return; // ✅ badbaado
      setState(() {
        isLoading = false;
      });
      debugPrint('Error fetching counts: $e');
    }
  }

  Widget _buildTabContent() {
    switch (selectedTab) {
      case 1:
        return const EventsManagementDesktop();
      case 2:
        return const VenuesManagementDesktop();
      case 3:
        return const TodayEventsPage();
      default:
        return _buildDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Builder(
            builder:
                (context) => AdminHomeHeaderDesktop(
                  onMenuTap: () => Scaffold.of(context).openEndDrawer(), title: 'Admin Dashbourd',
                ),
          ),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 20),
                  _buildTopBar(context),
                  const SizedBox(height: 24),
                  _buildTabs(),
                  const SizedBox(height: 24),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildTabContent(),
                  const SizedBox(height: 40),
                  const FooterPage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Admin Dashboard",
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.exit_to_app_rounded, size: 28),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => AdminHomeHeaderDesktop( onMenuTap: () => Scaffold.of(context).openEndDrawer(), title: 'Home Page',),
              ),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tabIcon(Icons.dashboard, "Dashboard", 0),
          _tabIcon(Icons.event, "Events", 1),
          _tabIcon(Icons.place, "Venues", 2),
          _tabIcon(Icons.event_available, "Today", 3),
        ],
      ),
    );
  }

  Widget _tabIcon(IconData icon, String label, int index) {
    final bool isActive = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.blue : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
       Center(
  child: Wrap(
    spacing: 16, // farqiga horizontal
    runSpacing: 16, // farqiga vertical haddii saf kale uu jiro
    alignment: WrapAlignment.center, // ✅ center garee
    children: [
      SizedBox(
        width: 600, // ✅ cabbir yar
        child: _buildDashboardCard(
          "Events",
          Icons.calendar_today,
          Colors.blue,
          eventsCount,
          "Total Events",
          onTap: () => setState(() => selectedTab = 1),
        ),
      ),
      SizedBox(
        width: 600,
        child: _buildDashboardCard(
          "Venues",
          Icons.place,
          Colors.orange,
          venuesCount,
          "Available Venues",
          onTap: () => setState(() => selectedTab = 2),
        ),
      ),
      SizedBox(
        width: 600,
        child: _buildDashboardCard(
          "Today",
          Icons.event_available,
          Colors.purple,
          todayCount,
          "Today's Events",
          onTap: () => setState(() => selectedTab = 3),
        ),
      ),
    ],
  ),
),
   
        const SizedBox(height: 24),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildQuickAction(Icons.add_box, "Add New Event", () {
                  setState(() => selectedTab = 1);
                }),
                _buildQuickAction(Icons.add_location_alt, "Add New Venue", () {
                  setState(() => selectedTab = 2);
                }),
                _buildQuickAction(Icons.bar_chart, "View Reports", () {
                  setState(() => selectedTab = 3);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    String title,
    IconData icon,
    Color color,
    int count,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildQuickAction(
  IconData icon,
  String label,
  VoidCallback onTap,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(40), // ✅ height yar
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), // yar
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 1.5,
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue.shade700,
      ),
      icon: Icon(icon, size: 16), // ✅ icon yar
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 13, // ✅ font yar
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: onTap,
    ),
  );
}

}
