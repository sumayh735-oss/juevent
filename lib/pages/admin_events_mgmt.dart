// -----------------------------------------------------------------------------
// events_management_with_status.dart (FINAL with Fixed Header)
// -----------------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:withfbase/pages/add_event_page.dart';
import 'package:withfbase/widgets/home_header.dart'; // make sure this import exists

// -----------------------------------------------------------------------------
// SMTP Email Helper
// -----------------------------------------------------------------------------
Future<void> sendEmail({
  required String recipientEmail,
  required String subject,
  required String body,
}) async {
  const String username = 'sumayh735@gmail.com';
  const String password = 'kuqo fmer odgv awqe'; // Gmail App password

  final smtpServer = gmail(username, password);

  final message =
      Message()
        ..from = Address(username, 'Jazeera University Admin')
        ..recipients.add(recipientEmail)
        ..subject = subject
        ..text = body;

  try {
    await send(message, smtpServer);
    debugPrint('✅ SMTP: Email sent to $recipientEmail');
  } catch (e) {
    debugPrint('❌ SMTP error: $e');
  }
}

class AdminEventsMgmt extends StatefulWidget {
  const AdminEventsMgmt({super.key});

  @override
  State<AdminEventsMgmt> createState() => _AdminEventsMgmtState();
}

enum EventStatusFilter { all, pending, approved, completed, rejected }

