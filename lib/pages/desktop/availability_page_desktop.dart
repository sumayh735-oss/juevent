import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:withfbase/models/selected_slot.dart';
import 'package:withfbase/pages/desktop/add_event_page_desktop.dart';
import 'package:withfbase/pages/desktop/home_header_desktop.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/widgets/app_drawer.dart';

class AvailabilityPageDesktop extends StatefulWidget {
  final bool isLoggedIn;
  final String? venueName; // optional external venue

  const AvailabilityPageDesktop({
    super.key,
    required this.isLoggedIn,
    this.venueName,
  });

  @override
  State<AvailabilityPageDesktop> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPageDesktop> {
  static const String morningLabel = '8:00–12:00';
  static const String afternoonLabel = '2:00–5:00';

  bool showOnlyAvailable = true;
  String get selectedVenue => widget.venueName ?? 'Main Hall';

  late Future<List<DayAvailability>> _futureDays;
  // dateKey => {morning, afternoon}
  final Map<String, Map<String, bool>> _userSelections = {};

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void initState() {
    super.initState();
    _futureDays = _loadDays();
  }

  Future<void> _refresh() async {
    setState(() {
      _futureDays = _loadDays();
    });
  }

  /// Soo saar 60 maalmood ee soo socda (2 bilood) maanta laga bilaabo.
  Future<List<DayAvailability>> _loadDays() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    // 60 maalmood forward = ~ 2 months
    final end = start.add(const Duration(days: 60));

    // akhri doc-yada booking (hal collection: 'booking')
    final snapshot = await FirebaseFirestore.instance.collection('booking').get();

    final Map<String, Map<String, bool>> booked = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      String key;
      if (data['date'] is Timestamp) {
        key = _dateKey((data['date'] as Timestamp).toDate());
      } else {
        key = doc.id; // fallback
      }
      booked[key] = {
        'morning': data['morning'] == true,
        'afternoon': data['afternoon'] == true,
      };
    }

    final List<DayAvailability> out = [];
    for (DateTime d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
      final key = _dateKey(d);
      final flags = booked[key] ?? const {'morning': false, 'afternoon': false};
      out.add(DayAvailability(
        date: d,
        morningBooked: flags['morning'] ?? false,
        afternoonBooked: flags['afternoon'] ?? false,
      ));
    }
    return out;
  }

  // -----------------
  // Selection helpers
  // -----------------
  void _toggleDayShift(DayAvailability day, String shiftKey) {
    if ((shiftKey == 'morning' && day.morningBooked) ||
        (shiftKey == 'afternoon' && day.afternoonBooked)) {
      return; // ignore booked
    }
    final k = _dateKey(day.date);
    final map = _userSelections.putIfAbsent(k, () => {'morning': false, 'afternoon': false});
    map[shiftKey] = !(map[shiftKey] ?? false);
    setState(() {});
  }

  void _clearSelectionForDay(DayAvailability day) {
    _userSelections.remove(_dateKey(day.date));
    setState(() {});
  }

  int _selectedShiftCount() {
    int c = 0;
    _userSelections.forEach((_, m) {
      if (m['morning'] == true) c++;
      if (m['afternoon'] == true) c++;
    });
    return c;
  }

  List<SelectedSlot> _buildSelectedSlotsPayload(List<DayAvailability> rows) {
    final mapByKey = {for (final r in rows) _dateKey(r.date): r};
    final out = <SelectedSlot>[];

    _userSelections.forEach((k, m) {
      final row = mapByKey[k];
      if (row == null) return;
      if (m['morning'] == true && !row.morningBooked) {
        out.add(SelectedSlot(date: row.date, shiftKey: 'morning', slotLabel: morningLabel));
      }
      if (m['afternoon'] == true && !row.afternoonBooked) {
        out.add(SelectedSlot(date: row.date, shiftKey: 'afternoon', slotLabel: afternoonLabel));
      }
    });
    return out;
  }

  int _shiftOrder(String k) => k == 'afternoon' ? 1 : 0;
  DateTime _shiftStart(DateTime d, String k) =>
      k == 'afternoon' ? DateTime(d.year, d.month, d.day, 14) : DateTime(d.year, d.month, d.day, 8);
  DateTime _shiftEnd(DateTime d, String k) =>
      k == 'afternoon' ? DateTime(d.year, d.month, d.day, 17) : DateTime(d.year, d.month, d.day, 12);

  // -----------------
  // BOOK SELECTED -> AddEventPage
  // -----------------
  Future<void> _bookSelected(List<DayAvailability> rows) async {
    final sel = _buildSelectedSlotsPayload(rows);
    if (sel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ma jiraan shifts la doortay.')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fadlan login samee ka hor booking.')));
      return;
    }

    sel.sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : _shiftOrder(a.shiftKey).compareTo(_shiftOrder(b.shiftKey));
    });

    final start = _shiftStart(sel.first.date, sel.first.shiftKey);
    final end = _shiftEnd(sel.last.date, sel.last.shiftKey);
    final timeSlotLabel = '${DateFormat.jm().format(start)} – ${DateFormat.jm().format(end)}';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEventPageDesktop(
          startDate: start,
          endDate: end,
          selectedSlots: sel,
          venue: selectedVenue,
          date: start, // legacy
          timeSlot: timeSlotLabel,
          eventId: '',
          isUserMode: true,
          shift: sel.length == 1 ? sel.first.slotLabel : 'Multi',
          selectedShifts: const [],
        ),
      ),
    );

    await _refresh();
  }

  // Legacy single-day quick booking
  Future<void> _bookSingle(DayAvailability day, {required bool morning}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login required.')));
      return;
    }

    final shiftKey = morning ? 'morning' : 'afternoon';
    final shiftLabel = morning ? morningLabel : afternoonLabel;

    final dateStr = _dateKey(day.date);
    await FirebaseFirestore.instance.collection('booking').doc(dateStr).set({
      shiftKey: true,
      'date': Timestamp.fromDate(day.date),
    }, SetOptions(merge: true));

    final start = _shiftStart(day.date, shiftKey);
    final end = _shiftEnd(day.date, shiftKey);
    final timeSlotLabel = '${DateFormat.jm().format(start)} – ${DateFormat.jm().format(end)}';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEventPageDesktop(
          startDate: start,
          endDate: end,
          selectedSlots: [
            SelectedSlot(date: day.date, shiftKey: shiftKey, slotLabel: shiftLabel),
          ],
          venue: selectedVenue,
          date: day.date,
          timeSlot: timeSlotLabel,
          eventId: '',
          isUserMode: true,
          shift: shiftLabel,
          selectedShifts: const [],
        ),
      ),
    );

    await _refresh();
  }

  // -----------------
  // BUILD
  // -----------------
  @override

