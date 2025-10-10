import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/home_header_desktop.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/widgets/venue_detail_page.dart';

class VenuesPageDesktop extends StatefulWidget {
  const VenuesPageDesktop({super.key});

  @override
  State<VenuesPageDesktop> createState() => _VenuesPageDesktopState();
}

class _VenuesPageDesktopState extends State<VenuesPageDesktop> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String searchQuery = '';

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

              final venues = snapshot.data!.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .where((venue) => venue['name']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase()))
                  .toList();

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),

                  /// Title + Search
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 12),
                      child: Row(
                        children: [
                          const Text(
                            'University Venues',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 320,
                            child: TextField(
                              onChanged: (value) => setState(() => searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search venues...',
                                prefixIcon: const Icon(Icons.search),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0, horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// Venues Grid → full page layout
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _venueCard(context, venues[index]),
                        childCount: venues.length,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: 0.85, // 🔹 ka dhig card dheer yar
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: FooterPage()),
                ],
              );
            },
          ),

          /// Fixed Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeaderDesktop(
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(), title: 'Venues Page',
            ),
          ),
        ],
      ),
    );
  }

  /// Venue Card
  Widget _venueCard(BuildContext context, Map<String, dynamic> venue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Image
          if (venue['imageUrl'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                venue['imageUrl'],
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          /// Info Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Name + Status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (venue['status'] == 'Available')
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          venue['status'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  /// Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue['location'] ?? '',
                          style: const TextStyle(color: Colors.black87, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  /// Capacity
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("Capacity: ${venue['capacity']} seats",
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),

                  /// Description
                  Expanded(
                    child: Text(
                      venue['description'] ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ),

                  /// Footer Row
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Colors.green),
                      const SizedBox(width: 6),
                      const Text(
                        "Open for booking",
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
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
                            Text("Details"),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 14),
                          ],
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
    );
  }
}
