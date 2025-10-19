import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/booking_form_desktop.dart';
import 'package:withfbase/pages/desktop/events_management_desktop.dart';

class HeroSectionDesktop extends StatelessWidget {
  final VoidCallback onExploreEvents;
  final VoidCallback onCheckAvailability;

  const HeroSectionDesktop({
    super.key,
    required this.onExploreEvents,
    required this.onCheckAvailability,
  });

  void _navigateToEvents(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => EventsManagementDesktop()),
    );
  }

  void _navigateToBooking(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => BookingFormDesktop()),
    );
  }

  void _navigateToVenues(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => EventsManagementDesktop()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
// Background image
SizedBox(
  height: 750,
  width: double.infinity,
  child: Image.asset(
    'assets/hero_bg.jpeg',
    fit: BoxFit.cover,
  ),
),

        // Overlay
        Container(
          height: 600,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Content
        Positioned(
          top: 150,
          left: 80,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "Jazeera University",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Find the Perfect Venue at\nJazeera University',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                'Browse, book, and manage events at our state-of-the-art halls and venues.',
                style: TextStyle(color: Colors.white70, fontSize: 22),
              ),
              const SizedBox(height: 40),

              // Buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: onExploreEvents,
                    icon: const Icon(Icons.search),
                    label: const Text("Explore Events"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 18),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: onCheckAvailability,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text("Check Availability"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // Info Cards Row
              Row(
                children: [
                  Expanded(
                    child: _infoCard(
                      Icons.search,
                      "Find Events",
                      "Discover upcoming academic and cultural events happening at our university.",
                      Colors.blue,
                      () => _navigateToEvents(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _infoCard(
                      Icons.place,
                      "Explore Venues",
                      "Browses our premium halls and spaces designed for every type of academic event.",
                      Colors.green,
                      () => _navigateToVenues(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _infoCard(
                      Icons.calendar_today,
                      "Book Instantly",
                      "Reserve halls and venues for your events with our easy-to-use booking system.",
                      Colors.blue,
                      () => _navigateToBooking(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCard(
      IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