Widget build(BuildContext context) {
  return Scaffold(
    endDrawer: AppDrawer(
      role: "user",
      currentIndex: 0,
      onItemSelected: (index) {},
      isLoggedIn: widget.isLoggedIn,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Builder(
              builder: (context) => HomeHeaderDesktop(
                onMenuTap: () => Scaffold.of(context).openEndDrawer(),
                title: '',
              ),
            ),
            const SizedBox(height: 8),

            // Top controls
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('📅 Available Days & 🕒 Shifts',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Available only')),
                          ButtonSegment(value: false, label: Text('All days')),
                        ],
                        selected: {showOnlyAvailable},
                        onSelectionChanged: (s) => setState(() => showOnlyAvailable = s.first),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _LegendBar(),
            const SizedBox(height: 6),

            // CONTENT (no Expanded) – wax walba wuu la rogi karaa
            FutureBuilder<List<DayAvailability>>(
              future: _futureDays,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _emptyCard('No data found.');
                }

                final rows = snapshot.data!;
                final shown = showOnlyAvailable
                    ? rows.where((r) => !r.isFull).toList()
                    : rows;

                if (shown.isEmpty) {
                  return _emptyCard('All days are fully booked in the next 60 days.');
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      children: [
                        _buildPrettyTable(shown),            // ← no Expanded
                        _buildSelectionSummaryFooter(rows),   // ← footer-ka xulashada
                      ],
                    ),
                  ),
                );
              },
            ),

            // Site footer – hadda qayb ka ah scroll-ka, overflow ma jiro
            const FooterPage(),
          ],
        ),
      ),
    ),
  );
}

