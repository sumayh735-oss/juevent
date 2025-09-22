import 'package:flutter/material.dart';
import 'package:withfbase/pages/report_page.dart';

class AdminDrawer extends StatelessWidget {
  final String role;
  final int currentIndex;
  final Function(int) onItemSelected;
  final bool isLoggedIn;
  final bool placeOnRight;

  const AdminDrawer({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onItemSelected,
    required this.isLoggedIn,
    this.placeOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 600;

    // ORDER-KAN waa inuu la mid noqdaa _adminPages ee MainAdminPage
    final List<Map<String, dynamic>> drawerItems = [
      {
        'icon': Icons.admin_panel_settings,
        'label': 'Dashboard',
      }, // 0 -> AdminDashboardPage
      {'icon': Icons.home, 'label': 'Home'}, // 1 -> Homepage
      {
        'icon': Icons.event_note,
        'label': 'Events Mgmt',
      }, // 2 -> EventsManagementPage
      {
        'icon': Icons.location_city,
        'label': 'Venues Mgmt',
      }, // 3 -> VenuesManagementPage
      {'icon': Icons.block, 'label': 'Blocked'}, // 4 -> BlockedUsersPage
      {'icon': Icons.bar_chart, 'label': 'Reports'}, // 5 -> ReportPage
    ];

    if (isWideScreen) {
      final rail = NavigationRail(
        backgroundColor: const Color(0xFF0D47A1),
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          onItemSelected(index);
        },
        labelType: NavigationRailLabelType.all,
        destinations:
            drawerItems.map((item) {
              return NavigationRailDestination(
                icon: Icon(item['icon'] as IconData),
                selectedIcon: Icon(
                  item['icon'] as IconData,
                  color: Colors.white,
                ),
                label: Text(item['label'] as String),
              );
            }).toList(),
        selectedIconTheme: const IconThemeData(color: Colors.white),
        unselectedIconTheme: const IconThemeData(color: Colors.white70),
        selectedLabelTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
      );

      return Row(
        mainAxisSize: MainAxisSize.min,
        children:
            placeOnRight
                ? [const VerticalDivider(width: 1), rail]
                : [rail, const VerticalDivider(width: 1)],
      );
    }

    // MOBILE: endDrawer
    return Drawer(
      width: 430,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Color(0xFFE3F2FD)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...drawerItems.asMap().entries.map((entry) {
                      final int index = entry.key;
                      final Map<String, dynamic> item = entry.value;
                      return _buildModernDrawerItem(
                        context,
                        icon: item['icon'] as IconData,
                        label: item['label'] as String,
                        selected: index == currentIndex,
                        onTap: () async {
                          onItemSelected(index);
                          await Future.delayed(
                            const Duration(milliseconds: 150),
                          );
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        //   Navigator.pushReplacement(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => const ReportPage(),
                        //     ),
                        //   );
                      },
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                _CircleLogo(),
                SizedBox(height: 12),
                Text(
                  'Jazeera University',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Admin Panel',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () async {
          onTap();
          await Future.delayed(const Duration(milliseconds: 150));
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color:
                selected ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 53, 64, 73).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleLogo extends StatelessWidget {
  const _CircleLogo();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
        image: DecorationImage(
          image: AssetImage('assets/logoicon.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
