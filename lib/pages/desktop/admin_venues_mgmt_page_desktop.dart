import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/add_venues_page_desktop.dart';
import 'package:withfbase/pages/desktop/admin_home_header_desktop.dart';
import 'package:withfbase/widgets/admin_venues_list.dart';

class AdminVenuesMgmtPageDesktop extends StatefulWidget {
  const AdminVenuesMgmtPageDesktop({super.key});

  @override
  State<AdminVenuesMgmtPageDesktop> createState() =>
      _AdminVenuesMgmtPageState();
}

class _AdminVenuesMgmtPageState extends State<AdminVenuesMgmtPageDesktop> {
  String searchQuery = '';
  String statusFilter = 'All'; // All, Available, Unavailable
  String sortBy = 'Recently Added'; // Recently Added, Name A–Z, Capacity

  void _showAddVenueModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddVenuesPageDesktop(venueId: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AdminHomeHeaderDesktop(
            onMenuTap: () => Scaffold.of(context).openEndDrawer(),
            title: 'Venues Management',
          ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- Top toolbar: Search + Filters + New Venue ----------
          Row(
  children: [
    // Search (qaab joogto ah, dherer yar si uusan u buuran)
    Expanded(
      flex: 6,
      child: SizedBox(
        height: 46,
        child: TextField(
          onChanged: (val) => setState(() => searchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search venues…',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ),
    ),
    const SizedBox(width: 12),

    // 🔧 Midig – xisaabi booska, ka dib ku qaybi labada pill si aysan u ka bixin
    Flexible(
      flex: 5,
      child: LayoutBuilder(
        builder: (context, box) {
          // 44 (refresh) + 10 (gap) + 140 (New Venue button min) + 12 (gap)
          final reserved = 44 + 10 + 140 + 12;
          final remain = (box.maxWidth - reserved).clamp(0, double.infinity);

          // Labada pill si isku mid ah uga qaado waxa haray; ha ka badin 200px,
          // hana ka yaraan 140px si ay u istaagaan xitaa marka boosku yaryahay
          final pillW = (remain / 2).clamp(140.0, 200.0);

          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: pillW,
                height: 46,
                child: _FilterPill(
                  value: statusFilter,
                  items: const ['All', 'Available', 'Unavailable'],
                  onChanged: (v) => setState(() => statusFilter = v),
                  icon: Icons.filter_alt_outlined, width: 30,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: pillW,
                height: 46,
                child: _FilterPill(
                  value: sortBy,
                  items: const ['Recently Added', 'Name A–Z', 'Capacity'],
                  onChanged: (v) => setState(() => sortBy = v),
                  icon: Icons.sort_rounded, width: 30,
                ),
              ),
              const SizedBox(width: 12),

              // Refresh – cabbir go’an si uusan boos badan u cunin
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton.filledTonal(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              const SizedBox(width: 10),

              // New Venue – ilaali min width oo ku deji dherer
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: () => _showAddVenueModal(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New Venue'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  ],
)
,            const SizedBox(height: 16),

            // -------- Quick stats from Firestore ----------
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('venues')
                  .snapshots(),
              builder: (context, snap) {
                int total = 0, available = 0, unavailable = 0;
                if (snap.hasData) {
                  total = snap.data!.docs.length;
                  for (final d in snap.data!.docs) {
                    final status =
                        (d.get('status') ?? '').toString().toLowerCase();
                    if (status == 'available') {
                      available++;
                    } else {
                      unavailable++;
                    }
                  }
                }

                return Row(
                  children: [
                    _StatCard(
                      title: 'Total Venues',
                      value: total.toString(),
                      icon: Icons.apartment_rounded,
                      color: Colors.indigo,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Available',
                      value: available.toString(),
                      icon: Icons.verified_rounded,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      title: 'Unavailable',
                      value: unavailable.toString(),
                      icon: Icons.block_rounded,
                      color: Colors.red,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // -------- Main card: the list --------
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // section header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        border: Border(
                          bottom:
                              BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Venues',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          // tiny legend that mirrors the status filter
                          _LegendDot(color: Colors.green, label: 'Available'),
                          const SizedBox(width: 10),
                          _LegendDot(color: Colors.red, label: 'Unavailable'),
                        ],
                      ),
                    ),

                    // list area
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(14),
                        ),
                        child: Container(
                          color: Colors.white,
                          // NB: AdminVenuesList waa inuu qudhiisa noqdaa scrollable;
                          // halkan waxaan siineynaa boos xadidan si uusan overflow u dhicin.
                          child: AdminVenuesList(
                            // Waxaa shaqeynaya raadinta; (filters kale
                            // haddii aad rabto, ku dar props cusub gudaha AdminVenuesList)
                            searchQuery: searchQuery.trim(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- UI Partials ----------------

class _FilterPill extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final IconData icon;

  const _FilterPill({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.icon, required int width,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: Icon(icon, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}


class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
      ],
    );
  }
}
