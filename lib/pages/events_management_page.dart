// -----------------------------------------------------------------------------
// events_management_page.dart
// Mobile-friendly Admin Events Management
// - Shows Reason + Cancelled By/Email/At (for Canceled). Reason for Rejected.
// - NO Delete anywhere
// -----------------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:withfbase/pages/add_event_page.dart';

// ============================= SMTP HELPER ===================================
// !! TALO AMNI: Ha ku darin password code-ka; isticmaal .env/Remote Config/Functions
Future<void> sendEmail({
  required String recipientEmail,
  required String subject,
  required String body,
}) async {
  const String username = 'youremail@gmail.com'; // ← beddel
  const String password = 'your-app-password-halkan'; // ← beddel App Password

  if (recipientEmail.isEmpty) return;

  final smtpServer = gmail(username, password);
  final message = Message()
    ..from = Address(username, 'Jazeera University Admin')
    ..recipients.add(recipientEmail)
    ..subject = subject
    ..text = body;

  try {
    await send(message, smtpServer);
    debugPrint('✅ Email sent to $recipientEmail');
  } catch (e) {
    debugPrint('❌ Email error: $e');
  }
}

// ============================= MAIN PAGE =====================================
class EventsManagementPage extends StatefulWidget {
  const EventsManagementPage({super.key});

  @override
  State<EventsManagementPage> createState() => _EventsManagementPageState();
}

enum EventStatusFilter { all, pending, approved, completed, rejected, canceled, expired }

class _EventsManagementPageState extends State<EventsManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  EventStatusFilter _filter = EventStatusFilter.all;

  @override
