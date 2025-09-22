import 'package:flutter/material.dart';

class BookingPromptCard extends StatelessWidget {
  final VoidCallback onCheckAvailability;

  const BookingPromptCard({super.key, required this.onCheckAvailability});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003366), Color.fromARGB(255, 111, 172, 233)],

          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ready to Book Your Next Event?",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Check availability and reserve university venues for your academic, cultural, or professional events with our easy-to-use booking system.",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onCheckAvailability,
            icon: const Icon(Icons.calendar_today),
            label: const Text("Check Availability Now"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
