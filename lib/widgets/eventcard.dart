import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ✅ Event Model
class EventModel {
  final String id;
  final String title;
  final String description;
  final String venue;
  final String category;
  final String imageUrl;
  final DateTime startDateTime;
  final DateTime endDateTime;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.category,
    required this.imageUrl,
    required this.startDateTime,
    required this.endDateTime,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      venue: map['venue'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      startDateTime: (map['startDateTime'] as Timestamp).toDate(),
      endDateTime: (map['endDateTime'] as Timestamp).toDate(),
    );
  }
}

// ✅ Card UI
class EventCard extends StatelessWidget {
  final String label;
  final String time;
  final String daysLeft;
  final String date;
  final String title;
  final String description;
  final String venue;
  final String image;

  const EventCard({
    super.key,
    required this.label,
    required this.time,
    required this.daysLeft,
    required this.date,
    required this.title,
    required this.description,
    required this.venue,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Top image + overlays
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: CachedNetworkImage(
                  imageUrl: image,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => const SizedBox(
                        height: 160,
                        child: Center(child: Icon(Icons.broken_image)),
                      ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        label == "Conference"
                            ? Colors.green
                            : label == "Seminar"
                            ? Colors.teal
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    "$daysLeft days left",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          // ✅ Content
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(venue, style: const TextStyle(color: Colors.grey)),
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

// ✅ Section with Grid layout
class UpcomingEventsSection extends StatelessWidget {
  const UpcomingEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
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

        final events =
            snapshot.data!.docs
                .map(
                  (doc) => EventModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ),
                )
                .where((event) => event.endDateTime.isAfter(DateTime.now()))
                .toList();

        if (events.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No upcoming events."),
          );
        }

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3, // ✅ 3 items per row
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.65,
          padding: const EdgeInsets.all(16),
          children:
              events.map((event) {
                final dateText = DateFormat(
                  "d MMM",
                ).format(event.startDateTime);
                final timeText =
                    "${DateFormat("h:mm a").format(event.startDateTime)} - ${DateFormat("h:mm a").format(event.endDateTime)}";
                final daysLeft =
                    event.startDateTime.difference(DateTime.now()).inDays;
                final daysLeftText = daysLeft <= 0 ? "0" : "$daysLeft";

                return EventCard(
                  label: event.category,
                  time: timeText,
                  daysLeft: daysLeftText,
                  date: dateText,
                  title: event.title,
                  description: event.description,
                  venue: event.venue,
                  image: event.imageUrl,
                );
              }).toList(),
        );
      },
    );
  }
}
