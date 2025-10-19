// -----------------------------------------------------------------------------
// events_management_with_status.dart  (FULL FILE — no line omitted)
// Booking rule: Pending/Approved => true, else => false
// -----------------------------------------------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:withfbase/pages/desktop/add_event_page_desktop.dart';
import 'package:withfbase/pages/desktop/admin_home_header_desktop.dart';

// ---------------- EMAIL ----------------
Future<void> sendEmail({
  required String recipientEmail,
  required String subject,
  required String body,
}) async {
  const String username = 'sumayh735@gmail.com';
  const String password = 'kuqo fmer odgv awqe'; // -> beddel hab ammaan ah
  final smtpServer = gmail(username, password);

  final message = Message()
    ..from = Address(username, 'Jazeera University Admin')
    ..recipients.add(recipientEmail)
    ..subject = subject
    ..text = body;

  try {
    await send(message, smtpServer);
    // ignore: avoid_print
    print('✅ SMTP: Email sent to $recipientEmail');
  } catch (e) {
    // ignore: avoid_print
    print('❌ SMTP error: $e');
  }
}

// ---------------- WIDGET ----------------
class AdminEventsMgmtDesktop extends StatefulWidget {
  const AdminEventsMgmtDesktop({super.key});
  @override
  State<AdminEventsMgmtDesktop> createState() => _AdminEventsMgmtDesktopState();
}

enum EventStatusFilter { all, pending, approved, completed, rejected, canceled, deleted }

class _AdminEventsMgmtDesktopState extends State<AdminEventsMgmtDesktop> {
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

  // ---------------- HELPERS ----------------
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
      case 'canceled':
      case 'cancelled':
        return 'Canceled';
      case 'deleted':
        return 'Deleted';
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

  String _dateKeyYYYYMD(DateTime d) => '${d.year}-${d.month}-${d.day}';
  String _dateKeyFromEvent(dynamic startDateTime) {
    DateTime? d;
    if (startDateTime is Timestamp) d = startDateTime.toDate();
    if (startDateTime is String) d = DateTime.tryParse(startDateTime);
    d ??= DateTime.now();
    return _dateKeyYYYYMD(d);
  }

  bool _hasMorning(List<dynamic> shifts) {
    try {
      return shifts.any((s) => s.toString().contains('08:00'));
    } catch (_) {
      return false;
    }
  }

  bool _hasAfternoon(List<dynamic> shifts) {
    try {
      return shifts.any((s) => s.toString().contains('02:00'));
    } catch (_) {
      return false;
    }
  }

  // ---------------- STREAM ----------------
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

  // ---------------- BOOKING TOGGLE BASED ON STATUS ----------------
  /// Map status -> booking boolean:
  /// Pending/Approved => true; Completed/Canceled/Rejected/Deleted/Expired => false
Future<void> _updateBookingByStatus(
  DocumentSnapshot<Map<String, dynamic>> snap,
  String newStatus,
) async {
  final data = snap.data();
  if (data == null) return;

  final start = data['startDateTime'];
  final venueRaw = (data['venue'] ?? '') as String;
  final venue = venueRaw.replaceAll(RegExp(r'\s+'), '').trim();
  final safeVenue = venue.isEmpty ? 'UnknownVenue' : venue; // ✅ fallback if empty
  final dateKey = _dateKeyFromEvent(start);
  final shiftsDyn = (data['selectedShifts'] ?? []) as List<dynamic>;

  final morning = _hasMorning(shiftsDyn);
  final afternoon = _hasAfternoon(shiftsDyn);

  final statusLower = newStatus.toLowerCase();
  final shouldBeTrue = statusLower == 'pending' || statusLower == 'approved';

  final bookingId = '${dateKey}_$safeVenue'; // ✅ always unique per venue
  print('DEBUG: bookingId=$bookingId (venue=$venueRaw, dateKey=$dateKey)'); // 🧩 debug

  final bookingRef = FirebaseFirestore.instance.collection('booking').doc(bookingId);

  try {
    final existing = await bookingRef.get();
    final updateData = <String, dynamic>{
      'dateKey': dateKey,
      'venue': safeVenue,
      'updatedAt': FieldValue.serverTimestamp(),
      if (morning) 'morning': shouldBeTrue,
      if (afternoon) 'afternoon': shouldBeTrue,
    };

    if (existing.exists) {
      await bookingRef.update(updateData);
      print('🟩 booking/$bookingId UPDATED → morning:$morning->$shouldBeTrue, afternoon:$afternoon->$shouldBeTrue, status:$newStatus');
    } else {
      await bookingRef.set(updateData);
      print('🟨 booking/$bookingId CREATED → morning:$morning->$shouldBeTrue, afternoon:$afternoon->$shouldBeTrue, status:$newStatus');
    }
  } catch (e) {
    print('❌ Booking update failed for $bookingId → $e');
  }
}
// Optional: calendar cleanup for negative statuses (keeps your earlier behavior)
Future<void> _clearCalendarColorIfNegativeStatus(
  DocumentSnapshot<Map<String, dynamic>> snap,
  String newStatus,
) async {
  final negative = {
    'completed',
    'canceled',
    'cancelled',
    'rejected',
    'deleted',
    'expired',
  };
  if (!negative.contains(newStatus.toLowerCase())) return;

  final data = snap.data();
  if (data == null) return;

  final start = data['startDateTime'];
  final venueRaw = (data['venue'] ?? '') as String;
  final venue = venueRaw.replaceAll(RegExp(r'\s+'), '').trim();
  final safeVenue = venue.isEmpty ? 'UnknownVenue' : venue; // ✅ normalize
  final dateKey = _dateKeyFromEvent(start);
  final shiftsDyn = (data['selectedShifts'] ?? []) as List<dynamic>;
  final morning = _hasMorning(shiftsDyn);
  final afternoon = _hasAfternoon(shiftsDyn);

  final calRef = FirebaseFirestore.instance.collection('calendar').doc(dateKey);
  final updates = <String, dynamic>{
    'updatedAt': FieldValue.serverTimestamp(),
  };

  if (morning) {
    updates['morningColor'] = null;
    updates['${safeVenue}_morningColor'] = null;
    updates['morningBooked'] = false;
    updates['${safeVenue}_morningBooked'] = false;
  }
  if (afternoon) {
    updates['afternoonColor'] = null;
    updates['${safeVenue}_afternoonColor'] = null;
    updates['afternoonBooked'] = false;
    updates['${safeVenue}_afternoonBooked'] = false;
  }

  try {
    await calRef.set(updates, SetOptions(merge: true));
    print('🧹 calendar/$dateKey cleared for $safeVenue (status=$newStatus)');
  } catch (e) {
    print('⚠️ Calendar clear failed for $dateKey/$safeVenue → $e');
  }
}
 // ---------------- ACTIONS ----------------
  Future<void> _approveEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final data = snap.data();
    if (data == null) return;