void initState() {
  super.initState();

  // Xir listner-ka search
  _searchController.addListener(() => setState(() => _searchTerm = _searchController.text.trim().toLowerCase()));

  // ✅ Dibu dhigid 1 ilbiriqsi kadib si UI uu u dhismo marka hore
  Future.delayed(const Duration(seconds: 1), () async {
    await _expireApprovedIfPast();
    await _sendRemindersForApproved();
  });
}

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------- Utils ----------------------------------------
  String _normalizeStatus(dynamic raw) {
    final v = (raw ?? '').toString().toLowerCase();
    switch (v) {
      case 'approved':
        return 'Approved';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'canceled':
      case 'cancelled':
        return 'Canceled';
      case 'expired':
        return 'Expired';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  bool _matchesSearch(Map<String, dynamic> m) {
    final hay = '${m['title'] ?? ''} ${m['organizerName'] ?? ''} ${m['venue'] ?? ''} ${m['companyName'] ?? ''}'
        .toString()
        .toLowerCase();
    return _searchTerm.isEmpty ? true : hay.contains(_searchTerm);
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'canceled':
        return Colors.grey;
      case 'expired':
        return Colors.black54;
      default:
        return Colors.orange; // pending
    }
  }

  // ---------------------------- Stream by Filter -----------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> _eventsStream() {
    final coll = FirebaseFirestore.instance.collection('events');
    switch (_filter) {
      case EventStatusFilter.pending:
        return coll.where('status', whereIn: ['Pending', 'pending']).orderBy('createdAt', descending: true).snapshots();
      case EventStatusFilter.approved:
        return coll.where('status', whereIn: ['Approved', 'approved']).orderBy('startDateTime').snapshots();
      case EventStatusFilter.completed:
        return coll.where('status', whereIn: ['Completed', 'completed']).orderBy('startDateTime').snapshots();
      case EventStatusFilter.rejected:
        return coll.where('status', whereIn: ['Rejected', 'rejected']).orderBy('createdAt', descending: true).snapshots();
      case EventStatusFilter.canceled:
        return coll
            .where('status', whereIn: ['Canceled', 'canceled', 'cancelled'])
            .orderBy('createdAt', descending: true)
            .snapshots();
      case EventStatusFilter.expired:
        return coll.where('status', whereIn: ['Expired', 'expired']).orderBy('createdAt', descending: true).snapshots();
      case EventStatusFilter.all:
      default:
        return coll.orderBy('startDateTime').snapshots();
    }
  }

  // ---------------------------- Actions --------------------------------------
  Future<void> _approveEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final m = snap.data();
    if (m == null) return;

    await snap.reference.update({
      'status': 'Approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    await sendEmail(
      recipientEmail: (m['organizerEmail'] ?? '').toString(),
      subject: 'Event Approved',
      body: 'Dear organizer,\n\nYour event "${m['title']}" has been approved.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event Approved')));
    }
  }

  Future<void> _completeEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final m = snap.data();
    if (m == null) return;

    await snap.reference.update({
      'status': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
      'completedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    await sendEmail(
      recipientEmail: (m['organizerEmail'] ?? '').toString(),
      subject: 'Event Completed',
      body: 'Dear organizer,\n\nYour event "${m['title']}" is now marked as Completed.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event Completed')));
    }
  }

  Future<void> _rejectEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Reason'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(hintText: 'Enter reason...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()), child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;

    final m = snap.data();
    if (m == null) return;

    await snap.reference.update({
      'status': 'Rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedReason': reason,
    });

    await sendEmail(
      recipientEmail: (m['organizerEmail'] ?? '').toString(),
      subject: 'Event Rejected',
      body: 'Dear organizer,\n\nYour event "${m['title']}" was rejected.\nReason: $reason',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event Rejected')));
    }
  }

  // Revert *any* to Pending (Approved/Rejected/Canceled/Completed/Expired)
  Future<void> _revertToPending(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final m = snap.data();
    await snap.reference.update({'status': 'Pending'});

    await sendEmail(
      recipientEmail: (m?['organizerEmail'] ?? '').toString(),
      subject: 'Event Reverted to Pending',
      body: 'Dear organizer,\n\nYour event "${m?['title']}" has been reverted to Pending by the admin.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reverted to Pending')));
    }
  }

  // -------------------------- Housekeeping -----------------------------------
  Future<void> _expireApprovedIfPast() async {
    final now = DateTime.now();
    try {
      final qs = await FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'Approved').get();
      for (final d in qs.docs) {
        final m = d.data();
        final end = (m['endDateTime'] as Timestamp?)?.toDate();
        if (end != null && end.isBefore(now)) {
          await d.reference.update({'status': 'Expired'});
        }
      }
    } catch (e) {
      debugPrint('Expire check error: $e');
    }
  }

  Future<void> _sendRemindersForApproved() async {
    final qs = await FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'Approved').get();
    for (final d in qs.docs) {
      final m = d.data();
      DateTime? start;
      final raw = m['startDateTime'];
      if (raw is Timestamp) start = raw.toDate();
      if (raw is String) start = DateTime.tryParse(raw);
      if (start != null && (m['reminderSent'] != true)) {
        await sendEmail(
          recipientEmail: (m['organizerEmail'] ?? '').toString(),
          subject: 'Event Reminder',
          body:
              'Reminder: Your event "${m['title']}" is starting soon (${DateFormat('yyyy-MM-dd HH:mm').format(start)}).',
        );
        await d.reference.update({'reminderSent': true});
      }
    }
  }

  // =============================== UI ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      body: Column(
        children: [
          // Search + New
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search by title / organizer / venue…',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEventPage(
                          venue: '',
                          date: DateTime.now(),
                          timeSlot: '',
                          eventId: '',
                          isUserMode: false,
                          shift: '',
                          selectedShifts: const [],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                ),
              ],
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _buildFilterChips(),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _eventsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((d) => _matchesSearch(d.data())).toList();
                if (docs.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No events found.'),
                  ));
                }

                return RefreshIndicator(
                  onRefresh: () async => _expireApprovedIfPast(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final snap = docs[i];
                      final m = snap.data();

                      final status = _normalizeStatus(m['status']);
                      final start = _parseDate(m['startDateTime']);
                      final dateTxt = start != null ? DateFormat('yyyy-MM-dd').format(start) : 'N/A';

                      // Reason logic
                      String reason = '-';
                      final low = status.toLowerCase();
                      if (low == 'canceled') {
                        reason = (m['cancelledReason'] ?? m['canceledReason'] ?? m['reason'] ?? '-').toString();
                      } else if (low == 'rejected') {
                        reason = (m['rejectedReason'] ?? m['rejectReason'] ?? m['reason'] ?? '-').toString();
                      } else if (low == 'expired') {
                        reason = (m['expiredReason'] ?? m['reason'] ?? '-').toString();
                      }

                      final cancelledBy = (m['cancelledByName'] ??
                              m['cancelledByEmail'] ??
                              m['cancelledByUid'] ??
                              '-')
                          .toString();

                      final cancelledEmail =
                          (m['cancelledEmail'] ?? m['cancelledByEmail'] ?? '-').toString();

                      final cancelledAtTxt = (m['cancelledAt'] is Timestamp)
                          ? DateFormat('yyyy-MM-dd HH:mm').format((m['cancelledAt'] as Timestamp).toDate())
                          : '-';

                      return _EventCard(
                        snap: snap,
                        title: (m['title'] ?? 'Untitled').toString(),
                        dateTxt: dateTxt,
                        venue: (m['venue'] ?? 'N/A').toString(),
                        organizer: (m['organizerName'] ?? 'N/A').toString(),
                        status: status,
                        statusColor: _statusColor(status),
                        organizerEmail: (m['organizerEmail'] ?? '').toString(),
                        // canceled/rejected details
                        reason: reason,
                        cancelledBy: cancelledBy,
                        cancelledEmail: cancelledEmail,
                        cancelledAt: cancelledAtTxt,
                        // actions
                        onApprove: _approveEvent,
                        onReject: _rejectEvent,
                        onComplete: _completeEvent,
                        onRevertPending: _revertToPending,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    Widget chip(String label, EventStatusFilter value) {
      return ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        chip('All', EventStatusFilter.all),
        chip('Pending', EventStatusFilter.pending),
        chip('Approved', EventStatusFilter.approved),
        chip('Completed', EventStatusFilter.completed),
        chip('Rejected', EventStatusFilter.rejected),
        chip('Canceled', EventStatusFilter.canceled),
        chip('Expired', EventStatusFilter.expired),
      ],
    );
  }
}

