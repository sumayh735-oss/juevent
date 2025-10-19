
// -----------------------------------------------------------------------------
// MycreatedEventsPageDesktop_FULL.dart
// Single-file drop-in page
// - Lists events created by the current user
// - Allows CANCEL on events with status "pending" or "approved"
// - On cancel: updates events.status = "cancelled" + audit fields
// - On cancel: updates booking collection -> only the shift(s) in THIS event
//              (morning 08:00 and/or afternoon 02:00) will be set to false
//              If the event had both shifts, both will be set false.
//              If there are two separate events for the same date, cancelling
//              one will NOT affect the other (because we only touch the shifts
//              present on the cancelled event).
// - No calendar color logic here (focus is on booking=false per user request)
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MycreatedEventsPage extends StatefulWidget {
  const MycreatedEventsPage({super.key});

  @override
  State<MycreatedEventsPage> createState() =>
      MycreatedEventsPageState();
}

class MycreatedEventsPageState
    extends State<MycreatedEventsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const double kHeaderPad = 90;

  final _auth = FirebaseAuth.instance;
  String _statusFilter = 'all'; // all | upcoming | cancelled
  String _search = '';

  // ---------------------------- Firestore Query ----------------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> _query() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    // Your events ordered by start
    return FirebaseFirestore.instance
        .collection('events')
        .where('createdBy', isEqualTo: uid)
        .orderBy('startDateTime')
        .snapshots();
  }

  // ---------------------------- Cancel Flow -------------------------------

  Future<String?> _askCancelReason() async {
    final controller = TextEditingController();
    String? errorText;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) => AlertDialog(
            title: const Text('Provide a reason'),
            content: TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Why are you cancelling this event?',
                errorText: errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Back'),
              ),
              FilledButton.icon(
                onPressed: () {
                  final reason = controller.text.trim();
                  if (reason.isEmpty) {
                    setSt(() => errorText = 'Reason is required');
                    return;
                  }
                  Navigator.pop(ctx, reason);
                },
                icon: const Icon(Icons.check),
                label: const Text('Continue'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _dateKeyFromStart(dynamic startDateTime) {
    DateTime? d;
    if (startDateTime is Timestamp) d = startDateTime.toDate();
    if (startDateTime is String) d = DateTime.tryParse(startDateTime);
    d ??= DateTime.now();
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  bool _hasMorningShift(List<dynamic> shifts) {
    try {
      return shifts.any((s) => s.toString().contains('08:00'));
    } catch (_) {
      return false;
    }
  }

  bool _hasAfternoonShift(List<dynamic> shifts) {
    try {
      return shifts.any((s) => s.toString().contains('02:00'));
    } catch (_) {
      return false;
    }
  }

  Future<void> _setBookingFalseForEvent(
    Map<String, dynamic> eventData,
  ) async {
    final venue = (eventData['venue'] ?? '').toString();
    final dateKey = _dateKeyFromStart(eventData['startDateTime']);
    final shiftsDyn = (eventData['selectedShifts'] ?? []) as List<dynamic>;

    final morning = _hasMorningShift(shiftsDyn);
    final afternoon = _hasAfternoonShift(shiftsDyn);

    final bookingRef =
        FirebaseFirestore.instance.collection('booking').doc(dateKey);

    final payload = <String, dynamic>{
      'date': (eventData['startDateTime'] is Timestamp)
          ? eventData['startDateTime']
          : null,
      'dateKey': dateKey,
      'venue': venue,
      'updatedAt': FieldValue.serverTimestamp(),
      if (morning) 'morning': false,
      if (afternoon) 'afternoon': false,
    };

    await bookingRef.set(payload, SetOptions(merge: true));
  }

  Future<void> _cancelEvent(DocumentReference ref) async {
    // 1) Ask reason
    final reason = await _askCancelReason();
    if (reason == null) return;

    // 2) Confirm
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this event?'),
        content: Text('This will mark the event as "cancelled".\nReason:\n$reason'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      // 3) Transaction to:
      //    - validate status (must be pending or approved)
      //    - update event -> cancelled + audit
      //    - update booking -> set only the shifts of THIS event to false
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data() as Map<String, dynamic>?;
        if (data == null) {
          throw 'Event not found.';
        }

        final currentStatus = (data['status'] ?? '').toString().toLowerCase();
        final allowed = currentStatus == 'pending' || currentStatus == 'approved';
        if (!allowed) {
          throw 'Only pending or approved events can be cancelled.';
        }

        final uid = _auth.currentUser?.uid;
        final userDoc = (uid != null)
            ? await tx.get(FirebaseFirestore.instance.collection('users').doc(uid))
            : null;
        final u = userDoc?.data() as Map<String, dynamic>?;

        tx.update(ref, {
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledByUid': uid,
          'cancelledByName': (u?['username'] ?? _auth.currentUser?.displayName ?? 'Unknown').toString(),
          'cancelledByEmail': (u?['email'] ?? _auth.currentUser?.email ?? '').toString(),
          'cancelledEmail': (u?['email'] ?? _auth.currentUser?.email ?? '').toString(),
          'cancelledReason': reason,
        });

        // booking → set shift(s) of THIS event to false
        final venue = (data['venue'] ?? '').toString();
        final dateKey = _dateKeyFromStart(data['startDateTime']);
        final shiftsDyn = (data['selectedShifts'] ?? []) as List<dynamic>;
        final morning = _hasMorningShift(shiftsDyn);
        final afternoon = _hasAfternoonShift(shiftsDyn);

        final bookingRef =
            FirebaseFirestore.instance.collection('booking').doc(dateKey);

        final payload = <String, dynamic>{
          'dateKey': dateKey,
          'venue': venue,
          'updatedAt': FieldValue.serverTimestamp(),
          if (morning) 'morning': false,
          if (afternoon) 'afternoon': false,
        };

        tx.set(bookingRef, payload, SetOptions(merge: true));
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event cancelled & booking updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ---------------------------- Filters & Helpers --------------------------

  bool _passesFilter(Map<String, dynamic> data) {
    final status = (data['status'] ?? '').toString().toLowerCase();
    final ts = data['startDateTime'];
    final start = (ts is Timestamp)
        ? ts.toDate()
        : (ts is String ? DateTime.tryParse(ts) : null);
    final now = DateTime.now();

    switch (_statusFilter) {
      case 'upcoming':
        return (status != 'cancelled') && (start == null || start.isAfter(now));
      case 'cancelled':
        return status == 'cancelled';
      default:
        return true;
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_search.trim().isEmpty) return true;
    final q = _search.toLowerCase();
    final title = (data['title'] ?? '').toString().toLowerCase();
    final venue = (data['venue'] ?? '').toString().toLowerCase();
    return title.contains(q) || venue.contains(q);
  }

  String _fmtDT(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  // ---------------------------- UI ----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('My events'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    decoration: InputDecoration(
                      labelText: 'Filter',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(
                          value: 'upcoming', child: Text('Upcoming')),
                      DropdownMenuItem(
                          value: 'cancelled', child: Text('Cancelled')),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search title or venue…',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _query(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(
                      child: Text('Could not load your events.'));
                }

                final docs = (snap.data?.docs ?? [])
                    .where((d) => _passesFilter(d.data()))
                    .where((d) => _matchesSearch(d.data()))
                    .toList();

                if (docs.isEmpty) {
                  return const _EmptyState();
                }

                // Ensure ascending by startDateTime
                docs.sort((a, b) {
                  final aStart =
                      (a.data()['startDateTime'] as Timestamp?)?.toDate() ??
                          (a.data()['startDateTime'] is String
                              ? DateTime.tryParse(a.data()['startDateTime'])
                              : null) ??
                          DateTime(2100);
                  final bStart =
                      (b.data()['startDateTime'] as Timestamp?)?.toDate() ??
                          (b.data()['startDateTime'] is String
                              ? DateTime.tryParse(b.data()['startDateTime'])
                              : null) ??
                          DateTime(2100);
                  return aStart.compareTo(bStart);
                });

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data();

                    final status = (data['status'] ?? 'pending')
                        .toString()
                        .toLowerCase();
                    final startTs = data['startDateTime'];
                    final endTs = data['endDateTime'];
                    final start = (startTs is Timestamp)
                        ? startTs.toDate()
                        : (startTs is String
                            ? DateTime.tryParse(startTs)
                            : null);
                    final end = (endTs is Timestamp)
                        ? endTs.toDate()
                        : (endTs is String ? DateTime.tryParse(endTs) : null);

                    final isCancelled = status == 'cancelled';
                    final canCancel =
                        status == 'pending' || status == 'approved';

                    final title = (data['title'] ?? 'Untitled').toString();
                    final venue = (data['venue'] ?? '').toString();
                    final cancelledBy = (data['cancelledByName'] ??
                            data['cancelledByEmail'] ??
                            data['cancelledByUid'] ??
                            '')
                        .toString();
                    final cancelledAtTxt =
                        (data['cancelledAt'] is Timestamp)
                            ? (data['cancelledAt'] as Timestamp)
                                .toDate()
                                .toLocal()
                                .toString()
                            : '';

                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Left icon
                            Container(
                              decoration: BoxDecoration(
                                color: isCancelled
                                    ? const Color(0xFFFFE5E5)
                                    : const Color(0xFFE7E8FD),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Icon(
                                isCancelled
                                    ? Icons.event_busy
                                    : Icons.event_available,
                                size: 24,
                                color: isCancelled
                                    ? const Color(0xFFFF5A5F)
                                    : const Color(0xFF6A5AE0),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Middle info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isCancelled
                                              ? const Color(0xFFFFE5E5)
                                              : const Color(0xFFEDEBFF),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isCancelled
                                              ? 'Cancelled'
                                              : (status.isEmpty
                                                  ? 'Active'
                                                  : status[0].toUpperCase() +
                                                      status.substring(1)),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isCancelled
                                                ? const Color(0xFFFF5A5F)
                                                : const Color(0xFF6A5AE0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.schedule,
                                                size: 16, color: Colors.grey),
                                            const SizedBox(width: 6),
                                            Text(
                                                '${_fmtDT(start)}  →  ${_fmtDT(end)}'),
                                          ]),
                                      if (venue.isNotEmpty)
                                        Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.place,
                                                  size: 16,
                                                  color: Colors.grey),
                                              const SizedBox(width: 6),
                                              Text(venue),
                                            ]),
                                    ],
                                  ),
                                  if (isCancelled) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Reason: ${(data['cancelledReason'] ?? data['canceledReason'] ?? '-').toString()}',
                                      style: const TextStyle(
                                          color: Color(0xFFFF5A5F),
                                          fontStyle: FontStyle.italic),
                                    ),
                                    if (cancelledBy.isNotEmpty)
                                      Text(
                                        'Cancelled by: $cancelledBy${cancelledAtTxt.isNotEmpty ? ' • $cancelledAtTxt' : ''}',
                                        style: TextStyle(
                                            color: Colors.grey.shade700),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Right actions
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (canCancel)
                                  ElevatedButton.icon(
                                    onPressed: () => _cancelEvent(doc.reference),
                                    icon: const Icon(Icons.cancel),
                                    label: const Text('Cancel'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFFFF5A5F),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                      textStyle: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      elevation: 1.5,
                                    ),
                                  ),
                                if (!canCancel && isCancelled)
                                  const Text(
                                    'This event is cancelled',
                                    style: TextStyle(
                                        color: Color(0xFFFF5A5F),
                                        fontWeight: FontWeight.w600),
                                  ),
                              ],
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
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Center(
        child: Column(
          children: const [
            Icon(Icons.event_note, size: 40, color: Color(0xFF6A5AE0)),
            SizedBox(height: 14),
            Text(
              'You have not created any events yet.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              'When you create an event, it will appear here.',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
