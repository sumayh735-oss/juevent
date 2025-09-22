import 'package:flutter/material.dart';
import 'package:withfbase/widgets/home_header.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EventDetailPage extends StatelessWidget {
  final String eventId;

  const EventDetailPage({super.key, required this.eventId});

  static const List<String> staticTags = [
    'Research',
    'Innovation',
    'Academic',
    'Networking',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            top: 150,
            child: FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('events')
                      .doc(eventId)
                      .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("Event not found."));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final title = data['title'] ?? 'No Title';
                final description = data['description'] ?? '';
                final venue = data['venue'] ?? '';
                final imageUrl = data['imageUrl'] ?? '';
                final time = data['time'] ?? '';
                final category = data['category'] ?? 'Category';
                final capacity = data['capacity']?.toString() ?? 'Unknown';
                final organizer = data['organizer'] ?? 'Organizer';
                final email = data['email'] ?? 'info@example.com';
                final tags = staticTags;
                final startDate = (data['startDateTime'] as Timestamp).toDate();
                final endDate =
                    (data['endDateTime'] as Timestamp?)?.toDate() ?? startDate;

                final formattedDate =
                    startDate == endDate
                        ? DateFormat.yMMMMd().format(startDate)
                        : '${DateFormat.yMMMMd().format(startDate)} - ${DateFormat.yMMMMd().format(endDate)}';

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🖼️ Header image with overlay and text
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            children: [
                              Image.network(
                                imageUrl,
                                height: 300,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned.fill(
                                bottom: 0,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black54,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // 🏷️ Category tag
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              // ❌ Close button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.black,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                              ),
                              // 🧾 Title
                              Positioned(
                                bottom: 12,
                                left: 16,
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4,
                                        color: Colors.black45,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ℹ️ Info section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18),
                                const SizedBox(width: 8),
                                Text(formattedDate),
                                const SizedBox(width: 16),
                                const Icon(Icons.access_time, size: 18),
                                const SizedBox(width: 4),
                                Text(time),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 18),
                                const SizedBox(width: 8),
                                Text(venue),
                                const SizedBox(width: 16),
                                const Icon(Icons.people, size: 18),
                                const SizedBox(width: 4),
                                Text("Capacity: $capacity seats"),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // 📘 About
                            const Text(
                              "About This Event",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 16),

                            // 🏷️ Tags (Static)
                            // 🏷️ Tags (Static)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  tags
                                      .map(
                                        (tag) => Chip(
                                          avatar: const Icon(
                                            Icons.local_offer,
                                            size: 16,
                                            color: Colors.black54,
                                          ),
                                          label: Text(tag),
                                          backgroundColor: Colors.grey.shade200,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),

                            const SizedBox(height: 24),

                            // 🧑‍💼 Organizer
                            const Text(
                              "Organizer",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const CircleAvatar(child: Text("F")),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(organizer),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // 📌 Footer
                      const FooterPage(),
                    ],
                  ),
                );
              },
            ),
          ),

          // 📍 Sticky header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeader(
              onMenuTap: () {
                ScaffoldMessenger.of(context);
              },
              title: '',
            ),
          ),
        ],
      ),
    );
  }
}
