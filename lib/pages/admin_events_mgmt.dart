// -----------------------------------------------------------------------------
// admin_events_mgmt_mobile.dart  ✅ FINAL MOBILE VERSION (Reason + Cancel Info)
// -----------------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:withfbase/pages/add_event_page.dart';
import 'package:withfbase/widgets/home_header.dart';

// -----------------------------------------------------------------------------
// EMAIL FUNCTION
// -----------------------------------------------------------------------------
Future<void> sendEmail({
  required String recipientEmail,
  required String subject,
  required String body,
}) async {
  const String username = 'sumayh735@gmail.com';
  const String password = 'kuqo fmer odgv awqe';
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
    debugPrint('❌ SMTP error: $e');
  }
}

// -----------------------------------------------------------------------------
// MAIN SCREEN
// -----------------------------------------------------------------------------
class AdminEventsMgmt extends StatefulWidget {
  const AdminEventsMgmt({super.key});
  @override
  State<AdminEventsMgmt> createState() => _AdminEventsMgmtState();
}

enum EventStatusFilter { all, pending, approved, completed, rejected, canceled, deleted }

class _AdminEventsMgmtState extends State<AdminEventsMgmt> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  EventStatusFilter _filter = EventStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _searchTerm = _searchController.text.toLowerCase()));
    expireApprovedEvents();
    checkAndSendReminders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Normalize statuses
  String _normalizedStatus(String? raw) {
    if (raw == null) return 'Pending';
    switch (raw.toLowerCase()) {
      case 'approved': return 'Approved';
      case 'completed': return 'Completed';
      case 'rejected': return 'Rejected';
      case 'expired': return 'Expired';
      case 'canceled':
      case 'cancelled': return 'Canceled';
      case 'deleted': return 'Deleted';
      default: return 'Pending';
    }
  }

  bool _matchesSearch(String? title) {
    if (title == null) return false;
    return title.toLowerCase().contains(_searchTerm);
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

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
      case EventStatusFilter.deleted:
        return coll.where('status', whereIn: ['Deleted', 'deleted']).orderBy('createdAt', descending: true).snapshots();
      default:
        return coll.orderBy('startDateTime').snapshots();
    }
  }

  // ---------------------------------------------------------------------------
  // ACTION METHODS
  // ---------------------------------------------------------------------------
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
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event approved')));
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
        body: 'Dear organizer,\n\nYour event "${data['title']}" has been marked as Completed.',
      );
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event completed')));
  }

  Future<void> _rejectEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Reason'),
        content: TextField(controller: reasonCtrl, decoration: const InputDecoration(hintText: 'Enter reason...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()), child: const Text('Reject')),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    final data = snap.data();
    if (data == null) return;
    await snap.reference.update({'status': 'Rejected', 'rejectedReason': reason, 'rejectedAt': FieldValue.serverTimestamp()});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event rejected')));
  }

  Future<void> _revertToPending(DocumentSnapshot<Map<String, dynamic>> snap) async {
    await snap.reference.update({'status': 'Pending'});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event reverted to Pending')));
  }

  Future<void> _deleteEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    await snap.reference.update({'status': 'Deleted'});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted')));
  }

  // ---------------------------------------------------------------------------
  // BACKGROUND TASKS
  // ---------------------------------------------------------------------------
  Future<void> expireApprovedEvents() async {
    final now = DateTime.now();
    final qs = await FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'Approved').get();
    for (final doc in qs.docs) {
      final data = doc.data();
      final end = (data['endDateTime'] as Timestamp?)?.toDate();
      if (end != null && end.isBefore(now)) await doc.reference.update({'status': 'Expired'});
    }
  }

  Future<void> checkAndSendReminders() async {
    final qs = await FirebaseFirestore.instance.collection('events').where('status', isEqualTo: 'Approved').get();
    for (final doc in qs.docs) {
      final data = doc.data();
      DateTime? start;
      final rawStart = data['startDateTime'];
      if (rawStart is Timestamp) start = rawStart.toDate();
      if (rawStart is String) start = DateTime.tryParse(rawStart);
      if (start != null && (data['reminderSent'] != true)) {
        await sendEmail(
          recipientEmail: data['organizerEmail'] ?? '',
          subject: 'Event Reminder',
          body: 'Reminder: Your event "${data['title']}" is starting soon (${start.toLocal()}).',
        );
        await doc.reference.update({'reminderSent': true});
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final showReason = _filter == EventStatusFilter.rejected || _filter == EventStatusFilter.canceled;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Builder(
          builder: (context) => HomeHeader(
            onMenuTap: () => Scaffold.of(context).openEndDrawer(),
            title: 'Events Management',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search events...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
                          selectedShifts: [],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildFilterChips(),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _eventsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final docs = snapshot.data!.docs.where((d) => _matchesSearch(d.data()['title'] as String?)).toList();
                  if (docs.isEmpty) return const Center(child: Text('No events found'));

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final snap = docs[i];
                      final data = snap.data();
                      final start = _parseDate(data['startDateTime']);
                      final formatted = start != null ? DateFormat('MMM d, yyyy').format(start) : 'N/A';
                      final status = _normalizedStatus(data['status']);
                      final reason = data['rejectedReason'] ?? data['cancelledReason'] ?? '-';
                      final canceledBy = data['cancelledByName'] ?? '-';
                      final canceledEmail = data['cancelledEmail'] ?? '-';
                      final canceledAt = data['cancelledAt'] is Timestamp
                          ? DateFormat('yyyy-MM-dd HH:mm').format((data['cancelledAt'] as Timestamp).toDate())
                          : '-';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['title'] ?? 'Untitled Event',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(status, style: const TextStyle(color: Colors.white)),
                                    backgroundColor: _statusColor(status),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('📅 Date: $formatted'),
                              Text('🏛️ Venue: ${data['venue'] ?? 'N/A'}'),
                              Text('👤 Organizer: ${data['organizerName'] ?? 'N/A'}'),
                              const SizedBox(height: 6),
                              if (showReason)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('📝 Reason: $reason'),
                                    if (_filter == EventStatusFilter.canceled) ...[
                                      Text('❌ Cancelled By: $canceledBy'),
                                      Text('📧 Email: $canceledEmail'),
                                      Text('⏰ At: $canceledAt'),
                                    ],
                                  ],
                                ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'approve') _approveEvent(snap);
                                    if (val == 'complete') _completeEvent(snap);
                                    if (val == 'reject') _rejectEvent(snap);
                                    if (val == 'revert') _revertToPending(snap);
                                    if (val == 'delete') _deleteEvent(snap);
                                  },
                                  itemBuilder: (_) {
                                    final items = <PopupMenuEntry<String>>[];
                                    final low = status.toLowerCase();
                                    if (low == 'pending') {
                                      items.addAll(const [
                                        PopupMenuItem(value: 'approve', child: Text('Approve')),
                                        PopupMenuItem(value: 'reject', child: Text('Reject')),
                                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                                      ]);
                                    } else if (low == 'approved') {
                                      items.addAll(const [
                                        PopupMenuItem(value: 'complete', child: Text('Complete')),
                                        PopupMenuItem(value: 'revert', child: Text('Revert to Pending')),
                                      ]);
                                    } else if (low == 'completed') {
                                      items.addAll(const [
                                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                                      ]);
                                    } else if (low == 'rejected' || low == 'canceled') {
                                      items.addAll(const [
                                        PopupMenuItem(value: 'approve', child: Text('Approve')),
                                        PopupMenuItem(value: 'revert', child: Text('Revert to Pending')),
                                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                                      ]);
                                    }
                                    return items;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.black54;
      case 'canceled':
        return Colors.grey;
      case 'deleted':
        return Colors.brown;
      default:
        return Colors.orange;
    }
  }

  Widget _buildFilterChips() {
    Widget chip(String label, EventStatusFilter value) {
      return ChoiceChip(
        label: Text(label),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', EventStatusFilter.all),
          const SizedBox(width: 6),
          chip('Pending', EventStatusFilter.pending),
          const SizedBox(width: 6),
          chip('Approved', EventStatusFilter.approved),
          const SizedBox(width: 6),
          chip('Completed', EventStatusFilter.completed),
          const SizedBox(width: 6),
          chip('Rejected', EventStatusFilter.rejected),
          const SizedBox(width: 6),
          chip('Canceled', EventStatusFilter.canceled),
          const SizedBox(width: 6),
          chip('Deleted', EventStatusFilter.deleted),
        ],
      ),
    );
  }
}