    await snap.reference.update({
      'status': 'Approved',
      'approvedAt': FieldValue.serverTimestamp(),
      'approvedBy': FirebaseAuth.instance.currentUser?.uid,
    });

    // booking => true
    await _updateBookingByStatus(snap, 'Approved');

    final email = (data['organizerEmail'] ?? '') as String;
    if (email.isNotEmpty) {
      await sendEmail(
        recipientEmail: email,
        subject: 'Event Approved',
        body: 'Dear organizer,\n\nYour event "${data['title']}" has been approved.',
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event approved')));
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

    // booking => false, calendar clear
    await _updateBookingByStatus(snap, 'Completed');
    await _clearCalendarColorIfNegativeStatus(snap, 'Completed');

    final email = (data['organizerEmail'] ?? '') as String;
    if (email.isNotEmpty) {
      await sendEmail(
        recipientEmail: email,
        subject: 'Event Completed',
        body: 'Dear organizer,\n\nYour event "${data['title']}" has been marked as Completed.',
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event marked as Completed')));
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

    // booking => false, calendar clear
    await _updateBookingByStatus(snap, 'Rejected');
    await _clearCalendarColorIfNegativeStatus(snap, 'Rejected');

    final email = (data['organizerEmail'] ?? '') as String;
    if (email.isNotEmpty) {
      await sendEmail(
        recipientEmail: email,
        subject: 'Event Rejected',
        body: 'Dear organizer,\n\nYour event "${data['title']}" was rejected.\nReason: $reason',
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event rejected')));
    }
  }
Future<void> _cancelEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
  final reasonCtrl = TextEditingController();

  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancel Event'),
      content: TextField(
        controller: reasonCtrl,
        decoration: const InputDecoration(hintText: 'Reason for cancellation…'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Back')),
        TextButton(onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()), child: const Text('Cancel Event')),
      ],
    ),
  );

  if (reason == null || reason.isEmpty) return;

  final admin = FirebaseAuth.instance.currentUser;
  final adminEmail = admin?.email ?? '-';
  final adminUid = admin?.uid ?? '-';

  final data = snap.data();
  final venueRaw = (data?['venue'] ?? '') as String;
  final venue = venueRaw.replaceAll(RegExp(r'\s+'), '').trim();
  final safeVenue = venue.isEmpty ? 'UnknownVenue' : venue;

  await snap.reference.update({
    'status': 'Canceled',
    'cancelledAt': FieldValue.serverTimestamp(),
    'cancelledReason': reason,
    'cancelledByUid': adminUid,
    'cancelledByEmail': adminEmail,
  });

  await _updateBookingByStatus(snap, 'Canceled');
  await _clearCalendarColorIfNegativeStatus(snap, 'Canceled');

  final email = (data?['organizerEmail'] ?? '') as String;
  if (email.isNotEmpty) {
    await sendEmail(
      recipientEmail: email,
      subject: 'Event Canceled',
      body:
          'Dear organizer,\n\nYour event "${data?['title'] ?? 'Event'}" has been canceled by admin.\nReason: $reason\n\nBest regards,\nEvent Management System',
    );
    print('📧 Email sent to $email (reason: $reason)');
  } else {
    print('⚠️ No organizerEmail found for event ${data?['title']}');
  }

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Event canceled — booking/calendar updated successfully.')),
    );
  }
}


  Future<void> _revertToPending(DocumentSnapshot<Map<String, dynamic>> snap) async {
    await snap.reference.update({'status': 'Pending'});

    // booking => true
    await _updateBookingByStatus(snap, 'Pending');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event status reverted to Pending')));
    }
  }

  Future<void> _deleteEvent(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final reasonCtrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(hintText: 'Optional: reason for delete…'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Back')),
          TextButton(onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()), child: const Text('Delete')),
        ],
      ),
    );

    await snap.reference.update({
      'status': 'Deleted',
      'deletedAt': FieldValue.serverTimestamp(),
      if (reason != null && reason.isNotEmpty) 'deletedReason': reason,
    });

    // booking => false, calendar clear
    await _updateBookingByStatus(snap, 'Deleted');
    await _clearCalendarColorIfNegativeStatus(snap, 'Deleted');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted, booking/calendar updated')));
    }
  }

  // ---------------- HOUSEKEEPING ----------------
  Future<void> expireApprovedEvents() async {
    final now = DateTime.now();
    try {
      final qs = await FirebaseFirestore.instance
          .collection('events')
          .where('status', isEqualTo: 'Approved')
          .get();
      for (final doc in qs.docs) {
        final data = doc.data();
        final end = (data['endDateTime'] as Timestamp?)?.toDate();
        if (end != null && end.isBefore(now)) {
          await doc.reference.update({'status': 'Expired'});

          // booking => false, calendar clear
          await _updateBookingByStatus(doc, 'Expired');
          await _clearCalendarColorIfNegativeStatus(doc, 'Expired');

          // ignore: avoid_print
          print('⚠️ Event expired: ${data['title'] ?? doc.id}');
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error expiring events: $e');
    }
  }

  Future<void> checkAndSendReminders() async {
    final qs = await FirebaseFirestore.instance
        .collection('events')
        .where('status', isEqualTo: 'Approved')
        .get();
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
          body:
              'Reminder: Your event "${data['title']}" is starting soon (${DateFormat('yyyy-MM-dd HH:mm').format(start.toLocal())}).',
        );
        await doc.reference.update({'reminderSent': true});
      }
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final showCancelledCols = _filter == EventStatusFilter.canceled;
    final showOnlyReason = _filter == EventStatusFilter.rejected;
    final showReason = _filter == EventStatusFilter.canceled || _filter == EventStatusFilter.rejected;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Builder(
          builder: (context) => AdminHomeHeaderDesktop(
            onMenuTap: () => Scaffold.of(context).openEndDrawer(),
            title: 'Events Management',
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
            _buildFilterChips(),
            const SizedBox(height: 8),
            _HeaderRow(
              showCancelledCols: showCancelledCols,
              showOnlyReason: showOnlyReason,
              showReason: showReason,
            ),
            const SizedBox(height: 4),
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
                        final data = snap.data();

                        final start = _parseDate(data['startDateTime']);
                        final formatted = start != null ? DateFormat('yyyy-MM-dd').format(start) : 'N/A';

                        final statusNorm = _normalizedStatus(data['status']);
                        final low = statusNorm.toLowerCase();

                        final reason = () {
                          if (low == 'canceled') {
                            return (data['cancelledReason'] ?? data['canceledReason'] ?? '-') as String;
                          }
                          if (low == 'rejected') {
                            return (data['rejectedReason'] ?? data['rejectReason'] ?? '-') as String;
                          }
                          if (low == 'deleted') {
                            return (data['deletedReason'] ?? '-') as String;
                          }
                          return (data['reason'] ?? '-') as String;
                        }();

                        final cancelledBy =
                            (data['cancelledByName'] ?? data['cancelledByEmail'] ?? data['cancelledByUid'] ?? '-') as String;
                        final cancelledEmail =
                            (data['cancelledEmail'] ?? data['cancelledByEmail'] ?? '-') as String;
                        final cancelledAtTxt = (data['cancelledAt'] is Timestamp)
                            ? DateFormat('yyyy-MM-dd HH:mm').format((data['cancelledAt'] as Timestamp).toDate())
                            : '-';

                        return _EventRow(
                          snap: snap,
                          title: data['title'] ?? 'Untitled',
                          date: formatted,
                          venue: data['venue'] ?? 'N/A',
                          organizer: data['organizerName'] ?? 'N/A',
                          status: statusNorm,
                          organizerEmail: data['organizerEmail'] ?? '',
                          reason: reason,
                          cancelledBy: cancelledBy,
                          cancelledEmail: cancelledEmail,
                          cancelledAt: cancelledAtTxt,
                          showCancelledCols: showCancelledCols,
                          showOnlyReason: showOnlyReason,
                          showReason: showReason,
                          onApprove: _approveEvent,
                          onComplete: _completeEvent,
                          onReject: _rejectEvent,
                          onRevertPending: _revertToPending,
                          onCancel: _cancelEvent,
                          onDelete: _deleteEvent,
                        );
                      },
                    );
                  },
                ),
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
        chip('Canceled', EventStatusFilter.canceled),
        chip('Deleted', EventStatusFilter.deleted),
      ],
    );
  }
}

