import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/add_venues_page.dart';

class AdminVenuesList extends StatelessWidget {
  final String searchQuery;

  const AdminVenuesList({super.key, required this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('venues').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Failed to load venues.');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;

        final filteredDocs =
            searchQuery.isEmpty
                ? allDocs
                : allDocs.where((doc) {
                  final name = (doc['name'] as String).toLowerCase();
                  final location =
                      (doc['location'] as String?)?.toLowerCase() ?? '';
                  return name.contains(searchQuery.toLowerCase()) ||
                      location.contains(searchQuery.toLowerCase());
                }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(child: Text('No matching venues found.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final venue = doc.data() as Map<String, dynamic>;
            final venueId = doc.id;

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
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
                            child: const Center(
                              child: Icon(Icons.broken_image),
                            ),
                          ),
                    ),
                  ),

                  // Info
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              venue['name'] ?? 'Untitled',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                venue['status'] ?? 'Available',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Location & Capacity
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              venue['location'] ?? '',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Capacity: ${venue['capacity'] ?? '-'}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Description
                        if (venue['description'] != null)
                          Text(
                            venue['description'],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Edit + Delete buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) =>
                                          AddVenuePage(venueId: venueId),
                                );
                              },
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text("Edit"),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text("Delete Venue"),
                                        content: const Text(
                                          "Are you sure you want to delete this venue?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('venues')
                                      .doc(venueId)
                                      .delete();
                                }
                              },
                              icon: const Icon(Icons.delete, size: 16),
                              label: const Text("Delete"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
