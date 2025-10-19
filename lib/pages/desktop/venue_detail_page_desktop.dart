import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/booking_form_desktop.dart';
import 'package:withfbase/pages/desktop/home_header_desktop.dart';
import 'package:withfbase/pages/desktop/upcoming_atthis_venue.dart';
import 'package:withfbase/pages/footer.dart';

class VenueDetailPageDesktop extends StatefulWidget {
  final Map<String, dynamic> venue;
  const VenueDetailPageDesktop({super.key, required this.venue});

  @override
  State<VenueDetailPageDesktop> createState() => _VenueDetailPageDesktopState();
}

class _VenueDetailPageDesktopState extends State<VenueDetailPageDesktop> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final v = widget.venue;

    final name = (v['name'] ?? '').toString();
    final status = (v['status'] ?? 'Available').toString();
    final location = (v['location'] ?? '').toString();
    final capacity = (v['capacity'] ?? '').toString();
    final imageUrl = (v['imageUrl'] ?? '').toString();
    final description =
        (v['description'] ?? 'No description available for this venue.').toString();
    final services = (v['services'] is List) ? (v['services'] as List) : const [];

    final isAvailable = status.toLowerCase() == 'available';
    final statusColor = isAvailable ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          /// MAIN SCROLL
          CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 120)), // header spacer

              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Breadcrumb / Back
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Back'),
                              ),
                              const Spacer(),
                            ],
                          ),

                          // Hero image + overlay
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 360,
                                  width: double.infinity,
                                  child: imageUrl.isEmpty
                                      ? Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(Icons.image, size: 72, color: Colors.grey),
                                          ),
                                        )
                                      : Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: Icon(Icons.broken_image, size: 64),
                                            ),
                                          ),
                                        ),
                                ),
                                // gradient overlay
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withOpacity(.25),
                                            Colors.transparent,
                                            Colors.black.withOpacity(.25),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // status pill
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.circle, size: 10, color: Colors.white),
                                        const SizedBox(width: 6),
                                        Text(
                                          status,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // close
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      tooltip: 'Close',
                                      icon: const Icon(Icons.close, color: Colors.white),
                                      onPressed: () => Navigator.of(context).maybePop(),
                                    ),
                                  ),
                                ),
                                // title over image
                                Positioned(
                                  left: 16,
                                  bottom: 16,
                                  right: 16,
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 6,
                                          color: Colors.black54,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Quick facts
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _FactCard(
                                icon: Icons.location_on_rounded,
                                label: 'Location',
                                value: location.isEmpty ? '-' : location,
                              ),
                              _FactCard(
                                icon: Icons.people_alt_rounded,
                                label: 'Capacity',
                                value: capacity.isEmpty ? '-' : '$capacity seats',
                              ),
                              _FactCard(
                                icon: Icons.event_available_rounded,
                                label: 'Status',
                                value: status,
                                valueColor: statusColor,
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // About
                          const Text(
                            'About This Venue',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            style: TextStyle(color: Colors.grey.shade800, height: 1.45),
                          ),

                          // Services
                          if (services.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            const Text(
                              'Services Offered',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            // single-line, scrollable chips so there is no overflow
                            SizedBox(
                              height: 34,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: services.length > 3 ? 3 : services.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  return Chip(
                                    label: Text(services[i].toString(),
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.grey.shade100,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    visualDensity: VisualDensity.compact,
                                  );
                                },
                              ),
                            ),
                            if (services.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Chip(
                                  label: Text('+${services.length - 3} more',
                                      style: const TextStyle(fontSize: 12)),
                                  backgroundColor: Colors.blue.shade50,
                                  side: BorderSide(color: Colors.blue.shade200),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],

                          const SizedBox(height: 26),

                          // CTA
                          Center(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const BookingFormDesktop(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.event_available_rounded),
                              label: const Text('Check Availability & Book'),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Upcoming events for this venue
                          const Text(
                            'Upcoming Events at this Venue',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          // DO NOT make this const: venueName is dynamic
                          UpcomingAtThisVenue(venueName: name),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: FooterPage()),
            ],
          ),

          /// STICKY HEADER
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeaderDesktop(
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              title: 'Venue Details',
            ),
          ),
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _FactCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: Colors.blue.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? Colors.black87,
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
