import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/widgets/home_header.dart';
import 'package:withfbase/widgets/venue_detail_page.dart';
import 'package:withfbase/widgets/notification_service.dart'; // Import NotificationService

class VenuesPage extends StatefulWidget {
  const VenuesPage({super.key});

  @override
  State<VenuesPage> createState() => _VenuesPageState();
}

class _VenuesPageState extends State<VenuesPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String searchQuery = '';
  bool showFilter = false;

  @override
  void initState() {
    super.initState();

    // Haddii aad rabto, halkan wali jadwal automatic ah waad ka saari kartaa
    // Future.delayed(Duration.zero, () async {
    //   final scheduledTime = DateTime.now().add(const Duration(minutes: 2));
    //   await NotificationService.scheduleNotification(
    //     id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    //     title: "Tijaabi Notification",
    //     body: "Notification-kan wuxuu imaanayaa 2 daqiiqo kadib",
    //     scheduledDate: scheduledTime,
    //   );
    // });
  }

  Stream<QuerySnapshot> getVenuesStream() {
    return FirebaseFirestore.instance.collection('venues').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: getVenuesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No venues found.'));
              }

              final venues =
                  snapshot.data!.docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .where(
                        (venue) => venue['name']
                            .toString()
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()),
                      )
                      .toList();

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 150)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'University Venues',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged:
                                (value) => setState(() => searchQuery = value),
                            decoration: InputDecoration(
                              hintText: 'Search venues...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _venueCard(context, venues[index]),
                        childCount: venues.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: FooterPage()),
                ],
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeader(
              showMenu: false,
              onMenuTap: () {},
              onFilterTap: () => setState(() => showFilter = !showFilter),
              title: '',
            ),
          ),

          // Halkan waxaan ku daray button-ka floating action button-ka
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () async {
                final scheduledTime = DateTime.now().add(
                  const Duration(seconds: 5),
                );
                await NotificationService.scheduleNotification(
                  id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  title: "Tijaabi Notification",
                  body: "Notification-kan wuxuu imaanayaa 5 ilbiriqsi kadib",
                  scheduledDate: scheduledTime,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification jadwaleeyay!')),
                );
              },
              tooltip: 'Tijaabi Notification',
              child: const Icon(Icons.notifications_active),
            ),
          ),
        ],
      ),
    );
  }

  Widget _venueCard(BuildContext context, Map<String, dynamic> venue) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (venue['imageUrl'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                venue['imageUrl'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        venue['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
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
                            (venue['status'] == 'Available')
                                ? Colors.green
                                : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        venue['status'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      venue['location'] ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('Capacity: ${venue['capacity']}'),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VenueDetailsPage(venue: venue),
                          ),
                        );
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View Details'),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward),
                        ],
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
  }
}
