import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:withfbase/pages/desktop/home_header_desktop.dart';
import 'package:withfbase/pages/footer.dart';

class EventDetailPageDesktop extends StatelessWidget {
  final String eventId;

  const EventDetailPageDesktop({super.key, required this.eventId});

  static const List<String> staticTags = [
    'Research',
    'Innovation',
    'Academic',
    'Networking',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('events').doc(eventId).get(),
        builder: (context, snap) {
          // Header always visible
          final header = HomeHeaderDesktop(onMenuTap: () {}, title: 'Event Details Page ');

          if (snap.connectionState == ConnectionState.waiting) {
            return Column(
              children: [
                header,
                const Expanded(child: Center(child: CircularProgressIndicator())),
              ],
            );
          }

          if (!snap.hasData || !snap.data!.exists) {
            return Column(
              children: [
                header,
                const Expanded(child: Center(child: Text('Event not found.'))),
              ],
            );
          }

          final data = snap.data!.data()!;
          final title = (data['title'] ?? 'No Title').toString();
          final description = (data['description'] ?? '').toString();
          final venue = (data['venue'] ?? '').toString();
          final imageUrl = (data['imageUrl'] ?? '').toString();
          final category = (data['category'] ?? 'Category').toString();
          final capacity = (data['capacity']?.toString() ?? 'Unknown');
          final organizer = (data['organizer'] ?? data['organizerName'] ?? 'Organizer').toString();
          final email = (data['email'] ?? data['organizerEmail'] ?? 'info@example.com').toString();

          // Start/End datetimes (safe parse)
          DateTime? start = _toDate(data['startDateTime']);
          DateTime? end = _toDate(data['endDateTime']) ?? start;

          final dateLabel = (start == null)
              ? 'TBD'
              : (end != null && !_sameDay(start, end))
                  ? '${DateFormat.yMMMMd().format(start)} - ${DateFormat.yMMMMd().format(end)}'
                  : DateFormat.yMMMMd().format(start);

          final timeLabel = (start == null)
              ? ''
              : (end == null)
                  ? DateFormat('h:mm a').format(start)
                  : '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}';

          return SingleChildScrollView(
            child: Column(
              children: [
                header,

                // Centered content
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HERO
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 360,
                                  width: double.infinity,
                                  child: imageUrl.isEmpty
                                      ? Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(Icons.image, size: 64, color: Colors.grey),
                                          ),
                                        )
                                      : Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: Icon(Icons.broken_image, size: 64),
                                            ),
                                          ),
                                        ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(.25),
                                            Colors.transparent,
                                            Colors.black.withOpacity(.25),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Category
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.local_offer_rounded, color: Colors.white, size: 14),
                                        SizedBox(width: 6),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 12,
                                  left: 64,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      category,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                // Close
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: IconButton(
                                      tooltip: 'Close',
                                      icon: const Icon(Icons.close, color: Colors.black),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ),
                                // Title
                                Positioned(
                                  left: 16,
                                  bottom: 14,
                                  right: 16,
                                  child: Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 6,
                                          color: Colors.black54,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Info quick-row
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _InfoChip(
                                icon: Icons.calendar_today_rounded,
                                label: dateLabel,
                              ),
                              if (timeLabel.isNotEmpty)
                                _InfoChip(
                                  icon: Icons.access_time_rounded,
                                  label: timeLabel,
                                ),
                              _InfoChip(
                                icon: Icons.location_on_rounded,
                                label: venue.isEmpty ? 'Venue TBD' : venue,
                              ),
                              _InfoChip(
                                icon: Icons.people_alt_rounded,
                                label: 'Capacity: $capacity',
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // About
                          const Text(
                            'About This Event',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(color: Colors.grey.shade800, height: 1.45),
                          ),

                          const SizedBox(height: 16),

                          // Tags
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: staticTags
                                .map(
                                  (t) => Chip(
                                    avatar: const Icon(Icons.local_offer, size: 16, color: Colors.black54),
                                    label: Text(t),
                                    backgroundColor: Colors.grey.shade200,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),

                          const SizedBox(height: 24),

                          // Organizer
                          const Text(
                            'Organizer',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const CircleAvatar(child: Icon(Icons.person)),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(organizer),
                                  Text(email, style: const TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer
                const FooterPage(),
              ],
            ),
          );
        },
      ),
    );
  }

  static DateTime? _toDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