class _AdminEventsMgmtState extends State<AdminEventsMgmt> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  EventStatusFilter _filter = EventStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchTerm = _searchController.text.toLowerCase());
    });
    expireApprovedEvents();
    checkAndSendReminders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizedStatus(String? raw) {
    if (raw == null) return 'Pending';
    switch (raw.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      default:
        return 'Pending';
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
        return coll
            .where('status', whereIn: ['Pending', 'pending'])
            .orderBy('createdAt', descending: true)
            .snapshots();
      case EventStatusFilter.approved:
        return coll
            .where('status', whereIn: ['Approved', 'approved'])
            .orderBy('startDateTime')
            .snapshots();
      case EventStatusFilter.completed:
        return coll
            .where('status', whereIn: ['Completed', 'completed'])
            .orderBy('startDateTime')
            .snapshots();
      case EventStatusFilter.rejected:
        return coll
            .where('status', whereIn: ['Rejected', 'rejected'])
            .orderBy('createdAt', descending: true)
            .snapshots();
      default:
        return coll.orderBy('startDateTime').snapshots();
    }
  }

  // Approve
  Future<void> _approveEvent(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) async {
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
        body:
            'Dear organizer,\n\nYour event "${data['title']}" has been approved.',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event approved')));
    }
  }

  // Complete
  Future<void> _completeEvent(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) async {
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
        body:
            'Dear organizer,\n\nYour event "${data['title']}" has been marked as Completed.',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event marked as Completed')),
      );
    }
  }

  // Reject
  Future<void> _rejectEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reject Reason'),
            content: TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(hintText: 'Enter reason...'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
                child: const Text('Reject'),
              ),
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
        body:
            'Dear organizer,\n\nYour event "${data['title']}" was rejected.\nReason: $reason',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event rejected')));
    }
  }

  // Expire Approved if time passed
  Future<void> expireApprovedEvents() async {
    final now = DateTime.now();

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .where('status', isEqualTo: 'Approved')
              .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();

        DateTime? endDateTime;
        final rawEnd = data['endDateTime'];

        if (rawEnd is Timestamp) {
          endDateTime = rawEnd.toDate();
        } else if (rawEnd is String) {
          endDateTime = DateTime.tryParse(rawEnd);
        }

        if (endDateTime == null) continue;

        final currentStatus = (data['status'] ?? '').toString().toLowerCase();

        if (currentStatus == 'approved' && endDateTime.isBefore(now)) {
          await doc.reference.update({'status': 'Expired'});
          debugPrint('⚠️ Event expired: ${data['title'] ?? doc.id}');

          final organizerId = data['organizerId'];
          if (organizerId != null) {
            final userRef = FirebaseFirestore.instance
                .collection('users')
                .doc(organizerId);
            final userDoc = await userRef.get();

            if (userDoc.exists) {
              final userData = userDoc.data();
              int expiredCount = (userData?['expiredCount'] ?? 0) + 1;

              final Map<String, dynamic> updateData = {
                'expiredCount': expiredCount,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (expiredCount >= 3) {
                updateData['blacklisted'] = true;
                updateData['blockedAt'] = FieldValue.serverTimestamp();

                final userEmail = userData?['email'] ?? '';
                final userName = userData?['fullName'] ?? 'Organizer';

                if (userEmail.isNotEmpty) {
                  await sendEmail(
                    recipientEmail: userEmail,
                    subject: 'Account Blacklisted - Jazeera University',
                    body: '''
Hello $userName,

Your account has been BLACKLISTED due to 3 or more expired events.

You are no longer allowed to create or manage new events until further notice.

If you believe this is a mistake, please contact the administrator.

-- Jazeera University Admin
''',
                  );
                }

                debugPrint(
                  "🚫 User $organizerId blacklisted after $expiredCount expired events",
                );
              }

              await userRef.update(updateData);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error expiring events: $e');
    }
  }

  // Reminder Emails
  Future<void> checkAndSendReminders() async {
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('events')
            .where('status', isEqualTo: 'Approved')
            .get();

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      DateTime? startDate;
      final rawStart = data['startDateTime'];

      if (rawStart is Timestamp) {
        startDate = rawStart.toDate();
      } else if (rawStart is String) {
        startDate = DateTime.tryParse(rawStart);
      }

      if (startDate != null && (data['reminderSent'] != true)) {
        await sendEmail(
          recipientEmail: data['organizerEmail'] ?? '',
          subject: 'Event Reminder',
          body:
              'Reminder: Your event "${data['title']}" is starting soon (${startDate.toLocal()}).',
        );
        await doc.reference.update({'reminderSent': true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(child: Text("Menu")),
            ListTile(leading: Icon(Icons.home), title: Text("Home")),
          ],
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Builder(
          builder:
              (context) => HomeHeader(
                onMenuTap: () => Scaffold.of(context).openEndDrawer(),
                title: 'Events Management',
              ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search events...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AddEventPage(
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
                  label: const Text('New Event'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFilterChips(),
            const Divider(),
            _buildHeaderRow(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _eventsStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    debugPrint("❌ Firestore error: ${snapshot.error}");
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs =
                      snapshot.data!.docs
                          .where(
                            (doc) =>
                                _matchesSearch(doc.data()['title'] as String?),
                          )
                          .toList();

                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No events found.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final snap = docs[index];
                      final data = snap.data();
                      final start = _parseDate(data['startDateTime']);
                      final formatted =
                          start != null
                              ? DateFormat('yyyy-MM-dd').format(start)
                              : 'N/A';

                      return _EventRow(
                        snap: snap,
                        title: data['title'] ?? 'Untitled',
                        date: formatted,
                        venue: data['venue'] ?? 'N/A',
                        organizer: data['organizerName'] ?? 'N/A',
                        status: _normalizedStatus(data['status']),
                        organizerEmail: data['organizerEmail'] ?? '',
                        onApprove: _approveEvent,
                        onComplete: _completeEvent,
                        onReject: _rejectEvent,
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
        Expanded(flex: 2, child: Text('Action', style: style)),
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
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onApprove;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onComplete;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onReject;

  const _EventRow({
    required this.snap,
    required this.title,
    required this.date,
    required this.venue,
    required this.organizer,
    required this.status,
    required this.organizerEmail,
    required this.onApprove,
    required this.onComplete,
    required this.onReject,
  });

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
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = status.toLowerCase() == 'pending';
    final approved = status.toLowerCase() == 'approved';

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
                if (val == 'complete') onComplete(snap);
                if (val == 'reject') onReject(snap);
              },
              itemBuilder:
                  (_) => [
                    if (pending) ...[
                      const PopupMenuItem(
                        value: 'approve',
                        child: Text('Approve'),
                      ),
                      const PopupMenuItem(
                        value: 'reject',
                        child: Text('Reject'),
                      ),
                    ],
                    if (approved) ...[
                      const PopupMenuItem(
                        value: 'complete',
                        child: Text('Complete'),
                      ),
                    ],
                  ],
            ),
          ),
        ],
      ),
    );
  }
}