// ---------------- Header Row (dynamic columns) ----------------
class _HeaderRow extends StatelessWidget {
  final bool showCancelledCols;
  final bool showOnlyReason;
  final bool showReason;

  const _HeaderRow({
    required this.showCancelledCols,
    required this.showOnlyReason,
    required this.showReason,
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
          if (showReason) const Expanded(flex: 2, child: Text('Reason', style: style)),
          if (showCancelledCols && !showOnlyReason) ...const [
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

// ---------------- ROW WIDGET ----------------
class _EventRow extends StatelessWidget {
  final DocumentSnapshot<Map<String, dynamic>> snap;
  final String title, date, venue, organizer, status, organizerEmail, reason;
  final String cancelledBy, cancelledEmail, cancelledAt;
  final bool showCancelledCols;
  final bool showOnlyReason;
  final bool showReason;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onApprove;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onComplete;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onReject;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onRevertPending;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onCancel;
  final void Function(DocumentSnapshot<Map<String, dynamic>> snap) onDelete;

  const _EventRow({
    required this.snap,
    required this.title,
    required this.date,
    required this.venue,
    required this.organizer,
    required this.status,
    required this.organizerEmail,
    required this.reason,
    required this.cancelledBy,
    required this.cancelledEmail,
    required this.cancelledAt,
    required this.showCancelledCols,
    required this.showOnlyReason,
    required this.showReason,
    required this.onApprove,
    required this.onComplete,
    required this.onReject,
    required this.onRevertPending,
    required this.onCancel,
    required this.onDelete,
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
      case 'canceled':
        return Colors.grey;
      case 'deleted':
        return Colors.brown;
      default:
        return Colors.orange; // pending
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = status.toLowerCase() == 'pending';
    final approved = status.toLowerCase() == 'approved';
    final complete = status.toLowerCase() == 'completed';
    final rejected = status.toLowerCase() == 'rejected';
    final canceled = status.toLowerCase() == 'canceled';

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
          if (showReason)
            Expanded(
              flex: 2,
              child: Tooltip(
                message: (reason.isEmpty ? '-' : reason),
                child: Text(
                  (reason.isEmpty ? '-' : reason),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          if (showCancelledCols && !showOnlyReason) ...[
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
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'approve') onApprove(snap);
                  if (val == 'complete') onComplete(snap);
                  if (val == 'reject') onReject(snap);
                  if (val == 'revert') onRevertPending(snap);
                  if (val == 'cancel') onCancel(snap);
                  if (val == 'delete') onDelete(snap);
                },
                itemBuilder: (_) {
                  final items = <PopupMenuEntry<String>>[];

                  if (pending) {
                    items.addAll(const [
                      PopupMenuItem(value: 'approve', child: Text('Approve')),
                      PopupMenuItem(value: 'reject', child: Text('Reject')),
                      PopupMenuItem(value: 'cancel', child: Text('Cancel')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ]);
                  }
                  if (approved) {
                    items.addAll(const [
                      PopupMenuItem(value: 'complete', child: Text('Complete')),
                      PopupMenuItem(value: 'revert', child: Text('Revert to Pending')),
                      PopupMenuItem(value: 'cancel', child: Text('Cancel')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ]);
                  }
                  if (complete) {
                    items.addAll(const [
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ]);
                  }
                  if (rejected) {
                    items.addAll(const [
                      PopupMenuItem(value: 'approve', child: Text('Approve')),
                      PopupMenuItem(value: 'revert', child: Text('Revert to Pending')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ]);
                  }
                  if (canceled) {
                    items.addAll(const [
                      PopupMenuItem(value: 'revert', child: Text('Revert to Pending')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
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
