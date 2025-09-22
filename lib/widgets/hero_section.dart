import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback onExploreEvents;
  final VoidCallback onCheckAvailability;

  const HeroSection({
    super.key,
    required this.onExploreEvents,
    required this.onCheckAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 690,
          width: double.infinity,
          child: Image.asset('assets/hero_bg.jpeg', fit: BoxFit.cover),
        ),
        Container(
          height: 400,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: 68,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(height: 16),
              const Text(
                'Find the Perfect Venue at\nJazeera University',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Browse, book, and manage events at our state-of-the-art halls and venues.',
                style: TextStyle(color: Colors.white70, fontSize: 22),
              ),
              const SizedBox(height: 50),
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
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onCheckAvailability,
                icon: const Icon(Icons.calendar_today),
                label: const Text("Check Availability"),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0x67AAAAAA),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 89),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      child: _boxedActionButton(
                        Icons.search,
                        "Find Events",
                        Colors.blue,
                      ),
                    ),
                    _boxedActionButton(Icons.place, "Venues", Colors.green),
                    GestureDetector(
                      child: _boxedActionButton(
                        Icons.event,
                        "Book Now",
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _boxedActionButton(IconData icon, String label, Color bgColor) {
    return Container(
      width: 150,
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
            child: Icon(icon, color: Colors.white, size: 24),
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
