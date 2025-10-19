// -----------------------------------------------------------------------------
// events_management_with_status.dart (Admin-style UI, No Delete Anywhere)
// -----------------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:withfbase/pages/desktop/add_event_page_desktop.dart';

// ============================= SMTP HELPER ===================================
Future<void> sendEmail({
  required String recipientEmail,
  required String subject,
  required String body,
}) async {
  const String username = 'sumayh735@gmail.com';
  const String password = 'kuqo fmer odgv awqe'; // Gmail App Password (suggest env)

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
class EventsManagementDesktop extends StatefulWidget {
  const EventsManagementDesktop({super.key});

  @override
  State<EventsManagementDesktop> createState() => _EventsManagementDesktopState();
}

enum EventStatusFilter { all, pending, approved, completed, rejected, canceled, expired }

class _EventsManagementDesktopState extends State<EventsManagementDesktop> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  EventStatusFilter _filter = EventStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _searchTerm = _searchController.text.toLowerCase()),
    );
    _expireApprovedEventsIfPast();
    _sendRemindersForApproved();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------- Utils ----------------------------------------
  String _normalizeStatus(String? raw) {
    if (raw == null) return 'Pending';
    switch (raw.toLowerCase()) {
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
      default:
        return 'Pending';
    }
  }

  bool _matchesSearch(String? title) =>
      title?.toLowerCase().contains(_searchTerm) ?? false;

  DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
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
        return coll.where('status', whereIn: ['Canceled', 'canceled', 'cancelled']).orderBy('createdAt', descending: true).snapshots();
      case EventStatusFilter.expired:
        return coll.where('status', whereIn: ['Expired', 'expired']).orderBy('createdAt', descending: true).snapshots();
      default:
        return coll.orderBy('startDateTime').snapshots();
    }
  }

  // ---------------------------- Actions --------------------------------------
  Future<void> _approveEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final data = snap.data();
    if (data == null) return;

    await snap.reference.update({
      'status': 'Approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    final email = (data['organizerEmail'] ?? '') as String;
    if (email.isNotEmpty) {
      await sendEmail(
        recipientEmail: email,
        subject: 'Event Approved',
        body: 'Dear organizer,\n\nYour event "${data['title']}" has been approved.',
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event Approved')));
    }
  }

  Future<void> _completeEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final data = snap.data();
    if (data == null) return;

    await snap.reference.update({
      'status': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
      'completedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    final email = (data['organizerEmail'] ?? '') as String;
    if (email.isNotEmpty) {
      await sendEmail(
        recipientEmail: email,
        subject: 'Event Completed',
        body: 'Dear organizer,\n\nYour event "${data['title']}" is now marked as Completed.',
      );
    }
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

    final data = snap.data();
    if (data == null) return;

    await snap.reference.update({
      'status': 'Rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedReason': reason,
    });

    final email = (data['organizerEmail'] ?? '') as String;
    if (email.isNotEmpty) {
      await sendEmail(
        recipientEmail: email,
        subject: 'Event Rejected',
        body: 'Dear organizer,\n\nYour event "${data['title']}" was rejected.\nReason: $reason',
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event Rejected')));
    }
  }

  // Revert any to Pending (used for Approved/Rejected/Canceled/Completed/Expired)
  Future<void> _revertToPending(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final data = snap.data();
    await snap.reference.update({'status': 'Pending'});

    final email = (data?['organizerEmail'] ?? '') as String;
    if (email.isNotEmpty) {
      await sendEmail(
        recipientEmail: email,
        subject: 'Event Reverted to Pending',
        body: 'Dear organizer,\n\nYour event "${data?['title']}" has been reverted to Pending by the admin.',
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reverted to Pending')));
    }
  }

  // -------------------------- Housekeeping -----------------------------------
  Future<void> _expireApprovedEventsIfPast() async {
    final now = DateTime.now();
    try {
      final qs = await FirebaseFirestore.instance
          .collection('events')
          .where('status', isEqualTo: 'Approved')
          .get();

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
    final qs = await FirebaseFirestore.instance
        .collection('events')
        .where('status', isEqualTo: 'Approved')
        .get();

    for (final d in qs.docs) {
      final m = d.data();
      DateTime? start;
      final rawStart = m['startDateTime'];
      if (rawStart is Timestamp) start = rawStart.toDate();
      if (rawStart is String) start = DateTime.tryParse(rawStart);

      if (start != null && (m['reminderSent'] != true)) {
        await sendEmail(
          recipientEmail: m['organizerEmail'] ?? '',
          subject: 'Event Reminder',
          body: 'Reminder: Your event "${m['title']}" is starting soon (${DateFormat('yyyy-MM-dd HH:mm').format(start)}).',
        );
        await d.reference.update({'reminderSent': true});
      }
    }
  }

  // =============================== UI ========================================
  @override
  Widget build(BuildContext context) {
    final showCancelledCols = _filter == EventStatusFilter.canceled;
    final showOnlyReason   = _filter == EventStatusFilter.rejected;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Events Management', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          const SizedBox(height: 12),

          // Search + New
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search events…',
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
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 46,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEventPageDesktop(
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
                  label: const Text('New Event'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter chips
          _buildFilterChips(),
          const SizedBox(height: 8),

          // Header row (dynamic columns)
          _HeaderRow(
            showCancelledCols: showCancelledCols,
            showOnlyReason: showOnlyReason,
          ),
          const SizedBox(height: 4),

          // List
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _eventsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs
                      .where((doc) => _matchesSearch(doc.data()['title'] as String?))
                      .toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text('No events found.'),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, i) {
                      final snap = docs[i];
                      final m = snap.data();

                      final start = _parseDate(m['startDateTime']);
                      final formatted = start != null ? DateFormat('yyyy-MM-dd').format(start) : 'N/A';

                      final statusNorm = _normalizeStatus(m['status']);
                      final low = statusNorm.toLowerCase();

                      // pick reason depending on status
                      final reason = () {
                        if (low == 'canceled') {
                          return (m['cancelledReason'] ?? m['canceledReason'] ?? '-') as String;
                        }
                        if (low == 'rejected') {
                          return (m['rejectedReason'] ?? m['rejectReason'] ?? '-') as String;
                        }
                        if (low == 'expired') {
                          return (m['expiredReason'] ?? '-') as String;
                        }
                        return '-';
                      }();

                      final cancelledBy = (m['cancelledByName'] ??
                          m['cancelledByEmail'] ??
                          m['cancelledByUid'] ??
                          '-') as String;

                      final cancelledEmail =
                          (m['cancelledEmail'] ?? m['cancelledByEmail'] ?? '-') as String;

                      final cancelledAtTxt = (m['cancelledAt'] is Timestamp)
                          ? DateFormat('yyyy-MM-dd HH:mm')
                              .format((m['cancelledAt'] as Timestamp).toDate())
                          : '-';

                      return _EventRow(
                        snap: snap,
                        title: m['title'] ?? 'Untitled',
                        date: formatted,
                        venue: m['venue'] ?? 'N/A',
                        organizer: m['organizerName'] ?? 'N/A',
                        status: statusNorm,
                        organizerEmail: m['organizerEmail'] ?? '',
                        // dynamic columns
                        showCancelledCols: showCancelledCols,
                        showOnlyReason: showOnlyReason,
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
                  );
                },
              ),
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

// ====================== Header Row (dynamic columns) ==========================
class _HeaderRow extends StatelessWidget {
  final bool showCancelledCols; // Canceled: show 3 extra columns
  final bool showOnlyReason;    // Rejected: only reason

  const _HeaderRow({
    required this.showCancelledCols,
    required this.showOnlyReason,
  });

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.bold, color: Colors.black87);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Expanded(flex: 2, child: Text('Title', style: style)),
          const Expanded(flex: 2, child: Text('Date', style: style)),
          const Expanded(flex: 2, child: Text('Venue', style: style)),
          const Expanded(flex: 2, child: Text('Organizer', style: style)),
          const Expanded(flex: 1, child: Text('Status', style: style)),
          if (showOnlyReason || showCancelledCols)
            const Expanded(flex: 2, child: Text('Reason', style: style)),
          if (showCancelledCols) ...const [
            Expanded(flex: 2, child: Text('Cancelled By', style: style)),
            Expanded(flex: 2, child: Text('Cancelled Email', style: style)),
            Expanded(flex: 2, child: Text('Cancelled At', style: style)),
          ],
          const Expanded(flex: 2, child: Text('Action', style: style)),
        ],
      ),
    );
  }
}

// ====================== Row ==========================
class _EventRow extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> snap;
  final String title, date, venue, organizer, status, organizerEmail;

  // dynamic columns
  final bool showCancelledCols;
  final bool showOnlyReason;
  final String reason;
  final String cancelledBy, cancelledEmail, cancelledAt;

  // actions
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onApprove;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onReject;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onComplete;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onRevertPending;

  const _EventRow({
    required this.snap,
    required this.title,
    required this.date,
    required this.venue,
    required this.organizer,
    required this.status,
    required this.organizerEmail,
    required this.showCancelledCols,
    required this.showOnlyReason,
    required this.reason,
    required this.cancelledBy,
    required this.cancelledEmail,
    required this.cancelledAt,
    required this.onApprove,
    required this.onReject,
    required this.onComplete,
    required this.onRevertPending,
  });

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

  @override
  Widget build(BuildContext context) {
    final low = status.toLowerCase();
    final pending  = low == 'pending';
    final approved = low == 'approved';
    final completed = low == 'completed';
    final rejected = low == 'rejected';
    final canceled = low == 'canceled';
    final expired  = low == 'expired';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(title)),
          Expanded(flex: 2, child: Text(date)),
          Expanded(flex: 2, child: Text(venue)),
          Expanded(flex: 2, child: Text(organizer)),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                backgroundColor: _statusColor(status),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),

          if (showOnlyReason || showCancelledCols)
            Expanded(
              flex: 2,
              child: Tooltip(
                message: reason.isEmpty ? '-' : reason,
                child: Text(
                  reason.isEmpty ? '-' : reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          if (showCancelledCols) ...[
            Expanded(
              flex: 2,
              child: Tooltip(
                message: cancelledBy.isEmpty ? '-' : cancelledBy,
                child: Text(
                  cancelledBy.isEmpty ? '-' : cancelledBy,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Tooltip(
                message: cancelledEmail.isEmpty ? '-' : cancelledEmail,
                child: Text(
                  cancelledEmail.isEmpty ? '-' : cancelledEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(flex: 2, child: Text(cancelledAt)),
          ],

          // Actions
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'approve') onApprove(snap);
                  if (val == 'reject') onReject(snap);
                  if (val == 'complete') onComplete(snap);
                  if (val == 'revert') onRevertPending(snap);
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
                      PopupMenuItem(value: 'revert', child: Text('Revert to Pending')), // NO approve on canceled
                    ]);
                  }
                  if (expired) {
                    items.addAll(const [
                      PopupMenuItem(value: 'revert', child: Text('Reopen (→ Pending)')),
                    ]);
                  }

                  return items;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
