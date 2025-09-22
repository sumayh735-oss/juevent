import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ===== CONFIG =====
const String kEventsCollection = 'events';
const String kEventDateField = 'startDateTime';
const String kEventTitleField = 'title';
const String kVenueField = 'venue';
const String kStartTimeField = 'startTime'; // optional string
const String kEndTimeField = 'endTime'; // optional string

/// Somalia (Africa/Mogadishu) = UTC+3
const Duration kSomaliaTzOffset = Duration(hours: 3);

class TodayEventsPage extends StatefulWidget {
  const TodayEventsPage({super.key});
  @override
  State<TodayEventsPage> createState() => _TodayEventsPageState();
}

class _TodayEventsPageState extends State<TodayEventsPage> {
  final _searchCtrl = TextEditingController();

  DateTime get _somaliaStartOfTodayUtc {
    final nowUtc = DateTime.now().toUtc();
    final nowSom = nowUtc.add(kSomaliaTzOffset);
    final startSom = DateTime(nowSom.year, nowSom.month, nowSom.day);
    return startSom.subtract(kSomaliaTzOffset);
  }

  DateTime get _somaliaEndOfTodayUtc =>
      _somaliaStartOfTodayUtc.add(const Duration(days: 1));

  Query<Map<String, dynamic>> _todayQuerySomaliaUtc() {
    return FirebaseFirestore.instance
        .collection(kEventsCollection)
        .where(
          kEventDateField,
          isGreaterThanOrEqualTo: Timestamp.fromDate(_somaliaStartOfTodayUtc),
        )
        .where(
          kEventDateField,
          isLessThan: Timestamp.fromDate(_somaliaEndOfTodayUtc),
        )
        .orderBy(kEventDateField, descending: false)
        .limit(300)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );
  }

  Future<void> _confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onYes,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                child: const Text("No"),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              ElevatedButton(
                child: const Text("Yes"),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
    );

    if (result == true) {
      onYes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nowUtc = DateTime.now().toUtc();
    final nowSom = nowUtc.add(kSomaliaTzOffset);
    final dayLabel = DateFormat('EEEE, dd MMM yyyy').format(nowSom);
    final df = DateFormat('dd MMM yyyy, HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _todayQuerySomaliaUtc().snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? const [];

          final q = _searchCtrl.text.trim().toLowerCase();
          final list =
              docs.where((d) {
                final m = d.data();
                final title =
                    (m[kEventTitleField] ?? '').toString().toLowerCase();
                final venue = (m[kVenueField] ?? '').toString().toLowerCase();
                final id = d.id.toLowerCase();
                if (q.isEmpty) return true;
                return title.contains(q) || venue.contains(q) || id.contains(q);
              }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Today's Events",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                dayLabel,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              const SizedBox(height: 12),

              // Search
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search by title / venue...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (list.isEmpty)
                Center(
                  child: Column(
                    children: const [
                      SizedBox(height: 24),
                      Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No Events Today',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'There are no events scheduled for today.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children:
                      list.map((doc) {
                        final m = doc.data();
                        final title =
                            (m[kEventTitleField] ?? 'Untitled').toString();
                        final venue = (m[kVenueField] ?? '-').toString();
                        final status = (m['status'] ?? 'pending').toString();

                        final startTs = m[kEventDateField] as Timestamp?;
                        final start = startTs?.toDate();

                        String timeLabel() {
                          final s =
                              (m[kStartTimeField] ?? '').toString().trim();
                          final e = (m[kEndTimeField] ?? '').toString().trim();
                          if (s.isNotEmpty && e.isNotEmpty) return '$s – $e';
                          if (s.isNotEmpty) return s;
                          return start == null
                              ? '-'
                              : df.format(start.toLocal());
                        }

                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  (m['imageUrl'] ?? '').toString(),
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        height: 160,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title & Time
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.schedule, size: 16),
                                        const SizedBox(width: 4),
                                        Text(timeLabel()),
                                      ],
                                    ),
                                    const SizedBox(height: 6),

                                    Text(
                                      "📍 $venue",
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    const SizedBox(height: 6),

                                    Text(
                                      "Status: $status",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            status == 'approved'
                                                ? Colors.green
                                                : status == 'rejected'
                                                ? Colors.red
                                                : Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    Text(
                                      (m['description'] ?? '').toString(),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 12),

                                    // Action buttons with confirmation
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                status == 'approved'
                                                    ? Colors.grey
                                                    : Colors.green,
                                          ),
                                          onPressed:
                                              status == 'approved'
                                                  ? null // ✅ Disable haddii horey loo approve-gareeyay
                                                  : () {
                                                    FirebaseFirestore.instance
                                                        .collection(
                                                          kEventsCollection,
                                                        )
                                                        .doc(doc.id)
                                                        .update({
                                                          'status': 'approved',
                                                        });
                                                  },
                                          icon: const Icon(
                                            Icons.check,
                                            size: 18,
                                          ),
                                          label: Text(
                                            status == 'approved'
                                                ? "Approved"
                                                : "Approve",
                                          ),
                                        ),

                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () {
                                            _confirmAction(
                                              context: context,
                                              title: "Reject Event",
                                              message:
                                                  "Are you sure you want to reject this event?",
                                              onYes: () {
                                                FirebaseFirestore.instance
                                                    .collection(
                                                      kEventsCollection,
                                                    )
                                                    .doc(doc.id)
                                                    .update({
                                                      'status': 'rejected',
                                                    });
                                              },
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.close,
                                            size: 18,
                                          ),
                                          label: const Text("Reject"),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            _confirmAction(
                                              context: context,
                                              title: "Delete Event",
                                              message:
                                                  "Are you sure you want to delete this event?",
                                              onYes: () {
                                                FirebaseFirestore.instance
                                                    .collection(
                                                      kEventsCollection,
                                                    )
                                                    .doc(doc.id)
                                                    .delete();
                                              },
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 18,
                                          ),
                                          label: const Text("Delete"),
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
                ),
            ],
          );
        },
      ),
    );
  }
}
