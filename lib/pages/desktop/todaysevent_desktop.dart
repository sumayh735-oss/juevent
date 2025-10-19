import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ===== CONFIG =====
const String kEventsCollection = 'events';
const String kEventDateField = 'startDateTime';
const String kEventEndDateField = 'endDateTime'; // optional
const String kEventTitleField = 'title';
const String kVenueField = 'venue';
const String kStartTimeField = 'startTime'; // optional string
const String kEndTimeField = 'endTime';     // optional string

/// Somalia (Africa/Mogadishu) = UTC+3
const Duration kSomaliaTzOffset = Duration(hours: 3);

class AdminTodayPageDesktop extends StatelessWidget {
  const AdminTodayPageDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today'), backgroundColor: Colors.blue.shade900),
      body: const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: TodayseventDesktop(),
      ),
      backgroundColor: Colors.grey.shade50,
    );
  }
}

class TodayseventDesktop extends StatefulWidget {
  const TodayseventDesktop({super.key});
  @override
  State<TodayseventDesktop> createState() => _TodayseventDesktopState();
}

class _TodayseventDesktopState extends State<TodayseventDesktop> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ---------- Time helpers (Somalia/EAT always) ----------
  DateTime _toSomalia(DateTime dt) => dt.toUtc().add(kSomaliaTzOffset);

  DateTime get _somaliaStartOfTodayUtc {
    final nowUtc = DateTime.now().toUtc();
    final nowSom = nowUtc.add(kSomaliaTzOffset);
    final startSom = DateTime(nowSom.year, nowSom.month, nowSom.day);
    return startSom.subtract(kSomaliaTzOffset);
  }

  DateTime get _somaliaEndOfTodayUtc => _somaliaStartOfTodayUtc.add(const Duration(days: 1));

  String _fmtSomTime(DateTime dt) => DateFormat('h:mm a').format(_toSomalia(dt));
  String _fmtSomDate(DateTime dt) => DateFormat('dd MMM yyyy, HH:mm').format(_toSomalia(dt));
  String _todayLabel() => DateFormat('EEEE, dd MMM yyyy').format(_toSomalia(DateTime.now()));

  // ---------- Query ----------
  Query<Map<String, dynamic>> _todayQuerySomaliaUtc() {
    return FirebaseFirestore.instance
        .collection(kEventsCollection)
        .where(kEventDateField, isGreaterThanOrEqualTo: Timestamp.fromDate(_somaliaStartOfTodayUtc))
        .where(kEventDateField, isLessThan: Timestamp.fromDate(_somaliaEndOfTodayUtc))
        .orderBy(kEventDateField, descending: false)
        .limit(300)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );
  }

  // ---------- UI helpers ----------
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF16A34A);
      case 'rejected':
        return const Color(0xFFDC2626);
      case 'completed':
        return const Color(0xFF2563EB);
      default:
        return const Color(0xFFF59E0B); // pending/others
    }
  }

  String _timeLabel(Map<String, dynamic> m) {
    final startStr = (m[kStartTimeField] ?? '').toString().trim();
    final endStr   = (m[kEndTimeField] ?? '').toString().trim();
    final startTs  = m[kEventDateField] as Timestamp?;
    final endTs    = m[kEventEndDateField] as Timestamp?;

    if (startStr.isNotEmpty && endStr.isNotEmpty) return '$startStr – $endStr (EAT)';
    if (startStr.isNotEmpty) return '$startStr (EAT)';

    if (startTs != null) {
      final start = startTs.toDate();
      if (endTs != null) {
        final end = endTs.toDate();
        return '${_fmtSomTime(start)} – ${_fmtSomTime(end)} (EAT)';
      }
      return '${_fmtSomDate(start)} (EAT)';
    }
    return '-';
  }

  String _metaChip(Map<String, dynamic> m) {
    final nowSom = _toSomalia(DateTime.now());
    final startTs = m[kEventDateField] as Timestamp?;
    final endTs   = m[kEventEndDateField] as Timestamp?;
    DateTime? s, e;
    if (startTs != null) s = _toSomalia(startTs.toDate());
    if (endTs != null)   e = _toSomalia(endTs.toDate());

    if (s != null && e != null) {
      if (nowSom.isAfter(s) && nowSom.isBefore(e)) return 'Ongoing';
      if (nowSom.isBefore(s)) {
        final diff = s.difference(nowSom);
        return diff.inHours >= 1 ? 'Starts in ${diff.inHours}h' : 'Starts in ${diff.inMinutes}m';
      }
      return 'Ended';
    }
    if (s != null) {
      if (nowSom.isBefore(s)) {
        final diff = s.difference(nowSom);
        return diff.inHours >= 1 ? 'Starts in ${diff.inHours}h' : 'Starts in ${diff.inMinutes}m';
      }
      return 'Started';
    }
    return '';
  }

  Future<void> _confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onYes,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
        ],
      ),
    );
    if (result == true) onYes();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollCtrl,
      thumbVisibility: true,
      child: CustomScrollView(
        controller: _scrollCtrl,
        primary: false,
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Events", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(_todayLabel(), style: TextStyle(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 46,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search by title / venue…',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        suffixIcon: _searchCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Times shown in Somalia (EAT, UTC+3).', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),

          // Stream + Grid
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _todayQuerySomaliaUtc().snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const _SkeletonGrid();
              }

              final docs = snap.data?.docs ?? const [];
              final q = _searchCtrl.text.trim().toLowerCase();
              final list = docs.where((d) {
                final m = d.data();
                final title = (m[kEventTitleField] ?? '').toString().toLowerCase();
                final venue = (m[kVenueField] ?? '').toString().toLowerCase();
                final id = d.id.toLowerCase();
                if (q.isEmpty) return true;
                return title.contains(q) || venue.contains(q) || id.contains(q);
              }).toList();

              if (list.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No Events Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('There are no events scheduled for today.', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.crossAxisExtent;
                    int cols = 1;
                    if (w >= 1400) cols = 4;
                    else if (w >= 1100) cols = 3;
                    else if (w >= 800) cols = 2;

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 18,
                        mainAxisExtent: 388, // FIX: kordhiyay height-ka card-ka
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final doc = list[i];
                          final m = doc.data();
                          final title = (m[kEventTitleField] ?? 'Untitled').toString();
                          final venue = (m[kVenueField] ?? '-').toString();
                          final status = (m['status'] ?? 'pending').toString();

                          return _EventCard(
                            title: title,
                            venue: venue,
                            imageUrl: (m['imageUrl'] ?? '').toString(),
                            status: status,
                            statusColor: _statusColor(status),
                            timeLabel: _timeLabel(m),
                            metaLabel: _metaChip(m),
                            description: (m['description'] ?? '').toString(),
                            onApprove: status.toLowerCase() == 'approved'
                                ? null
                                : () {
                                    FirebaseFirestore.instance
                                        .collection(kEventsCollection)
                                        .doc(doc.id)
                                        .update({'status': 'approved'});
                                  },
                            onReject: () {
                              _confirmAction(
                                context: context,
                                title: 'Reject Event',
                                message: 'Are you sure you want to reject this event?',
                                onYes: () {
                                  FirebaseFirestore.instance
                                      .collection(kEventsCollection)
                                      .doc(doc.id)
                                      .update({'status': 'rejected'});
                                },
                              );
                            },
                            onDelete: () {
                              _confirmAction(
                                context: context,
                                title: 'Delete Event',
                                message: 'Are you sure you want to delete this event?',
                                onYes: () {
                                  FirebaseFirestore.instance
                                      .collection(kEventsCollection)
                                      .doc(doc.id)
                                      .delete();
                                },
                              );
                            },
                          );
                        },
                        childCount: list.length,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ---------- Pretty Card ----------
class _EventCard extends StatelessWidget {
  final String title;
  final String venue;
  final String imageUrl;
  final String status;
  final Color statusColor;
  final String timeLabel;
  final String metaLabel;
  final String description;
  final VoidCallback? onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;

  const _EventCard({
    required this.title,
    required this.venue,
    required this.imageUrl,
    required this.status,
    required this.statusColor,
    required this.timeLabel,
    required this.metaLabel,
    required this.description,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
  });

  ButtonStyle get _compactFilled => FilledButton.styleFrom(
        minimumSize: const Size(0, 36),                 // FIX: yaray
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // FIX
        visualDensity: VisualDensity.compact,            // FIX
      );

  ButtonStyle get _compactElevated => ElevatedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );

  ButtonStyle get _compactOutlined => OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 6))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image + overlay + chips
          Stack(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: imageUrl.isEmpty
                    ? Container(color: Colors.grey.shade200, alignment: Alignment.center, child: const Icon(Icons.image, size: 48, color: Colors.grey))
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, alignment: Alignment.center, child: const Icon(Icons.broken_image, size: 40)),
                      ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(.18), Colors.transparent, Colors.black.withOpacity(.28)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(999)),
                  child: Text(status.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ),
              if (metaLabel.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                    child: Text(metaLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.schedule, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(timeLabel, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.blueGrey),
                    const SizedBox(width: 6),
                    Expanded(child: Text(venue, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black87))),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.35),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Actions (compact)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(onApprove == null ? 'Approved' : 'Approve'),
                  style: _compactFilled.merge(
                    ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(onApprove == null ? Colors.grey : Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: _compactElevated.merge(
                    const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.red),
                      foregroundColor: WidgetStatePropertyAll(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: _compactOutlined,
                ),
                const Spacer(),
                const Text('EAT', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- Skeleton while loading ----------
class _SkeletonGrid extends StatelessWidget {
  const _SkeletonGrid();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.crossAxisExtent;
          int cols = 1;
          if (w >= 1400) cols = 4;
          else if (w >= 1100) cols = 3;
          else if (w >= 800) cols = 2;

          return SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              mainAxisExtent: 388, // FIX: la mid ah card-ka dhabta
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => const _SkeletonCard(),
              childCount: cols * 2,
            ),
          );
        },
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    Widget box({double h = 16, double w = double.infinity, double r = 8}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(r)),
        );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 12, offset: const Offset(0, 6))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          box(h: 160, r: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(w: 200),
                const SizedBox(height: 10),
                box(w: 160),
                const SizedBox(height: 10),
                box(),
                const SizedBox(height: 6),
                box(),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                box(h: 36, w: 110, r: 10),
                const SizedBox(width: 8),
                box(h: 36, w: 96, r: 10),
                const SizedBox(width: 8),
                box(h: 36, w: 96, r: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
