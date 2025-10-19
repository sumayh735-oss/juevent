import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:withfbase/pages/event_model.dart';
import 'package:withfbase/widgets/home_header.dart';
import 'package:withfbase/widgets/event_detail_page.dart';
import 'package:withfbase/pages/footer.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
List<String> eventTypes = ['All Types'];
List<String> halls = ['All Venues'];

  bool showFilter = false;

  String selectedEventType = 'All Types';
  String selectedDateRange = 'Any Date';
  String selectedHall = 'All Venues';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
@override
void initState() {
  super.initState();
  _loadCategories();
  _loadVenues();
}

Future<void> _loadCategories() async {
  final snapshot = await FirebaseFirestore.instance.collection('categories').get();
  final types = snapshot.docs.map((doc) => doc['name'].toString()).toList();

  setState(() {
    eventTypes = ['All Types', ...types];
  });
}

Future<void> _loadVenues() async {
  final snapshot = await FirebaseFirestore.instance.collection('venues').get();
  final vens = snapshot.docs.map((doc) => doc['name'].toString()).toList();

  setState(() {
    halls = ['All Venues', ...vens];
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 140)),

              // Title + Filter Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "All Events",
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
          // ✅ Event Type from Firestore
          _buildFilterRow(
            label: 'Event Type',
            value: selectedEventType,
            options: eventTypes,
            onChanged: (value) => setState(() => selectedEventType = value!),
          ),
          const SizedBox(height: 16),

          // ✅ Date Range same as before
          _buildFilterRow(
            label: 'Date Range',
            value: selectedDateRange,
            options: [
              'Any Date',
              'This Week',
              'Next Week',
              'This Month',
            ],
            onChanged: (value) => setState(() => selectedDateRange = value!),
          ),
          const SizedBox(height: 16),

          // ✅ Hall from Firestore
          _buildFilterRow(
            label: 'Hall',
            value: selectedHall,
            options: halls,
            onChanged: (value) => setState(() => selectedHall = value!),
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
                onPressed: () => setState(() => showFilter = false),
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
              // Event List
              StreamBuilder<QuerySnapshot>(
                stream:
                    (() {
                      Query query = FirebaseFirestore.instance.collection(
                        'events',
                      );

                      // Filter by status Approved only (for user view)
                      query = query.where('status', isEqualTo: 'Approved');

                      // Filter by category (event type)
                      if (selectedEventType != 'All Types') {
                        query = query.where(
                          'category',
                          isEqualTo: selectedEventType,
                        );
                      }

                      // Filter by venue
                      if (selectedHall != 'All Venues') {
                        query = query.where('venue', isEqualTo: selectedHall);
                      }

                      // Filter by date range on startDateTime
final now = DateTime.now();

DateTime startDateFilter = DateTime(1900); // default: include all
DateTime endDateFilter = DateTime(2100);   // default: include all

if (selectedDateRange == 'This Week') {
  final startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
  final endOfWeek = startOfWeek
      .add(const Duration(days: 7))
      .subtract(const Duration(seconds: 1)); // end of week at 23:59:59

  startDateFilter = startOfWeek;
  endDateFilter = endOfWeek;
} else if (selectedDateRange == 'Next Week') {
  final startOfNextWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1))
      .add(const Duration(days: 7));
  final endOfNextWeek = startOfNextWeek
      .add(const Duration(days: 7))
      .subtract(const Duration(seconds: 1));

  startDateFilter = startOfNextWeek;
  endDateFilter = endOfNextWeek;
} else if (selectedDateRange == 'This Month') {
  final startOfMonth = DateTime(now.year, now.month, 1);
  final endOfMonth = DateTime(now.year, now.month + 1, 1)
      .subtract(const Duration(seconds: 1));

  startDateFilter = startOfMonth;
  endDateFilter = endOfMonth;
}

// ✅ Apply to Firestore
query = query
    .where('startDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDateFilter))
    .where('startDateTime',
        isLessThanOrEqualTo: Timestamp.fromDate(endDateFilter));


                      return query.snapshots();
                    })(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return const SliverToBoxAdapter(
                      child: Center(child: Text('Error loading events')),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(child: Text('No events found')),
                    );
                  }

                  final events =
                      snapshot.data!.docs
                          .map(
                            (doc) => EventModel.fromMap(
                              doc.data() as Map<String, dynamic>,
                              doc.id,
                            ),
                          )
                          .toList();

                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = events[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: _eventCard(event),
                      );
                    }, childCount: events.length),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              const SliverToBoxAdapter(child: FooterPage()),
            ],
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeader(
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              onFilterTap: () => setState(() => showFilter = !showFilter),
              title: '',
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
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButton<String>(
          isExpanded: true,
          value: value,
          items:
              options
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
  Widget _eventCard(EventModel event) {
    final now = DateTime.now();
    event.endDateTime.isBefore(now);

    final daysLeft = event.startDateTime.difference(now).inDays;
    final daysLeftText = daysLeft <= 0 ? "Today" : "$daysLeft days left";

    final formattedDate = DateFormat("E, MMM d").format(event.startDateTime);
    final formattedTime = DateFormat("h:mm a").format(event.startDateTime);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailPage(eventId: event.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- IMAGE + TAG + DAYS LEFT ----------
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  
                  child: CachedNetworkImage(
                    imageUrl: event.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (context, url, error) =>
                            const Icon(Icons.broken_image, size: 48),
                  ),
                ),

                // Category tag
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Favorite icon
                const Positioned(
                  top: 8,
                  right: 8,
                  child: Icon(Icons.favorite_border, color: Colors.white),
                ),

                // Days left
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      daysLeftText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ---------- DETAILS ----------
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedTime,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Date
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),

                  // Venue
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.venue,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
