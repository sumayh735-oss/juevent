import 'package:flutter/material.dart';
import 'package:withfbase/pages/booking_form.dart';
import 'package:withfbase/pages/events_page.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/pages/venues_page.dart';
import 'package:withfbase/widgets/home_header.dart';

class Adminnnnnnnnnnnnn extends StatefulWidget {
  const Adminnnnnnnnnnnnn({super.key});

  @override
  State<Adminnnnnnnnnnnnn> createState() => _EventsPageState();
}

class _EventsPageState extends State<Adminnnnnnnnnnnnn> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool showFilter = false;
  String selectedEventType = 'All Types';
  String selectedDateRange = 'Any Date';
  String selectedHall = 'All Venues';
  int selectedIndex = 1;
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventsPage()),
    );
  }

  void _navigateToBooking() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookingForm()));
  }

  void _navigateToVenues() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VenuesPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Welcome to Jazeera',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Events'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEvents();
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text('Book Now'),
              onTap: () {
                Navigator.pop(context);
                _navigateToBooking();
              },
            ),
            ListTile(
              leading: const Icon(Icons.place),
              title: const Text('Venues'),
              onTap: () {
                Navigator.pop(context);
                _navigateToVenues();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
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
                // Fixed Header
                SliverToBoxAdapter(
                  child: HomeHeader(
                    onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                    onFilterTap: () {},
                    title: '',
                  ),
                ),

                // Title + Filter button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "Upcoming Events",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.filter_alt_outlined),
                          onPressed: () {
                            setState(() {
                              showFilter = !showFilter;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Filter Section
                if (showFilter)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterRow(
                            label: 'Event Type',
                            value: selectedEventType,
                            options: [
                              'All Types',
                              'Conference',
                              'Seminar',
                              'Workshop',
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedEventType = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFilterRow(
                            label: 'Date Range',
                            value: selectedDateRange,
                            options: [
                              'Any Date',
                              'This Week',
                              'Next Week',
                              'This Month',
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedDateRange = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFilterRow(
                            label: 'Hall',
                            value: selectedHall,
                            options: [
                              'All Venues',
                              'Venue 1',
                              'Venue 2',
                              'Main Hall',
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedHall = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    selectedEventType = 'All Types';
                                    selectedDateRange = 'Any Date';
                                    selectedHall = 'All Venues';
                                  });
                                },
                                child: const Text('Reset'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showFilter = false;
                                  });
                                },
                                child: const Text('Apply Filters'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Events List + Footer
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _eventCard(
                        title: "Annual Science Conference",
                        dateText: "Tue, May 6",
                        timeText: "1:00 PM",
                        venue: "Venue 1",
                        daysLeft: "5 days left",
                        tag: "Conference",
                        image: 'assets/hall1.jpeg',
                        description:
                            "Showcasing the latest research and innovation in science. Join us for keynote speeches, panel discussions, poster...",
                      ),
                      const SizedBox(height: 16),
                      _eventCard(
                        title: "Leadership Workshop",
                        dateText: "Thu, May 8",
                        timeText: "4:00 PM",
                        venue: "Venue 2",
                        daysLeft: "8 days left",
                        tag: "Workshop",
                        image: 'assets/hall1.jpeg',
                        description:
                            "Develop essential leadership skills for today's challenges with our expert facilitators.",
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                const SliverToBoxAdapter(child: FooterPage()),
              ],
            ),
          ),

          // Fixed Home Header
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

  Widget _buildFilterRow({
    required String label,
    required String value,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items:
                options.map((option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _eventCard({
    required String title,
    required String dateText,
    required String timeText,
    required String venue,
    required String daysLeft,
    required String tag,
    required String image,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  image,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.favorite_border, color: Colors.white),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    daysLeft,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(color: Colors.blue, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      venue,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
