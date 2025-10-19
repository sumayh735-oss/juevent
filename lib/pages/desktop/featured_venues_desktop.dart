import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:withfbase/pages/desktop/venue_detail_page_desktop.dart';
import 'package:withfbase/services/responsive.dart';

class FeaturedVenuesDesktop extends StatelessWidget {
  const FeaturedVenuesDesktop({super.key});

  Future<List<Map<String, dynamic>>> fetchVenues() async {
    final snap = await FirebaseFirestore.instance.collection('venues').get();
    return snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchVenues(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _VenuesSkeleton();
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final venues = snap.data ?? [];
        if (venues.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("No venues found."),
          );
        }

        int cross = 1;
        if (Responsive.isTablet(context)) cross = 2;
        if (Responsive.isDesktop(context)) cross = 3;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: Responsive.isMobile(context) ? 0.95 : 1.25,
          ),
          itemCount: venues.length,
          itemBuilder: (_, i) => _VenueCard(venue: venues[i]),
        );
      },
    );
  }
}

class _VenueCard extends StatefulWidget {
  final Map<String, dynamic> venue;
  const _VenueCard({required this.venue});

  @override
  State<_VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends State<_VenueCard> {
  bool _hover = false;

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'available':
        return const Color(0xFF16A34A);
      case 'maintenance':
        return const Color(0xFFF59E0B);
      case 'unavailable':
      case 'reserved':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF22C55E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.venue;
    final imageUrl = (v['imageUrl'] ?? '').toString();
    final name = (v['name'] ?? '').toString();
    final loc = (v['location'] ?? '').toString();
    final cap = (v['capacity'] ?? '-').toString();
    final desc = (v['description'] ?? '').toString();
    final status = (v['status'] ?? 'Available').toString();

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..translate(0.0, _hover ? -3.0 : 0.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hover ? 0.10 : 0.06),
              blurRadius: _hover ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
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
              // Image + gradient + status badge
              Stack(
                children: [
                  SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: imageUrl.isEmpty
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.image, size: 42, color: Colors.grey)),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(child: Icon(Icons.broken_image, size: 42)),
                            ),
                          ),
                  ),
                  // top gradient
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x66000000), Color(0x00000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // status badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(status),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
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
                  // subtle name overlay (top-left)
                  Positioned(
                    left: 12,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.apartment_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Info
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location + Capacity row
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            loc,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD6E4FF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF1D4ED8)),
                              const SizedBox(width: 6),
                              Text('Capacity: $cap',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                    ),
                    const SizedBox(height: 12),

                    // Chips row (optional tags if present)
                    _AmenityChips(venue: v),

                    const SizedBox(height: 12),
                    // CTA row
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => VenueDetailPageDesktop(venue: v)),
                            );
                          },
                          icon: const Icon(Icons.info_outline_rounded),
                          label: const Text('Details'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => VenueDetailPageDesktop(venue: v)),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('View →'),
                        ),
                      ],
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
}

class _AmenityChips extends StatelessWidget {
  final Map<String, dynamic> venue;
  const _AmenityChips({required this.venue});

  @override
  Widget build(BuildContext context) {
    final List<String> tags = [];
    // auto-build small chips if fields exist
    if ((venue['projector'] ?? false) == true) tags.add('Projector');
    if ((venue['airCondition'] ?? venue['ac'] ?? false) == true) tags.add('A/C');
    if ((venue['wifi'] ?? false) == true) tags.add('Wi-Fi');
    if ((venue['parking'] ?? false) == true) tags.add('Parking');

    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags
          .map(
            (t) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                t,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Lightweight shimmer grid while loading (no extra packages)
class _VenuesSkeleton extends StatefulWidget {
  const _VenuesSkeleton();

  @override
  State<_VenuesSkeleton> createState() => _VenuesSkeletonState();
}

class _VenuesSkeletonState extends State<_VenuesSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  late final Animation<double> _a =
      Tween(begin: .45, end: .9).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int cross = 1;
    if (Responsive.isTablet(context)) cross = 2;
    if (Responsive.isDesktop(context)) cross = 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: Responsive.isMobile(context) ? 0.95 : 1.25,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => FadeTransition(
        opacity: _a,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(height: 170, decoration: BoxDecoration(color: Colors.blueGrey.shade200, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)))),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _skelLine(),
                      const SizedBox(height: 8),
                      _skelLine(width: 140),
                      const Spacer(),
                      Row(
                        children: [
                          _skelPill(),
                          const SizedBox(width: 8),
                          _skelPill(width: 70),
                          const Spacer(),
                          _skelPill(width: 80, height: 34),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skelLine({double width = 220, double height = 14}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.blueGrey.shade200, borderRadius: BorderRadius.circular(6)),
      );

  Widget _skelPill({double width = 90, double height = 28}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: Colors.blueGrey.shade200, borderRadius: BorderRadius.circular(30)),
      );
}
