import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UpcomingAtThisVenue extends StatelessWidget {
  final String venueName;     // ama u baddel venueId haddii aad doorbideyso
  final int limit;

  const UpcomingAtThisVenue({
    super.key,
    required this.venueName,
    this.limit = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (venueName.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final q = FirebaseFirestore.instance
        .collection('events')
        .where('status', isEqualTo: 'Approved')
        .where('venue', isEqualTo: venueName)
        .orderBy('startDateTime'); // <-- waxay u baahan kartaa INDEX (hoos eeg)

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: q.limit(limit).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Text('Error: ${snap.error}');
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Text('No upcoming events for this venue.');
        }

        // sifeyn: kaliya kuwa aan dhammaan (end > now)
        final now = DateTime.now();
        final docs = snap.data!.docs.where((d) {
          final end = _toDate(d.data()['endDateTime']);
          return end == null || end.isAfter(now);
        }).toList();

        if (docs.isEmpty) {
          return const Text('No upcoming events for this venue.');
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 420, // 1–3 columns iyadoo ku xiran ballaca
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            mainAxisExtent: 300,     // 👉 dherer card go’an si uusan u overflow-garin
          ),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data();
            final title     = (d['title'] ?? 'Untitled').toString();
            final category  = (d['category'] ?? 'General').toString();
            final venue     = (d['venue'] ?? '').toString();
            final imageUrl  = (d['imageUrl'] ?? '').toString();
            final desc      = (d['description'] ?? '').toString();
            final start     = _toDate(d['startDateTime']);
            final end       = _toDate(d['endDateTime']);

            final timeLabel = (start == null)
                ? ''
                : (end == null)
                    ? DateFormat('EEE, MMM d • h:mm a').format(start)
                    : '${DateFormat('EEE, MMM d • h:mm a').format(start)} – ${DateFormat('h:mm a').format(end)}';

            return _EventCard(
              imageUrl: imageUrl,
              category: category,
              title: title,
              description: desc,
              timeLabel: timeLabel,
              venue: venue,
            );
          },
        );
      },
    );
  }

  static DateTime? _toDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}

class _EventCard extends StatelessWidget {
  final String imageUrl, category, title, description, timeLabel, venue;

  const _EventCard({
    required this.imageUrl,
    required this.category,
    required this.title,
    required this.description,
    required this.timeLabel,
    required this.venue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: imageUrl.isEmpty
                  ? Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.broken_image, size: 40)),
                      ),
                    ),
            ),
          ),

          // body
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),

                  // description limited
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const Spacer(),

                  // time
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          timeLabel,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // venue
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          venue,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
