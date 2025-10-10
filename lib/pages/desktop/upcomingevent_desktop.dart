import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:withfbase/pages/event_model.dart';
import 'package:withfbase/widgets/event_detail_page.dart';
import 'package:withfbase/services/responsive.dart';

class UpcomingeventDesktop extends StatelessWidget {
  const UpcomingeventDesktop({super.key, required String category});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('status', isEqualTo: 'Approved')
          .orderBy('startDateTime')
          .snapshots(),
      builder: (context, snapshot) { 
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No upcoming events."),
          );
        }

        final allEvents = snapshot.data!.docs.map((doc) {
          return EventModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        final events = allEvents.where((event) {
          final now = DateTime.now();
          return event.endDateTime.isAfter(now);
        }).toList();

        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No upcoming events."),
          );
        }

        // responsive columns
        int crossAxisCount = 1;
        if (Responsive.isTablet(context)) {
          crossAxisCount = 2;
        } else if (Responsive.isDesktop(context)) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: Responsive.isMobile(context) ? 0.9 : 1.2,
          ),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(context, event);
          },
        );
      },
    );
  }

  Widget _buildEventCard(BuildContext context, EventModel event) {
  final dateDay = DateFormat("d").format(event.startDateTime);
  final dateMonth = DateFormat("MMM").format(event.startDateTime).toUpperCase();
  final timeRange =
      "${DateFormat("h:mm a").format(event.startDateTime)} - ${DateFormat("h:mm a").format(event.endDateTime)}";
  final daysLeft = event.startDateTime.difference(DateTime.now()).inDays;
  final daysLeftText = daysLeft <= 0 ? "Today" : "$daysLeft days left";

  return GestureDetector(
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
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top image (optional, haddii aad rabto background)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              event.imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date + Category
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(dateDay,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(dateMonth,
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
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
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(event.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                const SizedBox(height: 6),

                // Description
                Text(event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),

                // Time + Venue
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(timeRange, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(event.venue, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),

                // Organizer + Days left
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                   Text("By ${event.organizerName} (${event.organizerEmail})",
    style: const TextStyle(fontSize: 12, color: Colors.black54)),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(daysLeftText,
                          style: const TextStyle(fontSize: 12, color: Colors.blue)),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    ),
  );
}
}
