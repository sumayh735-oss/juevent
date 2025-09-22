import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/add_venues_page.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/widgets/home_header.dart';

class AdminVenuesPage extends StatefulWidget {
  const AdminVenuesPage({super.key});

  @override
  State<AdminVenuesPage> createState() => _AdminVenuesPageState();
}

class _AdminVenuesPageState extends State<AdminVenuesPage> {
  String searchQuery = '';

  void _showAddVenueModal(BuildContext context, [String venueId = '']) {
    showDialog(
      context: context,
      builder: (context) => AddVenuePage(venueId: venueId),
    );
  }

  void _deleteVenue(String venueId) {
    FirebaseFirestore.instance.collection('venues').doc(venueId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Builder(
            builder:
                (context) => HomeHeader(
                  onMenuTap: () => Scaffold.of(context).openEndDrawer(),
                  title: '',
                ),
          ),

          // Body scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Venues Management",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value.trim().toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search venues...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddVenueModal(context),
                          icon: const Icon(Icons.add),
                          label: const Text('New Venue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Venues List
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('venues')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Error loading venues.');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        final filtered =
                            searchQuery.isEmpty
                                ? docs
                                : docs.where((doc) {
                                  final name =
                                      (doc['name'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  final location =
                                      (doc['location'] ?? '')
                                          .toString()
                                          .toLowerCase();
                                  return name.contains(searchQuery) ||
                                      location.contains(searchQuery);
                                }).toList();

                        if (filtered.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No matching venues found.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children:
                              filtered.map((venue) {
                                final data =
                                    venue.data() as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (data['imageUrl'] != null)
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(4),
                                              ),
                                          child: Image.network(
                                            data['imageUrl'],
                                            width: double.infinity,
                                            height: 180,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    data['name'] ?? '',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (data['status'] ==
                                                                'Available')
                                                            ? Colors
                                                                .green
                                                                .shade100
                                                            : Colors
                                                                .red
                                                                .shade100,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    data['status'] ?? 'Unknown',
                                                    style: TextStyle(
                                                      color:
                                                          (data['status'] ==
                                                                  'Available')
                                                              ? Colors.green
                                                              : Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              '📍 ${data['location'] ?? ''}',
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '🪑 Capacity: ${data['capacity'] ?? ''} seats',
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              data['description'] ?? '',
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                TextButton.icon(
                                                  onPressed:
                                                      () => _showAddVenueModal(
                                                        context,
                                                        venue.id,
                                                      ),
                                                  icon: const Icon(Icons.edit),
                                                  label: const Text("Edit"),
                                                ),
                                                TextButton.icon(
                                                  onPressed:
                                                      () => _deleteVenue(
                                                        venue.id,
                                                      ),
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                  ),
                                                  label: const Text(
                                                    "Delete",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
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
                              }).toList(),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                  const FooterPage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
