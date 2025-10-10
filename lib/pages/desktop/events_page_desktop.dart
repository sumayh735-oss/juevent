import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:withfbase/pages/desktop/home_header_desktop.dart';
import 'package:withfbase/pages/event_model.dart';
import 'package:withfbase/widgets/event_detail_page.dart';
import 'package:withfbase/pages/footer.dart';

class EventsPageDesktop extends StatefulWidget {
  const EventsPageDesktop({super.key});

  @override
  State<EventsPageDesktop> createState() => _EventsPageDesktopState();
}

class _EventsPageDesktopState extends State<EventsPageDesktop> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool showFilter = false;
  String searchQuery = "";

  /// Filters
  String selectedEventType = "All Types";
  String selectedDateRange = "Any Date";
  String selectedHall = "All Venues";

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
              const SliverToBoxAdapter(child: SizedBox(height: 120)),

              /// 🔹 Title + Filter/Search/Refresh
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        "Upcoming Events",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),

                      /// Filter button
                      IconButton(
                        icon: Icon(
                          showFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          setState(() {
                            showFilter = !showFilter;
                          });
                        },
                      ),
                      const SizedBox(width: 12),

                      /// Search box
                      SizedBox(
                        width: 250,
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Search events...",
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      /// Refresh button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {}); // reload page
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text("Refresh"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

 /// 🔹 Filter Panel
if (showFilter)
  SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                /// Event Type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Event Type",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedEventType,
                        items: [
                          "All Types",
                          "Conference",
                          "Seminar",
                          "Workshop",
                          "Cultural",
                          "Sports"
                        ]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedEventType = val!),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                /// Date Range
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Date Range",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedDateRange,
                        items: [
                          "Any Date",
                          "Today",
                          "This Week",
                          "This Month",
                        ]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedDateRange = val!),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                /// Hall
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hall",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: selectedHall,
                        items: [
                          "All Venues",
                          "Venue 1",
                          "Venue 2",
                          "Venue 3",
                        ]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedHall = val!),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      selectedEventType = "All Types";
                      selectedDateRange = "Any Date";
                      selectedHall = "All Venues";
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Reset"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  ),
                  child: const Text("Apply Filters"),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
              /// 🔹 Events List
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('status', isEqualTo: 'Approved')
                    .orderBy('startDateTime', descending: false)
                    .snapshots(),
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

                  var events = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return EventModel.fromMap(data, doc.id);
                  }).toList();

                  /// 🔹 Apply Search Filter
                  if (searchQuery.isNotEmpty) {
                    events = events.where((e) {
                      final q = searchQuery.toLowerCase();
                      return e.title.toLowerCase().contains(q) ||
                          e.description.toLowerCase().contains(q) ||
                          e.category.toLowerCase().contains(q);
                    }).toList();
                  }

                  /// 🔹 Apply Dropdown Filters
                  if (selectedEventType != "All Types") {
                    events = events.where((e) => e.category == selectedEventType).toList();
                  }
                  if (selectedHall != "All Venues") {
                    events = events.where((e) => e.venue == selectedHall).toList();
                  }
                  if (selectedDateRange != "Any Date") {
                    final now = DateTime.now();
                    if (selectedDateRange == "Today") {
                      events = events
                          .where((e) =>
                              e.startDateTime.year == now.year &&
                              e.startDateTime.month == now.month &&
                              e.startDateTime.day == now.day)
                          .toList();
                    } else if (selectedDateRange == "This Week") {
                      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                      final endOfWeek = startOfWeek.add(const Duration(days: 6));
                      events = events
                          .where((e) =>
                              e.startDateTime.isAfter(startOfWeek) &&
                              e.startDateTime.isBefore(endOfWeek))
                          .toList();
                    } else if (selectedDateRange == "This Month") {
                      events = events
                          .where((e) =>
                              e.startDateTime.year == now.year &&
                              e.startDateTime.month == now.month)
                          .toList();
                    }
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final event = events[index];
                          return _eventCard(event);
                        },
                        childCount: events.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.2,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: FooterPage()),
            ],
          ),

          /// 🔹 Header Top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeaderDesktop(
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(), title: 'Event Page',
             
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Event Card
  Widget _eventCard(EventModel event) {
    final now = DateTime.now();
    final daysLeft = event.startDateTime.difference(now).inDays;
    final daysLeftText = daysLeft <= 0 ? "Today" : "$daysLeft days left";

    final formattedDate = DateFormat("d MMM").format(event.startDateTime);
    
    final formattedTime =
        "${DateFormat("h:mm a").format(event.startDateTime)} - ${DateFormat("h:mm a").format(event.endDateTime)}";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailPage(eventId: event.id)),
        );
      },
      child: Container(
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
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: event.imageUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.broken_image, size: 48),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat("d").format(event.startDateTime),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat("MMM").format(event.startDateTime).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.category,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(6),
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(formattedTime, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4,),
                  Row(
  children: [
    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
    const SizedBox(width: 4),
    Text(
      formattedDate,
      style: const TextStyle(fontSize: 12, color: Colors.black87),
    ),
  ],
),
const SizedBox(height: 4),

                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.green),
                      const SizedBox(width: 4),
                      Text(event.venue, style: const TextStyle(fontSize: 12)),
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
