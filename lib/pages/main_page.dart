import 'package:flutter/material.dart';
import 'package:withfbase/pages/availability_page.dart';
import 'package:withfbase/pages/booking_form.dart';
import 'package:withfbase/pages/homepage.dart';
import 'package:withfbase/pages/events_page.dart';
import 'package:withfbase/pages/profile.dart';
import 'package:withfbase/pages/venues_page.dart';
import 'package:withfbase/widgets/app_drawer.dart';

class MainPage extends StatefulWidget {
  final int initialIndex;

  const MainPage({super.key, this.initialIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    Homepage(),
    EventsPage(),
    VenuesPage(),
    BookingForm(),
    ProfilePage(),
    AvailabilityPage(isLoggedIn: true),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onDrawerItemTapped(int index) async {
    if (index < _pages.length) {
      setState(() {
        _currentIndex = index;
      });
    }

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: AppDrawer(
        role: "guest",
        currentIndex: _currentIndex,
        onItemSelected: _onDrawerItemTapped,
        isLoggedIn: false, // Example, beddel marka aad rabto
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder:
            (child, animation) =>
                FadeTransition(opacity: animation, child: child),
        child: _pages[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Venues'),
          BottomNavigationBarItem(icon: Icon(Icons.book_online), label: 'Book'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
