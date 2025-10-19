import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/home_header_desktop.dart';
import 'package:withfbase/pages/desktop/venue_detail_page_desktop.dart';
import 'package:withfbase/pages/footer.dart';

class VenuesPageDesktop extends StatefulWidget {
  const VenuesPageDesktop({super.key});

  @override
  State<VenuesPageDesktop> createState() => _VenuesPageDesktopState();
}

class _VenuesPageDesktopState extends State<VenuesPageDesktop> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // UI state
  bool showFilter = false;
  String searchQuery = '';
  String selectedStatus = 'All'; // All / Available / Unavailable
  String selectedSort = 'Name A–Z'; // Name A–Z / Capacity / Recently Added
  double minCapacity = 0;

  // Responsive columns
  int _gridColumnsForWidth(double w) {
    if (w >= 1360) return 4;
    if (w >= 1080) return 3;
    if (w >= 820) return 2;
    return 1;
  }

  // Card height per breakpoint — slightly larger to eliminate edge overflows
  double _cardHeightForCols(int cols) {
    switch (cols) {
      case 4:
        return 380; // +20
      case 3:
        return 400; // +20
      case 2:
        return 430; // +20
      default:
        return 470; // +30
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cols = _gridColumnsForWidth(width);
    final cardExtent = _cardHeightForCols(cols);

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('venues').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Skeleton while loading
                return CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => const _VenueSkeletonCard(),
                          childCount: 8,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          mainAxisExtent: cardExtent,
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return CustomScrollView(
                  slivers: const [
                    SliverToBoxAdapter(child: SizedBox(height: 120)),
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text('No venues found.'),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(child: FooterPage()),
                  ],
                );
              }

              // Build a list of venues
              final rawVenues = snapshot.data!.docs
                  .map((doc) => (doc.data() as Map<String, dynamic>)..['id'] = doc.id)
                  .toList();

              // Services list (informational)
              final Set<String> allServices = {};
              for (final v in rawVenues) {
                final sv = v['services'];
                if (sv is List) {
                  for (final s in sv) {
                    final t = s?.toString().trim();
                    if (t != null && t.isNotEmpty) allServices.add(t);
                  }
                }
              }
              final servicesList = allServices.toList()..sort();

              // Apply filters (client-side)
              List<Map<String, dynamic>> venues = rawVenues.where((venue) {
                final name = (venue['name'] ?? '').toString();
                final status = (venue['status'] ?? '').toString();
                final cap = (venue['capacity'] ?? 0);
                final matchesSearch = name.toLowerCase().contains(searchQuery.toLowerCase());
                final matchesStatus = (selectedStatus == 'All')
                    ? true
                    : (selectedStatus == 'Available'
                        ? status.toLowerCase() == 'available'
                        : status.toLowerCase() != 'available');
                final matchesCapacity = (cap is num ? cap.toDouble() : 0) >= minCapacity;
                return matchesSearch && matchesStatus && matchesCapacity;
              }).toList();

              // Sort
              venues.sort((a, b) {
                if (selectedSort == 'Capacity') {
                  final ca = (a['capacity'] ?? 0) as num;
                  final cb = (b['capacity'] ?? 0) as num;
                  return cb.compareTo(ca); // high → low
                } else if (selectedSort == 'Recently Added') {
                  final ta = a['createdAt'];
                  final tb = b['createdAt'];
                  DateTime da = ta is Timestamp ? ta.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  DateTime db = tb is Timestamp ? tb.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
                  return db.compareTo(da); // newest first
                } else {
                  final na = (a['name'] ?? '').toString().toLowerCase();
                  final nb = (b['name'] ?? '').toString().toLowerCase();
                  return na.compareTo(nb);
                }
              });

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),

                  // Title + Search + Sort + Filter
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(80, 12, 80, 8),
                      child: Row(
                        children: [
                          const Text(
                            'University Venues',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_city_rounded, color: Colors.blueGrey),
                          const Spacer(),

                          // Sort
                          SizedBox(
                            width: 210,
                            child: DropdownButtonFormField<String>(
                              value: selectedSort,
                              items: const ['Name A–Z', 'Capacity', 'Recently Added']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                              onChanged: (v) => setState(() => selectedSort = v ?? selectedSort),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Filter toggle
                          Tooltip(
                            message: 'Filters',
                            child: IconButton(
                              icon: Icon(
                                showFilter ? Icons.filter_alt : Icons.filter_alt_outlined,
                                color: Colors.black87,
                              ),
                              onPressed: () => setState(() => showFilter = !showFilter),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Search
                          SizedBox(
                            width: 320,
                            child: TextField(
                              onChanged: (value) => setState(() => searchQuery = value),
                              decoration: InputDecoration(
                                hintText: 'Search venues…',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: 'Clear',
                                        icon: const Icon(Icons.close),
                                        onPressed: () => setState(() => searchQuery = ''),
                                      ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Filter Panel
                  SliverToBoxAdapter(
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState:
                          showFilter ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.fromLTRB(80, 6, 80, 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x11000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status + Min Capacity
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Status',
                                            style: TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        DropdownButtonFormField<String>(
                                          value: selectedStatus,
                                          items: const ['All', 'Available', 'Unavailable']
                                              .map((e) =>
                                                  DropdownMenuItem(value: e, child: Text(e)))
                                              .toList(),
                                          onChanged: (v) =>
                                              setState(() => selectedStatus = v ?? 'All'),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                            filled: true,
                                            fillColor: Colors.grey.shade100,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: BorderSide(color: Colors.grey.shade300),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Min Capacity',
                                            style: TextStyle(fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Slider(
                                                value: minCapacity,
                                                min: 0,
                                                max: 1000,
                                                divisions: 20,
                                                label: minCapacity.round().toString(),
                                                onChanged: (v) => setState(() => minCapacity = v),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 70,
                                              child: Text(
                                                '${minCapacity.round()}+',
                                                textAlign: TextAlign.end,
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              if (servicesList.isNotEmpty) ...[
                                const Text('Services (available in data)',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: servicesList
                                      .map((s) => Chip(
                                            label: Text(s),
                                            backgroundColor: Colors.grey.shade100,
                                            side: BorderSide(color: Colors.grey.shade300),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedStatus = 'All';
                                        minCapacity = 0;
                                      });
                                    },
                                    child: const Text('Reset'),
                                  ),
                                  const SizedBox(width: 10),
                                  FilledButton.icon(
                                    onPressed: () => setState(() {}),
                                    icon: const Icon(Icons.tune),
                                    label: const Text('Apply'),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Venues Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                    sliver: venues.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No venues match your filters.'),
                              ),
                            ),
                          )
                        : SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _VenueCard(venue: venues[index]),
                              childCount: venues.length,
                            ),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              mainAxisSpacing: 24,
                              crossAxisSpacing: 24,
                              mainAxisExtent: cardExtent,
                            ),
                          ),
                  ),

                  const SliverToBoxAdapter(child: FooterPage()),
                ],
              );
            },
          ),

          // Sticky Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeaderDesktop(
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              title: 'Venues Page',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- CARDS ----------------

class _VenueCard extends StatefulWidget {
  final Map<String, dynamic> venue;
  const _VenueCard({required this.venue});

  @override
  State<_VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends State<_VenueCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.venue;
    final name = (v['name'] ?? '').toString();
    final imageUrl = (v['imageUrl'] ?? '').toString();
    final status = (v['status'] ?? 'Unknown').toString();
    final isAvailable = status.toLowerCase() == 'available';
    final location = (v['location'] ?? '').toString();
    final capacity = (v['capacity'] ?? '').toString();
    final description = (v['description'] ?? '').toString();
    final services = (v['services'] is List)
        ? (v['services'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        transform: _hover ? (Matrix4.identity()..translate(0.0, -4.0)) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hover ? 0.12 : 0.07),
              blurRadius: _hover ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => VenueDetailPageDesktop(venue: v)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + overlay + status
              Stack(
                children: [
                  SizedBox(
                    height: 136, // 140 -> 136 to free a few pixels
                    width: double.infinity,
                    child: imageUrl.isEmpty
                        ? Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: const Icon(Icons.image, size: 48, color: Colors.grey),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(.15),
                            Colors.transparent,
                            Colors.black.withOpacity(.28),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, size: 10, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Body (Expanded si ay ula qabsato dhererka card-ka)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      // Location
                      _metaRow(Icons.location_on_rounded, location),
                      const SizedBox(height: 4),
                      // Capacity
                      _metaRow(Icons.people_alt_rounded, 'Capacity: $capacity seats'),
                      const SizedBox(height: 8),

                      // Description (max 2 lines)
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 10),

                      // Services — single-row, fixed height
                      if (services.isNotEmpty)
                        SizedBox(
                          height: 32,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            itemCount: services.length > 2 ? 3 : services.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                            itemBuilder: (context, i) {
                              if (i < 2 && i < services.length) {
                                return Chip(
                                  label: Text(services[i], style: const TextStyle(fontSize: 12)),
                                  backgroundColor: Colors.grey.shade100,
                                  side: BorderSide(color: Colors.grey.shade300),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                );
                              }
                              final extra = services.length - 2;
                              return Chip(
                                label: Text('+$extra more', style: const TextStyle(fontSize: 12)),
                                backgroundColor: Colors.blue.shade50,
                                side: BorderSide(color: Colors.blue.shade200),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Footer row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded,
                        size: 16, color: isAvailable ? Colors.green : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      isAvailable ? 'Open for booking' : 'Closed',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAvailable ? Colors.green : Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => VenueDetailPageDesktop(venue: v)),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_ios, size: 14),
                      label: const Text('Details'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}

// Skeleton card while loading
class _VenueSkeletonCard extends StatelessWidget {
  const _VenueSkeletonCard();

  @override
  Widget build(BuildContext context) {
    Widget box({double h = 16, double w = double.infinity, double r = 8}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(r),
          ),
        );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          box(h: 136, r: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(w: 180),
                const SizedBox(height: 10),
                box(w: 220),
                const SizedBox(height: 6),
                box(w: 160),
                const SizedBox(height: 10),
                box(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
