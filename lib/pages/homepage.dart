import 'package:flutter/material.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/pages/main_page.dart';
import 'package:withfbase/widgets/featured_venues.dart';
import 'package:withfbase/widgets/home_header.dart';
import 'package:withfbase/widgets/hero_section.dart';
import 'package:withfbase/widgets/category_chips.dart';
import 'package:withfbase/widgets/booking_prompt_card.dart';
import 'package:withfbase/widgets/upcomingevent.dart';
import 'package:withfbase/pages/availability_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = "All";

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToEvents() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainPage(initialIndex: 1), // tabka Events
      ),
    );
  }

  void _navigateToBooking() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainPage(initialIndex: 3),
      ), // Booking tab
    );
  }

  void _navigateToVenues() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainPage(initialIndex: 2),
      ), // Venues tab
    );
  }

  void _navigateToAvailability() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AvailabilityPage(isLoggedIn: true),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: onTap,
            child: const Text(
              "View All →",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxedActionButtonNobg(IconData icon, String label, Color bgColor) {
    return Container(
      width: 110,
      height: 120,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  Theme.of(context).textTheme.bodyMedium?.color ??
                  Colors.black87,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 8.0,
            radius: const Radius.circular(8),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeroSection(
                        onExploreEvents: _navigateToEvents,
                        onCheckAvailability: _navigateToAvailability,
                      ),
                      const SizedBox(height: 12),
                      CategoryChips(
                        selected: _selectedCategory,
                        onSelected: (label) {
                          setState(() {
                            _selectedCategory = label;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            GestureDetector(
                              onTap: _navigateToEvents,
                              child: _boxedActionButtonNobg(
                                Icons.event,
                                "Events",
                                Colors.blue,
                              ),
                            ),
                            GestureDetector(
                              onTap: _navigateToVenues,
                              child: _boxedActionButtonNobg(
                                Icons.place,
                                "Venues",
                                Colors.green,
                              ),
                            ),
                            GestureDetector(
                              onTap: _navigateToBooking,
                              child: _boxedActionButtonNobg(
                                Icons.event,
                                "Book Now",
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      _sectionHeader("Featured Venues", _navigateToVenues),
                      const SizedBox(height: 15),
                      const FeaturedVenues(),
                      const SizedBox(height: 24),
                      _sectionHeader("Upcoming Events", _navigateToEvents),
                      const UpcomingEventsSection(),
                      const SizedBox(height: 20),
                      BookingPromptCard(
                        onCheckAvailability: _navigateToAvailability,
                      ),
                      const FooterPage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Builder(
              builder:
                  (context) => HomeHeader(
                    onMenuTap: () => Scaffold.of(context).openEndDrawer(),
                    title: '',
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
