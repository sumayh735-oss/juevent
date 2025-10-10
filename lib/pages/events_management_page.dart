// -----------------------------------------------------------------------------
// events_management_with_status.dart (FINAL - All Statuses, No Delete Anywhere)
// -----------------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:withfbase/pages/add_event_page.dart';

// -----------------------------------------------------------------------------
// SMTP Email Helper
// -----------------------------------------------------------------------------
Future<void> sendEmail({
  required String recipientEmail,
  required String subject,
  required String body,
}) async {
  const String username = 'sumayh735@gmail.com';
  const String password = 'kuqo fmer odgv awqe'; // Gmail App Password

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
    debugPrint('❌ Email send error: $e');
  }
}

// -----------------------------------------------------------------------------
// MAIN PAGE
// -----------------------------------------------------------------------------
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
    _searchController.addListener(() {
      setState(() => _searchTerm = _searchController.text.toLowerCase());
    });
    checkAndSendReminders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeStatus(String? raw) {
    if (raw == null) return 'Pending';
    final lower = raw.toLowerCase();
    switch (lower) {
      case 'approved':
        return 'Approved';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'canceled':
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

  // ---------------------------------------------------------------------------
  // Firestore Stream by Filter
  // ---------------------------------------------------------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> _eventsStream() {
    final coll = FirebaseFirestore.instance.collection('events');
    switch (_filter) {
      case EventStatusFilter.pending:
        return coll.where('status', whereIn: ['Pending', 'pending']).snapshots();
      case EventStatusFilter.approved:
        return coll.where('status', whereIn: ['Approved', 'approved']).snapshots();
      case EventStatusFilter.completed:
        return coll.where('status', whereIn: ['Completed', 'completed']).snapshots();
      case EventStatusFilter.rejected:
        return coll.where('status', whereIn: ['Rejected', 'rejected']).snapshots();
      case EventStatusFilter.canceled:
        return coll.where('status', whereIn: ['Canceled', 'canceled']).snapshots();
      case EventStatusFilter.expired:
        return coll.where('status', whereIn: ['Expired', 'expired']).snapshots();
      default:
        return coll.orderBy('startDateTime').snapshots();
    }
  }

  // ---------------------------------------------------------------------------
  // STATUS ACTIONS
  // ---------------------------------------------------------------------------
  Future<void> _approveEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final data = snap.data();
    if (data == null) return;
    await snap.reference.update({
      'status': 'Approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': FirebaseAuth.instance.currentUser?.uid,
    });
    await sendEmail(
      recipientEmail: data['organizerEmail'] ?? '',
      subject: 'Event Approved',
      body: 'Dear organizer,\n\nYour event "${data['title']}" has been approved.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event Approved')),
    );
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

    await snap.reference.update({
      'status': 'Rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedReason': reason,
    });

    final data = snap.data();
    if (data != null) {
      await sendEmail(
        recipientEmail: data['organizerEmail'] ?? '',
        subject: 'Event Rejected',
        body:
            'Dear organizer,\n\nYour event "${data['title']}" was rejected.\nReason: $reason',
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event Rejected')),
    );
  }

  Future<void> _completeEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final data = snap.data();
    if (data == null) return;
    await snap.reference.update({
      'status': 'Completed',
      'completedAt': FieldValue.serverTimestamp(),
      'completedBy': FirebaseAuth.instance.currentUser?.uid,
    });
    await sendEmail(
      recipientEmail: data['organizerEmail'] ?? '',
      subject: 'Event Completed',
      body: 'Dear organizer,\n\nYour event "${data['title']}" is now marked as completed.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event Completed')),
    );
  }

  Future<void> _cancelEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final data = snap.data();
    if (data == null) return;

    await snap.reference.update({
      'status': 'Pending',
      'canceledAt': FieldValue.serverTimestamp(),
    });

    await sendEmail(
      recipientEmail: data['organizerEmail'] ?? '',
      subject: 'Event Reverted to Pending',
      body:
          'Dear organizer,\n\nYour event "${data['title']}" has been reverted back to Pending by the admin.',
    );

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event reverted to Pending')),
    );
  }

  // ---------------------------------------------------------------------------
  // Reminder
  // ---------------------------------------------------------------------------
  Future<void> checkAndSendReminders() async {
    final query = await FirebaseFirestore.instance
        .collection('events')
        .where('status', isEqualTo: 'Approved')
        .get();

    for (final doc in query.docs) {
      final data = doc.data();
      final rawStart = data['startDateTime'];
      DateTime? startDate;
      if (rawStart is Timestamp) startDate = rawStart.toDate();
      else if (rawStart is String) startDate = DateTime.tryParse(rawStart);

      if (startDate != null && (data['reminderSent'] != true)) {
        await sendEmail(
          recipientEmail: data['organizerEmail'] ?? '',
          subject: 'Event Reminder',
          body:
              'Reminder: Your event "${data['title']}" is starting soon (${DateFormat('yyyy-MM-dd HH:mm').format(startDate)}).',
        );
        await doc.reference.update({'reminderSent': true});
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Events Management',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search events...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
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
                label: const Text('New Event'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilterChips(),
          const Divider(),
          _buildHeaderRow(),
          SizedBox(
            height: 420,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _eventsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text('Error: ${snapshot.error}');
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs
                    .where((doc) => _matchesSearch(doc.data()['title'] as String?))
                    .toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('No events found.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final snap = docs[i];
                    final data = snap.data();
                    final date = _parseDate(data['startDateTime']);
                    final formatted = date != null
                        ? DateFormat('yyyy-MM-dd').format(date)
                        : 'N/A';

                    return _EventRow(
                      snap: snap,
                      title: data['title'] ?? 'Untitled',
                      date: formatted,
                      venue: data['venue'] ?? 'N/A',
                      organizer: data['organizerName'] ?? 'N/A',
                      status: _normalizeStatus(data['status']),
                      organizerEmail: data['organizerEmail'] ?? '',
                      onApprove: _approveEvent,
                      onReject: _rejectEvent,
                      onComplete: _completeEvent,
                      onCancel: _cancelEvent,
                    );
                  },
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

  Widget _buildHeaderRow() {
    const style = TextStyle(fontWeight: FontWeight.bold);
    return const Row(
      children: [
        Expanded(flex: 2, child: Text('Title', style: style)),
        Expanded(flex: 2, child: Text('Date', style: style)),
        Expanded(flex: 2, child: Text('Venue', style: style)),
        Expanded(flex: 2, child: Text('Organizer', style: style)),
        Expanded(flex: 1, child: Text('Status', style: style)),
        Expanded(flex: 2, child: Text('Actions', style: style)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ROW WIDGET
// -----------------------------------------------------------------------------
class _EventRow extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> snap;
  final String title, date, venue, organizer, status, organizerEmail;
  final void Function(DocumentSnapshot<Map<String, dynamic>>) onApprove;
  final void Function(DocumentSnapshot<Map<String, dynamic>>) onReject;
  final void Function(DocumentSnapshot<Map<String, dynamic>>) onComplete;
  final void Function(DocumentSnapshot<Map<String, dynamic>>) onCancel;

  const _EventRow({
    required this.snap,
    required this.title,
    required this.date,
    required this.venue,
    required this.organizer,
    required this.status,
    required this.organizerEmail,
    required this.onApprove,
    required this.onReject,
    required this.onComplete,
    required this.onCancel,
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
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = status.toLowerCase() == 'pending';
    final approved = status.toLowerCase() == 'approved';
    final completed = status.toLowerCase() == 'completed';
    final rejected = status.toLowerCase() == 'rejected';
    final canceled = status.toLowerCase() == 'canceled';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(title)),
          Expanded(flex: 2, child: Text(date)),
          Expanded(flex: 2, child: Text(venue)),
          Expanded(flex: 2, child: Text(organizer)),
          Expanded(
            flex: 1,
            child: Chip(
              label: Text(status, style: const TextStyle(color: Colors.white)),
              backgroundColor: _statusColor(status),
            ),
          ),
          Expanded(
            flex: 2,
            child: PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'approve') onApprove(snap);
                if (val == 'reject') onReject(snap);
                if (val == 'complete') onComplete(snap);
                if (val == 'cancel') onCancel(snap);
              },
              itemBuilder: (_) => [
                if (pending) ...[
                  const PopupMenuItem(value: 'approve', child: Text('Approve')),
                  const PopupMenuItem(value: 'reject', child: Text('Reject')),
                ],
                if (approved) ...[
                  const PopupMenuItem(value: 'complete', child: Text('Complete')),
                  const PopupMenuItem(value: 'cancel', child: Text('Cancel (→ Pending)')),
                ],
                if (rejected || canceled) ...[
                  const PopupMenuItem(value: 'cancel', child: Text('Revert to Pending')),
                ],
                if (completed) ...[
                  const PopupMenuItem(value: 'cancel', child: Text('Reopen (→ Pending)')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