// ====================== Card (Mobile-friendly) ===============================
class _EventCard extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> snap;
  final String title, dateTxt, venue, organizer, status, organizerEmail;
  final Color statusColor;

  // extra columns
  final String reason;
  final String cancelledBy, cancelledEmail, cancelledAt;

  // actions
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onApprove;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onReject;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onComplete;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onRevertPending;

  const _EventCard({
    required this.snap,
    required this.title,
    required this.dateTxt,
    required this.venue,
    required this.organizer,
    required this.status,
    required this.organizerEmail,
    required this.statusColor,
    required this.reason,
    required this.cancelledBy,
    required this.cancelledEmail,
    required this.cancelledAt,
    required this.onApprove,
    required this.onReject,
    required this.onComplete,
    required this.onRevertPending,
  });

  @override
  Widget build(BuildContext context) {
    final low = status.toLowerCase();
    final pending = low == 'pending';
    final approved = low == 'approved';
    final completed = low == 'completed';
    final rejected = low == 'rejected';
    final canceled = low == 'canceled';
    final expired = low == 'expired';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withOpacity(.5)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 4),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'approve') onApprove(snap);
                    if (v == 'reject') onReject(snap);
                    if (v == 'complete') onComplete(snap);
                    if (v == 'revert') onRevertPending(snap);
                  },
                  itemBuilder: (_) {
                    final items = <PopupMenuEntry<String>>[];
                    if (pending) {
                      items.addAll(const [
                        PopupMenuItem(value: 'approve', child: Text('Approve')),
                        PopupMenuItem(value: 'reject', child: Text('Reject')),
                      ]);
                    }
                    if (approved) {
                      items.addAll(const [
                        PopupMenuItem(value: 'complete', child: Text('Complete')),
                        PopupMenuItem(value: 'revert', child: Text('Revert to Pending')),
                      ]);
                    }
                    if (completed) {
                      items.addAll(const [
                        PopupMenuItem(value: 'revert', child: Text('Reopen (→ Pending)')),
                      ]);
                    }
                    if (rejected) {
                      items.addAll(const [
                        PopupMenuItem(value: 'approve', child: Text('Approve')),
                        PopupMenuItem(value: 'revert', child: Text('Revert to Pending')),
                      ]);
                    }
                    if (canceled) {
                      items.addAll(const [
                        PopupMenuItem(value: 'revert', child: Text('Revert to Pending')),
                      ]);
                    }
                    if (expired) {
                      items.addAll(const [
                        PopupMenuItem(value: 'revert', child: Text('Reopen (→ Pending)')),
                      ]);
                    }
                    return items;
                  },
                )
              ],
            ),
            const SizedBox(height: 6),
            _kv('Date', dateTxt),
            _kv('Venue', venue),
            _kv('Organizer', organizer),
            if (organizerEmail.isNotEmpty) _kv('Email', organizerEmail),

            // Reason section (Rejected/Expired or Canceled)
            if (rejected || expired || canceled) ...[
              const SizedBox(height: 6),
              _sectionHeader(rejected
                  ? 'Reject Reason'
                  : expired
                      ? 'Expired Reason'
                      : 'Cancel Details'),
              const SizedBox(height: 4),
              if (rejected || expired) _kv('Reason', reason.isEmpty ? '-' : reason),
              if (canceled) ...[
                _kv('Reason', reason.isEmpty ? '-' : reason),
                _kv('Cancelled By', cancelledBy.isEmpty ? '-' : cancelledBy),
                _kv('Cancelled Email', cancelledEmail.isEmpty ? '-' : cancelledEmail),
                _kv('Cancelled At', cancelledAt.isEmpty ? '-' : cancelledAt),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(k, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
