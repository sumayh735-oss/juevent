import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/admin_home_header_desktop.dart';
import 'package:withfbase/pages/desktop/events_management_desktop.dart';
import 'package:withfbase/pages/desktop/todaysevent_desktop.dart';
import 'package:withfbase/pages/desktop/venues_management_desktop.dart';
import 'package:withfbase/pages/footer.dart';

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
  final ScrollController _listCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchCounts();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    super.dispose();
  }
Future<void> fetchCounts() async {
  try {
    // Total events & venues
    final eventsSnap =
        await FirebaseFirestore.instance.collection('events').get();
    final venuesSnap =
        await FirebaseFirestore.instance.collection('venues').get();

    // Today's range (local day)
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));

    // Events happening today
    final todaySnap = await FirebaseFirestore.instance
        .collection('events')
        .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('startDateTime', isLessThan: Timestamp.fromDate(end))
        .get();

    if (!mounted) return;
    setState(() {
      eventsCount = eventsSnap.docs.length;
      venuesCount = venuesSnap.docs.length;
      todayCount  = todaySnap.docs.length;
      isLoading   = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() => isLoading = false);
    debugPrint('Error fetching counts: $e');
  }
}

  // ... fetchCounts(), _buildTopBar(), _buildTabs(), _buildDashboardCard(), _buildQuickAction() iwm sidii hore ...

  // Helper: same header + tabs + divider + Expanded(child)
  Widget _sectionScaffold(Widget child) {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildTopBar(context),
        const SizedBox(height: 24),
        _buildTabs(),
        const SizedBox(height: 8),
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
            builder: (context) => AdminHomeHeaderDesktop(
              onMenuTap: () => Scaffold.of(context).openEndDrawer(),
              title: 'Admin Dashboard',
            ),
          ),

          // 🔽 Halkan ayaa la beddelay
          Expanded(
            child: () {
              // Tab 1: Events  → Expanded child, MA AHA ListView child
              if (selectedTab == 1) {
                return _sectionScaffold(const EventsManagementDesktop());
              }
              // Tab 2: Venues
              if (selectedTab == 2) {
                return _sectionScaffold(const VenuesManagementDesktop());
              }
              // Tab 3: Today
              if (selectedTab == 3) {
                return _sectionScaffold(const TodayseventDesktop());
              }

              // Tab 0: Dashboard → wali ListView (waa content gaaban)
              return Scrollbar(
                controller: _listCtrl,
                thumbVisibility: true,
                child: ListView(
                  controller: _listCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    const SizedBox(height: 20),
                    _buildTopBar(context),
                    const SizedBox(height: 24),
                    _buildTabs(),
                    const SizedBox(height: 24),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
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
            Navigator.of(context).pop();
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

  // ----- Dashboard Section -----
  Widget _buildDashboard() {
    return Column(
      children: [
        Center(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildDashboardCard(
                "Events",
                Icons.calendar_today,
                Colors.blue,
                eventsCount,
                "Total Events",
                () => setState(() => selectedTab = 1),
              ),
              _buildDashboardCard(
                "Venues",
                Icons.place,
                Colors.orange,
                venuesCount,
                "Available Venues",
                () => setState(() => selectedTab = 2),
              ),
              _buildDashboardCard(
                "Today",
                Icons.event_available,
                Colors.purple,
                todayCount,
                "Today's Events",
                () => setState(() => selectedTab = 3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Quick Actions",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildQuickAction(
                    Icons.add_box, "Add New Event", () => setState(() => selectedTab = 1)),
                _buildQuickAction(Icons.add_location_alt, "Add New Venue",
                    () => setState(() => selectedTab = 2)),
                _buildQuickAction(Icons.bar_chart, "View Reports",
                    () => setState(() => selectedTab = 3)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(String title, IconData icon, Color color, int count,
      String subtitle, VoidCallback onTap) {
    return SizedBox(
      width: 600,
      child: Card(
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
                Text(count.toString(),
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
                Text(subtitle,
                    style:
                        const TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildQuickAction(
      IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 1.5,
          backgroundColor: Colors.blue.shade50,
          foregroundColor: Colors.blue.shade700,
        ),
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        onPressed: onTap,
      ),
    );
  }
}
