import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:withfbase/pages/desktop/event_detail_page_desktop.dart';
import 'package:withfbase/pages/event_model.dart';
import 'package:withfbase/services/responsive.dart';

class UpcomingeventDesktop extends StatelessWidget {
  final String category;
  const UpcomingeventDesktop({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final eventsQuery = FirebaseFirestore.instance
        .collection('events')
        .where('status', isEqualTo: 'Approved')
        .orderBy('startDateTime');

    return StreamBuilder<QuerySnapshot>(
      stream: eventsQuery.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _EventsSkeleton();
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text("No upcoming events.")),
          );
        }

        // Firestore → EventModel
        final allEvents = snap.data!.docs.map((d) {
          return EventModel.fromMap(d.data() as Map<String, dynamic>, d.id);
        }).toList();

        // Filter: upcoming + category
        final now = DateTime.now();
        final filtered = allEvents.where((e) {
          final isUpcoming = e.endDateTime.isAfter(now);
          final matchCat = category == "All Events"
              ? true
              : e.category.trim().toLowerCase() == category.trim().toLowerCase();
          return isUpcoming && matchCat;
        }).toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No upcoming events found for "$category".',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          );
        }

        // Responsive columns
        int cross = 1;
        if (Responsive.isTablet(context)) cross = 2;
        if (Responsive.isDesktop(context)) cross = 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: Responsive.isMobile(context) ? 0.9 : 1.2,
          ),
          itemCount: filtered.length,
          itemBuilder: (_, i) => _EventCard(event: filtered[i]),
        );
      },
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

  String _window(DateTime start, DateTime end) {
    final sameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    final dayPart = DateFormat('EEE, MMM d').format(start);
    final startPart = DateFormat('h:mm a').format(start);
    final endPart = DateFormat('h:mm a').format(end);

    return sameDay ? '$dayPart • $startPart–$endPart' : '$dayPart • $startPart';
  }

  String _countdown(DateTime start) {
    final diff = start.difference(DateTime.now());
    if (diff.inMinutes <= 0) return 'Today';
    if (diff.inHours < 24) return '${diff.inHours}h left';
    final d = diff.inDays;
    return d == 1 ? '1 day left' : '$d days left';
  }

  Color _countdownColor(DateTime start) {
    final diff = start.difference(DateTime.now());
    if (diff.inMinutes <= 0) return const Color(0xFF2563EB);
    if (diff.inHours < 24) return const Color(0xFFF59E0B);
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final day = DateFormat('d').format(e.startDateTime);
    final mon = DateFormat('MMM').format(e.startDateTime).toUpperCase();
    final window = _window(e.startDateTime, e.endDateTime);
    final countdown = _countdown(e.startDateTime);
    final cdColor = _countdownColor(e.startDateTime);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        transform: Matrix4.identity()..translate(0.0, _hover ? -3.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hover ? .12 : .07),
              blurRadius: _hover ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EventDetailPageDesktop(eventId: e.id)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE + GRADIENT + CATEGORY + DATE PILL
              Stack(
                children: [
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: e.imageUrl.isEmpty
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                                child: Icon(Icons.image, color: Colors.grey, size: 42)),
                          )
                        : Image.network(
                            e.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                  child: Icon(Icons.broken_image, size: 42)),
                            ),
                          ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x66000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Category chip (top-right)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            e.category,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Date pill (top-left)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      width: 54,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(day,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                          Text(mon,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // CONTENT
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      e.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                    ),
                    const SizedBox(height: 10),

                    // Time window
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            window,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Venue
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF22C55E)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            e.venue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Organizer + Countdown
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'By ${e.organizerName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: cdColor.withOpacity(.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cdColor.withOpacity(.25)),
                          ),
                          child: Text(
                            countdown,
                            style: TextStyle(
                              fontSize: 12,
                              color: cdColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // CTA
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => EventDetailPageDesktop
                              (eventId: e.id)),
                        );
                      },
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('Details'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => EventDetailPageDesktop(eventId: e.id)),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('View →'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lightweight shimmer grid while loading (no packages)
class _EventsSkeleton extends StatefulWidget {
  const _EventsSkeleton();

  @override
  State<_EventsSkeleton> createState() => _EventsSkeletonState();
}

class _EventsSkeletonState extends State<_EventsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
        ..repeat(reverse: true);
  late final Animation<double> _a =
      Tween(begin: .45, end: .9).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int cross = 1;
    if (Responsive.isTablet(context)) cross = 2;
    if (Responsive.isDesktop(context)) cross = 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: Responsive.isMobile(context) ? 0.9 : 1.2,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => FadeTransition(
        opacity: _a,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade200,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _skelLine(),
                      const SizedBox(height: 8),
                      _skelLine(width: 160),
                      const SizedBox(height: 12),
                      _skelLine(width: 200, height: 12),
                      const SizedBox(height: 6),
                      _skelLine(width: 180, height: 12),
                      const Spacer(),
                      Row(
                        children: [
                          _skelPill(),
                          const Spacer(),
                          _skelPill(width: 90, height: 34),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skelLine({double width = 220, double height = 14}) => Container(
        width: width,
        height: height,
        decoration:
            BoxDecoration(color: Colors.blueGrey.shade200, borderRadius: BorderRadius.circular(6)),
      );

  Widget _skelPill({double width = 90, double height = 28}) => Container(
        width: width,
        height: height,
        decoration:
            BoxDecoration(color: Colors.blueGrey.shade200, borderRadius: BorderRadius.circular(30)),
      );
}
