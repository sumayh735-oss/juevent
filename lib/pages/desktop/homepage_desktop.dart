import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/admin_events_mgmt_desktop.dart';
import 'package:withfbase/pages/desktop/category_chips_desktop.dart';
import 'package:withfbase/pages/desktop/featured_venues_desktop.dart';
import 'package:withfbase/pages/desktop/upcomingevent_desktop.dart';
import 'package:withfbase/pages/availability_page.dart';
import 'package:withfbase/widgets/booking_prompt_card.dart';
import 'package:withfbase/pages/footer.dart';
import 'home_header_desktop.dart';
import 'hero_section_desktop.dart';
   
class HomepageDesktop extends StatefulWidget {
  const HomepageDesktop({super.key});

  @override
  State<HomepageDesktop> createState() => _HomepageDesktopState();
}

class _HomepageDesktopState extends State<HomepageDesktop> {
  final ScrollController _scrollController = ScrollController();
  
  // ✅ default All Events
  String _selectedCategory = "All Events";  

  void _navigateToEvents() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AdminEventsMgmtDesktop()),
    );
  }

  void _navigateToVenues() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AdminEventsMgmtDesktop()),
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
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, fontSize: 24),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1550), // ✅ sax 1550
          child: Stack(
            children: [
              Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                thickness: 8,
                radius: const Radius.circular(8),
                child: ListView(
                  controller: _scrollController,
                  children: [
                    HeroSectionDesktop(
                      onExploreEvents: _navigateToEvents,
                      onCheckAvailability: _navigateToAvailability,
                    ),
                    const SizedBox(height: 2),

                    // ✅ Categories filter
                    CategoryChipsDesktop(
                      selected: _selectedCategory,
                      onSelected: (label) {
                        setState(() {
                          _selectedCategory = label;
                        });
                      },
                    ),
                    const SizedBox(height: 40),

                    // Featured Venues with filter
                    _sectionHeader("Featured Venues", _navigateToVenues),
                      const SizedBox(height: 15),
                      const FeaturedVenuesDesktop(),
                      const SizedBox(height: 24),

                    // Upcoming Events with filter
                    _sectionHeader("Upcoming Events", _navigateToEvents),
                    UpcomingeventDesktop(category: _selectedCategory),
                    const SizedBox(height: 40),

                    BookingPromptCard(
                      onCheckAvailability: _navigateToAvailability,
                    ),
                    const SizedBox(height: 20),

                    const FooterPage(),
                  ],
                ),
              ),

              // Fixed header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: HomeHeaderDesktop(
                  onMenuTap: () => Scaffold.of(context).openEndDrawer(), title: 'Home Page',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
