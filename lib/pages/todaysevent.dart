// -----------------------------------------------------------------------------
// todaysevent.dart
// Beautiful, Live-Updating Today's Events Page (Somalia Time)
// ----------------------------------------------------------------------------- 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:withfbase/pages/desktop/admin_events_mgmt_desktop.dart';

const String kEventsCollection = 'events';
const Duration kSomaliaTzOffset = Duration(hours: 3);

class TodayEventsPage extends StatefulWidget {
  const TodayEventsPage({super.key});

  @override
  State<TodayEventsPage> createState() => _TodayEventsPageState();
}

class _TodayEventsPageState extends State<TodayEventsPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  DateTime get _somaliaStartUtc {
    final nowUtc = DateTime.now().toUtc();
    final nowSom = nowUtc.add(kSomaliaTzOffset);
    final startSom = DateTime(nowSom.year, nowSom.month, nowSom.day);
    return startSom.subtract(kSomaliaTzOffset);
  }

  DateTime get _somaliaEndUtc => _somaliaStartUtc.add(const Duration(days: 1));

  Query<Map<String, dynamic>> _todayQuery() {
    return FirebaseFirestore.instance
        .collection(kEventsCollection)
        .where('startDateTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_somaliaStartUtc))
        .where('startDateTime',
            isLessThan: Timestamp.fromDate(_somaliaEndUtc))
        .orderBy('startDateTime', descending: false);
  }

  Future<void> _updateStatus(
      String docId, String status, BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection(kEventsCollection)
          .doc(docId)
          .update({'status': status});
      if (!mounted) return;

      // Snackbar success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Event marked as $status."),
          backgroundColor:
              status == 'approved' ? Colors.green : Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to EventsManagementPage after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminEventsMgmtDesktop()),
      );
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final nowSom = DateTime.now().toUtc().add(kSomaliaTzOffset);
    final dateLabel = DateFormat('EEEE, dd MMM yyyy').format(nowSom);
    final df = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _todayQuery().snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data?.docs ?? [];
            final query = _searchCtrl.text.trim().toLowerCase();
            final list = docs.where((d) {
              final m = d.data();
              final title = (m['title'] ?? '').toString().toLowerCase();
              final venue = (m['venue'] ?? '').toString().toLowerCase();
              return query.isEmpty ||
                  title.contains(query) ||
                  venue.contains(query);
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search by title or venue...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: list.isEmpty
                      ? const Center(
                          child: Text(
                            "No events scheduled for today.",
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                        )
                      : ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, i) {
                            final doc = list[i];
                            final m = doc.data();
                            final title =
                                (m['title'] ?? 'Untitled Event').toString();
                            final venue = (m['venue'] ?? '-').toString();
                            final desc =
                                (m['description'] ?? '').toString().trim();
                            final status =
                                (m['status'] ?? 'pending').toString();

                            final ts = m['startDateTime'] as Timestamp?;
                            final date = ts?.toDate();
                            final formatted =
                                date == null ? '-' : df.format(date.toLocal());

                            Color badgeColor;
                            if (status == 'approved') {
                              badgeColor = Colors.green;
                            } else if (status == 'rejected') {
                              badgeColor = Colors.redAccent;
                            } else {
                              badgeColor = Colors.orange;
                            }

                            final image = (m['imageUrl'] ?? '').toString();

                            return Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.only(bottom: 18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(16)),
                                    child: image.isNotEmpty
                                        ? Image.network(
                                            image,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => Container(
                                              height: 180,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                  Icons.broken_image,
                                                  size: 48,
                                                  color: Colors.grey),
                                            ),
                                          )
                                        : Container(
                                            height: 180,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(Icons.image,
                                                  size: 60, color: Colors.grey),
                                            ),
                                          ),
                                  ),

                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
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
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color:
                                                    badgeColor.withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                status.toUpperCase(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: badgeColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today,
                                                size: 16,
                                                color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(formatted),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text("📍 $venue",
                                            style: const TextStyle(
                                                color: Colors.black54)),
                                        const SizedBox(height: 8),
                                        if (desc.isNotEmpty)
                                          Text(
                                            desc,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                color: Colors.black54),
                                          ),
                                        const SizedBox(height: 12),

                                        // Action Buttons
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton.icon(
                                              style:
                                                  ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    status == 'approved'
                                                        ? Colors.grey
                                                        : Colors.green,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 10),
                                              ),
                                              icon: const Icon(Icons.check,
                                                  size: 18),
                                              label: Text(
                                                status == 'approved'
                                                    ? "Approved"
                                                    : "Approve",
                                              ),
                                              onPressed: status == 'approved' ||
                                                      status == 'rejected'
                                                  ? null
                                                  : () => _updateStatus(
                                                      doc.id,
                                                      'approved',
                                                      context),
                                            ),
                                            ElevatedButton.icon(
                                              style:
                                                  ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 10),
                                              ),
                                              icon: const Icon(Icons.close,
                                                  size: 18),
                                              label: const Text("Reject"),
                                              onPressed: status ==
                                                          'rejected' ||
                                                      status == 'approved'
                                                  ? null
                                                  : () => _updateStatus(
                                                      doc.id,
                                                      'rejected',
                                                      context),
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
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
