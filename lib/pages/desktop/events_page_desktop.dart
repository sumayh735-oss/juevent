import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:withfbase/pages/desktop/event_detail_page_desktop.dart';
import 'package:withfbase/pages/desktop/home_header_desktop.dart';
import 'package:withfbase/pages/event_model.dart';
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

  // Filters
  String selectedEventType = "All Types";
  String selectedDateRange = "Any Date";
  String selectedHall = "All Venues";

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int _gridColumnsForWidth(double w) {
    if (w >= 1360) return 4;
    if (w >= 1080) return 3;
    if (w >= 820) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 120)),

              /// Title + actions
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 4),
                  child: Row(
                    children: [
                      const Text(
                        "All Events",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.event_available_rounded, color: Colors.blueGrey),
                      const Spacer(),
                      // Filter toggle
                      Tooltip(
                        message: "Filters",
                        child: IconButton(
                          icon: Icon(
                            showFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
                            color: Colors.black87,
                          ),
                          onPressed: () => setState(() => showFilter = !showFilter),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Search
                      SizedBox(
                        width: 280,
                        child: TextField(
                          onChanged: (v) => setState(() => searchQuery = v),
                          decoration: InputDecoration(
                            hintText: "Search events…",
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: searchQuery.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: "Clear",
                                    icon: const Icon(Icons.close),
                                    onPressed: () => setState(() => searchQuery = ""),
                                  ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Refresh
                      ElevatedButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text("Refresh"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Filter panel (animated)
              SliverToBoxAdapter(
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 220),
                  crossFadeState:
                      showFilter ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Event type
                              Expanded(
                                child: _LabeledDropdown(
                                  label: "Event Type",
                                  value: selectedEventType,
                                  items: const [
                                    "All Types",
                                    "Conference",
                                    "Seminar",
                                    "Workshop",
                                    "Cultural",
                                    "Sports",
                                  ],
                                  onChanged: (v) => setState(() => selectedEventType = v),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Date range
                              Expanded(
                                child: _LabeledDropdown(
                                  label: "Date Range",
                                  value: selectedDateRange,
                                  items: const ["Any Date", "Today", "This Week", "This Month"],
                                  onChanged: (v) => setState(() => selectedDateRange = v),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Hall
                              Expanded(
                                child: _LabeledDropdown(
                                  label: "Hall",
                                  value: selectedHall,
                                  items: const ["All Venues", "Venue 1", "Venue 2", "Venue 3"],
                                  onChanged: (v) => setState(() => selectedHall = v),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 12),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text("Reset"),
                              ),
                              const SizedBox(width: 10),
                              FilledButton.icon(
                                onPressed: () => setState(() {}),
                                icon: const Icon(Icons.tune),
                                label: const Text("Apply Filters"),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// Events list
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('events')
                    .where('status', isEqualTo: 'Approved')
                    .orderBy('startDateTime', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 64),
                        child: Center(child: Text('Error loading events')),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _EmptyState(
                        title: "No events found",
                        subtitle: "Check back later or adjust your filters.",
                      ),
                    );
                  }

                  var events = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return EventModel.fromMap(data, doc.id);
                  }).toList();

                  // Text search
                  if (searchQuery.isNotEmpty) {
                    final q = searchQuery.toLowerCase();
                    events = events
                        .where((e) =>
                            e.title.toLowerCase().contains(q) ||
                            e.description.toLowerCase().contains(q) ||
                            e.category.toLowerCase().contains(q))
                        .toList();
                  }

                  // Filters
                  if (selectedEventType != "All Types") {
                    events =
                        events.where((e) => e.category == selectedEventType).toList();
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
                      final endOfWeek = startOfWeek.add(const Duration(days: 7));
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

                  if (events.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _EmptyState(
                        title: "No matching events",
                        subtitle:
                            "Try changing the filters or clearing your search.",
                      ),
                    );
                  }

                  final cols = _gridColumnsForWidth(width);

                  return SliverPadding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _EventCard(event: events[index]),
                        childCount: events.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.18,
                      ),
                    ),
                  );
                },
              ),

              const SliverToBoxAdapter(child: FooterPage()),
            ],
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeaderDesktop(
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              title: 'Event Page',
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventCard extends StatefulWidget {
  final EventModel event;
  const _EventCard({required this.event});

  @override
  State<_EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<_EventCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final now = DateTime.now();
    final daysLeft = e.startDateTime.difference(now).inDays;
    final daysLeftText = daysLeft <= 0 ? "Today" : "$daysLeft days left";
    final formattedDate = DateFormat("d MMM").format(e.startDateTime);
    final formattedTime =
        "${DateFormat("h:mm a").format(e.startDateTime)} - ${DateFormat("h:mm a").format(e.endDateTime)}";

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        transform: _hover
            ? (Matrix4.identity()..translate(0.0, -4.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hover ? 0.12 : 0.07),
              blurRadius: _hover ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EventDetailPageDesktop(eventId: e.id)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with gradient + badges
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: e.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, size: 40),
                    ),
                  ),
                  // gradient
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(.15),
                            Colors.transparent,
                            Colors.black.withOpacity(.28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // date badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      width: 56,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat("d").format(e.startDateTime),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            DateFormat("MMM").format(e.startDateTime).toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // category badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _chip(e.category, Colors.green),
                  ),
                  // time-left badge
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: _chip(daysLeftText, Colors.blue),
                  ),
                ],
              ),

              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      e.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    _metaRow(Icons.access_time, formattedTime),
                    const SizedBox(height: 4),
                    _metaRow(Icons.calendar_month, formattedDate),
                    const SizedBox(height: 4),
                    _metaRow(Icons.location_on, e.venue, iconColor: Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text, {Color iconColor = Colors.grey}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  const _EmptyState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
