import 'package:flutter/material.dart';
import 'package:withfbase/pages/main_page.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback onExploreEvents;
  final VoidCallback onCheckAvailability;

  const HeroSection({
    super.key,
    required this.onExploreEvents,
    required this.onCheckAvailability,
  });

  void _navigateToEvents(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainPage(initialIndex: 1)),
    );
  }

  void _navigateToBooking(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainPage(initialIndex: 3)),
    );
  }

  void _navigateToVenues(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainPage(initialIndex: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Stack(
      children: [
        // Background image
        SizedBox(
          height: isDesktop ? 600 : 690,
          width: double.infinity,
          child: Image.asset('assets/hero_bg.jpeg', fit: BoxFit.cover),
        ),
        // Gradient overlay
        Container(
          height: isDesktop ? 600 : 400,
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
          top: isDesktop ? 120 : 68,
          left: isDesktop ? 80 : 16,
          right: isDesktop ? 80 : 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Small Tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.lightBlueAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "Jazeera University",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Find the Perfect Venue at\nJazeera University',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 52 : 44,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Browse, book, and manage events at our state-of-the-art halls and venues.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isDesktop ? 24 : 20,
                ),
              ),
              const SizedBox(height: 40),

              // Buttons → Row on desktop, Column on mobile
              isDesktop
                  ? Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: onExploreEvents,
                        icon: const Icon(Icons.search),
                        label: const Text("Explore Events"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: onCheckAvailability,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text("Check Availability"),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  )
                  : Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: onExploreEvents,
                        icon: const Icon(Icons.search),
                        label: const Text("Explore Events"),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blueAccent,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: onCheckAvailability,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text("Check Availability"),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ],
                  ),

              const SizedBox(height: 60),

              // Bottom quick actions
              if (isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        "Browse our premium halls and spaces designed for every type of academic event.",
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
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToEvents(context),
                      child: _boxedActionButton(
                        Icons.event,
                        "Events",
                        Colors.blue,
                      ), // mobile card
                    ),
                    GestureDetector(
                      onTap: () => _navigateToVenues(context),
                      child: _boxedActionButton(
                        Icons.place,
                        "Venues",
                        Colors.green,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _navigateToBooking(context),
                      child: _boxedActionButton(
                        Icons.calendar_today,
                        "Book Now",
                        Colors.blue,
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
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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

  Widget _boxedActionButton(IconData icon, String label, Color bgColor) {
    return Container(
      width: 100,
      height: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x66AAAAAA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x66AAAAAA), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
