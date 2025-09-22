import 'package:flutter/material.dart';
import 'package:withfbase/pages/admin_events_mgmt.dart';
import 'package:withfbase/pages/admin_venues_mgmt_page.dart';
import 'package:withfbase/pages/admindashboard.dart';
import 'package:withfbase/pages/homepage.dart';
import 'package:withfbase/pages/report_page.dart';
import 'package:withfbase/widgets/BlockedUsersPage.dart';
import 'package:withfbase/widgets/adminDrawer.dart';
import 'package:withfbase/pages/report2.dart';

class MainAdminPage extends StatefulWidget {
  final int initialIndex;
  const MainAdminPage({super.key, this.initialIndex = 0});

  @override
  State<MainAdminPage> createState() => _MainAdminPageState();
}

class _MainAdminPageState extends State<MainAdminPage> {
  late int _currentIndex;

  final List<Widget> _adminPages = const [
    AdminDashboardPage(), // 0
    Homepage(), // 1
    AdminEventsMgmt(), // 2
    AdminVenuesMgmtPage(), // 3
    BlockedUsersPage(), // 4
    ReportPage(), // 5
    FullEventReportPage(), //6
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _goTo(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 600;

    final adminDrawer = AdminDrawer(
      role: 'Admin',
      currentIndex: _currentIndex,
      isLoggedIn: true,
      placeOnRight: true,
      onItemSelected: _goTo,
    );

    return Scaffold(
      endDrawer: isWide ? null : adminDrawer,
      endDrawerEnableOpenDragGesture: true,
      body:
          isWide
              ? Row(
                children: [
                  Expanded(child: _adminPages[_currentIndex]),
                  adminDrawer, // right rail
                ],
              )
              : _adminPages[_currentIndex],
      bottomNavigationBar:
          isWide
              ? null
              : BottomNavigationBar(
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                onTap: _goTo,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.admin_panel_settings),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.event_note),
                    label: 'Events Mgmt',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.location_city),
                    label: 'Venues Mgmt',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.block),
                    label: 'Blocked',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart),
                    label: 'Reports',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart),
                    label: 'ReportsT',
                  ),
                ],
              ),
    );
  }
}