// helper yar oo kaarar fariin ah ku soo bandhiga
Widget _emptyCard(String msg) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
    child: Card(
      elevation: 0,
      color: Colors.indigo.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.indigo),
            const SizedBox(width: 10),
            Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    ),
  );
}
  // --- Pretty table card ---
  Widget _buildPrettyTable(List<DayAvailability> data) {
    final now = DateTime.now();

    return Card(
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 760),
            child: SingleChildScrollView(
              child: DataTable(
                headingRowHeight: 48,
                dataRowMinHeight: 58,
                dataRowMaxHeight: 72,
                columnSpacing: 28,
                horizontalMargin: 16,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
                headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade200),
                ),
                columns: const [
                  DataColumn(label: _HeadingCell(icon: Icons.event, text: 'Date')),
                  DataColumn(label: _HeadingCell(icon: Icons.wb_sunny, text: 'Morning')),
                  DataColumn(label: _HeadingCell(icon: Icons.wb_twilight, text: 'Afternoon')),
                  DataColumn(label: _HeadingCell(icon: Icons.more_horiz, text: 'Action')),
                ],
                rows: data.map((day) {
                  final dateStr = DateFormat('EEE, dd MMM').format(day.date);
                  final isToday = DateUtils.isSameDay(day.date, now);
                  final key = _dateKey(day.date);
                  final sel = _userSelections[key];

                  Widget am = _ShiftChip(
                    label: 'AM',
                    booked: day.morningBooked,
                    selected: sel?['morning'] == true,
                    onTap: () => _toggleDayShift(day, 'morning'),
                  );

                  Widget pm = _ShiftChip(
                    label: 'PM',
                    booked: day.afternoonBooked,
                    selected: sel?['afternoon'] == true,
                    onTap: () => _toggleDayShift(day, 'afternoon'),
                  );

                  Widget actions;
                  if (day.isFull) {
                    actions = const Text('-', style: TextStyle(color: Colors.grey));
                  } else {
                    actions = Wrap(
                      spacing: 6,
                      children: [
                        if (!day.morningBooked)
                          OutlinedButton(
                            onPressed: () => _bookSingle(day, morning: true),
                            child: const Text('Book AM'),
                          ),
                        if (!day.afternoonBooked)
                          OutlinedButton(
                            onPressed: () => _bookSingle(day, morning: false),
                            child: const Text('Book PM'),
                          ),
                        if (sel != null && (sel['morning'] == true || sel['afternoon'] == true))
                          IconButton(
                            tooltip: 'Clear selection',
                            icon: const Icon(Icons.clear),
                            onPressed: () => _clearSelectionForDay(day),
                          ),
                      ],
                    );
                  }

                  return DataRow(
                    color: WidgetStateProperty.resolveWith((_) {
                      if (isToday) return Colors.lightBlue.shade50;
                      if (day.date.weekday == DateTime.saturday ||
                          day.date.weekday == DateTime.sunday) {
                        return Colors.grey.shade50;
                      }
                      return null;
                    }),
                    cells: [
                      DataCell(Row(
                        children: [
                          if (isToday)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.today, color: Colors.redAccent, size: 18),
                            ),
                          Text(dateStr),
                        ],
                      )),
                      DataCell(am),
                      DataCell(pm),
                      DataCell(actions),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionSummaryFooter(List<DayAvailability> rows) {
    final total = _selectedShiftCount();
    final hasSel = total > 0;
    final selSlots = _buildSelectedSlotsPayload(rows);
    final preview = selSlots.take(4).toList();
    final remaining = selSlots.length - preview.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_available, size: 18, color: Colors.indigo),
                  const SizedBox(width: 6),
                  Text('Selected: $total shift${total == 1 ? '' : 's'}'),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: hasSel ? () => _bookSelected(rows) : null,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Book Selected'),
                  ),
                ],
              ),
              if (hasSel) const SizedBox(height: 8),
              if (hasSel)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...preview.map((s) {
                      final shortDate = DateFormat('MM/dd').format(s.date);
                      final shortShift = s.shiftKey == 'morning' ? 'AM' : 'PM';
                      return Chip(
                        label: Text('$shortDate $shortShift'),
                        backgroundColor: Colors.white,
                        shape: StadiumBorder(side: BorderSide(color: Colors.indigo.shade200)),
                      );
                    }),
                    if (remaining > 0) Chip(label: Text('+$remaining more')),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== Small UI helpers ===================

class _HeadingCell extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeadingCell({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: Colors.black54),
      const SizedBox(width: 6),
      Text(text),
    ]);
  }
}

class _ShiftChip extends StatelessWidget {
  final String label;
  final bool booked;
  final bool selected;
  final VoidCallback onTap;

  const _ShiftChip({
    required this.label,
    required this.booked,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (booked) {
      return Chip(
        avatar: const Icon(Icons.lock, size: 16, color: Colors.white),
        label: const Text('Booked', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey,
        shape: const StadiumBorder(),
      );
    }
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text(label),
      showCheckmark: true,
      selectedColor: Colors.indigo.shade100,
      shape: const StadiumBorder(),
    );
  }
}

class _LegendBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Wrap(
            spacing: 12,
            runSpacing: 6,
            children: const [
              _LegendItem(color: Colors.green, icon: Icons.check_circle, text: 'Available'),
              _LegendItem(color: Colors.grey, icon: Icons.lock, text: 'Booked'),
              _LegendItem(color: Colors.redAccent, icon: Icons.today, text: 'Today'),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;
  const _LegendItem({required this.color, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(text),
      backgroundColor: Colors.grey.shade100,
      shape: const StadiumBorder(),
    );
  }
}

// ----------------
// Day availability model
// ----------------
class DayAvailability {
  final DateTime date;
  final bool morningBooked;
  final bool afternoonBooked;

  const DayAvailability({
    required this.date,
    required this.morningBooked,
    required this.afternoonBooked,
  });

  bool get isFull => morningBooked && afternoonBooked;
}
