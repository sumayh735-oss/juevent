import 'package:flutter/material.dart';
import 'package:withfbase/pages/booking_form.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/pages/main_page.dart';
import 'package:withfbase/widgets/home_header.dart';
import 'package:withfbase/widgets/upcomingevent.dart';

class VenueDetailsPage extends StatelessWidget {
  final Map<String, dynamic> venue;

  const VenueDetailsPage({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          venue['imageUrl'] ?? '',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MainPage(initialIndex: 0),
                              ),
                              (route) => false,
                            );
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              venue['status'] == 'Available'
                                  ? Colors.green
                                  : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          venue['status'] ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(venue['location'] ?? ''),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Capacity: ${venue['capacity']} seats'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'About This Venue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    venue['description'] ??
                        'No description available for this venue.',
                    style: TextStyle(color: Colors.grey[700]),
                  ),

                  // Services Offered Section
                  if (venue['services'] != null &&
                      venue['services'] is List &&
                      (venue['services'] as List).isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Services Offered',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          (venue['services'] as List)
                              .map((service) => Chip(label: Text(service)))
                              .toList(),
                    ),
                  ],

                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookingForm(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.event_available),
                      label: const Text('Check Availability & Book'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Upcoming Events at this Venue',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const UpcomingEventsSection(),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const FooterPage(),
          ],
        ),
      ),
    );
  }
}
