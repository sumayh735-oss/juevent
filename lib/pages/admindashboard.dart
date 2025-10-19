// -----------------------------------------------------------------------------
// admin_dashboard_page.dart
// FINAL FIXED VERSION (FULL PAGE, STABLE, NO FRAME SKIP)
// Works with EventsManagementPage, VenuesManagementPage, TodayEventsPage
// ----------------------------------------------------------------------------- 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/events_management_page.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/pages/full_event_report_22.dart';
import 'package:withfbase/pages/main_page.dart';
import 'package:withfbase/pages/todaysevent.dart';
import 'package:withfbase/pages/venues_management_page.dart';
import 'package:withfbase/widgets/home_header.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
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
      final firestore = FirebaseFirestore.instance;
      final eventsSnapshot = await firestore.collection('events').get();
      final venuesSnapshot = await firestore.collection('venues').get();

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayEventsSnapshot = await firestore
          .collection('events')
          .where('startDateTime', isGreaterThanOrEqualTo: todayStart)
          .where('startDateTime', isLessThan: todayEnd)
          .get();

      if (!mounted) return;
      setState(() {
        eventsCount = eventsSnapshot.docs.length;
        venuesCount = venuesSnapshot.docs.length;
        todayCount = todayEventsSnapshot.docs.length;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error fetching counts: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // ✅ Simple wrapper: header + tabs + divider + Expanded(child)
  Widget _sectionScaffold(Widget child) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildTopBar(context),
        const SizedBox(height: 16),
        _buildTabs(),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Builder(
            builder: (context) => HomeHeader(
              onMenuTap: () => Scaffold.of(context).openEndDrawer(),
              title: 'Admin Dashboard',
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : () {
                    // switch direct — no AnimatedSwitcher (performance win)
                    if (selectedTab == 1) {
                      return _sectionScaffold(const EventsManagementPage());
                    }
                    if (selectedTab == 2) {
                      return _sectionScaffold(const VenuesManagementPage());
                    }
                    if (selectedTab == 3) {
                      return _sectionScaffold(const TodayEventsPage());
                    }
                    if (selectedTab == 4) {
                      return _sectionScaffold(const FullEventReport22());
                    }

                    // default dashboard scroll
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _buildTopBar(context),
                          const SizedBox(height: 24),
                          _buildTabs(),
                          const SizedBox(height: 24),
                          _buildDashboard(),
                          const SizedBox(height: 40),
                          const FooterPage(),
                        ],
                      ),
                    );
                  }(),
          ),
        ],
      ),
    );
  }

  // ----------------- TopBar -----------------
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
          tooltip: 'Logout',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainPage(initialIndex: 0)),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  // ----------------- Tabs -----------------
  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tabIcon(Icons.dashboard, "Dashboard", 0),
          _tabIcon(Icons.event, "Events", 1),
          _tabIcon(Icons.place, "Venues", 2),
          _tabIcon(Icons.today_rounded, "Today", 3),
          _tabIcon(Icons.bar_chart_rounded, "Reports", 4),
        ],
      ),
    );
  }

  Widget _tabIcon(IconData icon, String label, int index) {
    final bool isActive = selectedTab == index;
    return InkWell(
      onTap: () => setState(() => selectedTab = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.blue : Colors.grey, size: 26),
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
      ),
    );
  }

  // ----------------- Dashboard -----------------
  Widget _buildDashboard() {
    return Column(
      children: [
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDashboardCard(
              title: "Events",
              icon: Icons.event_note_rounded,
              color: Colors.blue,
              count: eventsCount,
              subtitle: "Total Events",
              onTap: () => setState(() => selectedTab = 1),
            ),
            _buildDashboardCard(
              title: "Venues",
              icon: Icons.place_rounded,
              color: Colors.orange,
              count: venuesCount,
              subtitle: "Total Venues",
              onTap: () => setState(() => selectedTab = 2),
            ),
            _buildDashboardCard(
              title: "Today",
              icon: Icons.event_available_rounded,
              color: Colors.purple,
              count: todayCount,
              subtitle: "Today's Events",
              onTap: () => setState(() => selectedTab = 3),
            ),
            _buildDashboardCard(
              title: "Reports",
              icon: Icons.bar_chart_rounded,
              color: Colors.green,
              count: eventsCount + venuesCount,
              subtitle: "Analytics",
              onTap: () => setState(() => selectedTab = 4),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Quick Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildQuickAction(Icons.add_box_rounded, "Add New Event", () {
                  setState(() => selectedTab = 1);
                }),
                _buildQuickAction(Icons.add_location_alt_rounded, "Add New Venue", () {
                  setState(() => selectedTab = 2);
                }),
                _buildQuickAction(Icons.today_rounded, "View Today’s Events", () {
                  setState(() => selectedTab = 3);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(
                count.toString(),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          backgroundColor: Colors.blue.shade50,
          foregroundColor: Colors.blue.shade700,
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 15)),
        onPressed: onTap,
      ),
    );
  }
}
