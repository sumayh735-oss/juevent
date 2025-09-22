import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:withfbase/widgets/venue_detail_page.dart';

class FeaturedVenues extends StatelessWidget {
  const FeaturedVenues({super.key});

  Future<List<Map<String, dynamic>>> fetchVenues() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('venues').get();
    return snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchVenues(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final venues = snapshot.data ?? [];

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: venues.length,
          itemBuilder: (context, index) {
            final venue = venues[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildVenueCard(context, venue),
            );
          },
        );
      },
    );
  }

  Widget _buildVenueCard(BuildContext context, Map<String, dynamic> venue) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.network(
                  venue['imageUrl'] ?? '',
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        height: 160,
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image)),
                      ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    venue['status'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venue['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              venue['location'] ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
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
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Capacity: ${venue['capacity'] ?? '-'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),

                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                VenueDetailsPage(venue: venue), // tab: Venues
                      ),
                    );
                  },

                  child: Row(
                    children: const [
                      Text(
                        'View Details',
                        style: TextStyle(color: Colors.blue),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 16, color: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
