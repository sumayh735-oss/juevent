import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:withfbase/pages/add_event_page.dart';
import 'package:withfbase/models/selected_slot.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/widgets/app_drawer.dart';
import 'package:withfbase/widgets/home_header.dart';

class AvailabilityPage extends StatefulWidget {
  final bool isLoggedIn;
  final String? venueName; // optional external venue
  const AvailabilityPage({super.key, required this.isLoggedIn, this.venueName});
  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  static const String morningLabel = '8:00–12:00';
  static const String afternoonLabel = '2:00–5:00';
  bool showOnlyAvailable = true;
  String get selectedVenue => widget.venueName ?? 'Main Hall';

  late Future<List<DayAvailability>> _futureDays;
  final Map<String, Map<String, bool>> _userSelections =
      {}; // dateKey => {morning,afternoon}

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

  Future<List<DayAvailability>> _loadDays() async {
    final now = DateTime.now();
    final twoMonthsLater = DateTime(now.year, now.month + 2, now.day);
    final snapshot =
        await FirebaseFirestore.instance.collection('booking').get();

    final Map<String, Map<String, bool>> bookedMap = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      String? key;
      if (data['date'] is Timestamp) {
        final dt = (data['date'] as Timestamp).toDate();
        key = _dateKey(dt);
      } else {
        key = doc.id;
      }
      final morning = data['morning'] == true;
      final afternoon = data['afternoon'] == true;
      bookedMap[key] = {'morning': morning, 'afternoon': afternoon};
    }

    final totalDays = twoMonthsLater.difference(now).inDays;
    final List<DayAvailability> rows = [];
    for (int i = 0; i <= totalDays; i++) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(Duration(days: i));
      final key = _dateKey(date);
      final data = bookedMap[key] ?? {'morning': false, 'afternoon': false};
      rows.add(
        DayAvailability(
          date: date,
          morningBooked: data['morning'] ?? false,
          afternoonBooked: data['afternoon'] ?? false,
        ),
      );
    }
    return rows;
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
    final map = _userSelections.putIfAbsent(
      k,
      () => {'morning': false, 'afternoon': false},
    );
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
    final List<SelectedSlot> out = [];
    final mapByKey = {for (final r in rows) _dateKey(r.date): r};
    _userSelections.forEach((k, m) {
      final row = mapByKey[k];
      if (row == null) return;
      if (m['morning'] == true && !row.morningBooked) {
        out.add(
          SelectedSlot(
            date: row.date,
            shiftKey: 'morning',
            slotLabel: morningLabel,
          ),
        );
      }
      if (m['afternoon'] == true && !row.afternoonBooked) {
        out.add(
          SelectedSlot(
            date: row.date,
            shiftKey: 'afternoon',
            slotLabel: afternoonLabel,
          ),
        );
      }
    });
    return out;
  }

  // shift ordering / datetimes (same mapping as AddEventPage)
  int _shiftOrder(String k) => k == 'afternoon' ? 1 : 0;
  DateTime _shiftStart(DateTime d, String k) =>
      k == 'afternoon'
          ? DateTime(d.year, d.month, d.day, 14, 0)
          : DateTime(d.year, d.month, d.day, 8, 0);
  DateTime _shiftEnd(DateTime d, String k) =>
      k == 'afternoon'
          ? DateTime(d.year, d.month, d.day, 17, 0)
          : DateTime(d.year, d.month, d.day, 12, 0);

  // -----------------
  // BOOK SELECTED -> AddEventPage
  // -----------------
  Future<void> _bookSelected(List<DayAvailability> rows) async {
    final sel = _buildSelectedSlotsPayload(rows);
    if (sel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ma jiraan shifts la doortay.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fadlan login samee ka hor booking.')),
      );
      return;
    }

    // sort to derive range
    sel.sort((a, b) {
      final int cmp = a.date.compareTo(b.date);
      if (cmp != 0) return cmp;
      return _shiftOrder(a.shiftKey).compareTo(_shiftOrder(b.shiftKey));
    });
    final start = _shiftStart(sel.first.date, sel.first.shiftKey);
    final end = _shiftEnd(sel.last.date, sel.last.shiftKey);

    final timeSlotLabel =
        '${DateFormat.jm().format(start)} – ${DateFormat.jm().format(end)}';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddEventPage(
              startDate: start,
              endDate: end,
              selectedSlots: sel,
              venue: selectedVenue,
              date: start, // legacy param
              timeSlot: timeSlotLabel,
              eventId: '', // new create
              isUserMode: true, // disable fields
              shift: sel.length == 1 ? sel.first.slotLabel : 'Multi',
              selectedShifts: [],
            ),
      ),
    );

    await _refresh();
  }

  // -----------------
  // Legacy single-day quick booking
  // -----------------
  Future<void> _bookSingle(DayAvailability day, {required bool morning}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login required.')));
      return;
    }

    final shiftKey = morning ? 'morning' : 'afternoon';
    final shiftLabel = morning ? morningLabel : afternoonLabel;

    // Pre-mark the shift doc (optional; can remove if you prefer to mark after create)
    final dateStr = _dateKey(day.date);
    await FirebaseFirestore.instance.collection('booking').doc(dateStr).set({
      shiftKey: true,
      'date': Timestamp.fromDate(day.date),
    }, SetOptions(merge: true));

    final start = _shiftStart(day.date, shiftKey);
    final end = _shiftEnd(day.date, shiftKey);
    final timeSlotLabel =
        '${DateFormat.jm().format(start)} – ${DateFormat.jm().format(end)}';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => AddEventPage(
              startDate: start,
              endDate: end,
              selectedSlots: [
                SelectedSlot(
                  date: day.date,
                  shiftKey: shiftKey,
                  slotLabel: shiftLabel,
                ),
              ],
              venue: selectedVenue,
              date: day.date,
              timeSlot: timeSlotLabel,
              eventId: '',
              isUserMode: true,
              shift: shiftLabel,
              selectedShifts: [],
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
      body: Column(
        children: [
          Builder(
            builder:
                (context) => HomeHeader(
                  onMenuTap: () => Scaffold.of(context).openEndDrawer(),
                  title: '',
                ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              '📅 Available Days & 🕒 Shifts',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Switch(
                value: showOnlyAvailable,
                onChanged: (val) => setState(() => showOnlyAvailable = val),
              ),
              Text(
                showOnlyAvailable ? 'Only available' : 'Show all (incl. full)',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<DayAvailability>>(
              future: _futureDays,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data found.'));
                }

                final rows = snapshot.data!;
                final filtered =
                    showOnlyAvailable
                        ? rows.where((r) => !r.isFull).toList()
                        : rows;

                return Column(
                  children: [
                    Expanded(child: _buildDataTable(filtered)),
                    _buildSelectionSummaryFooter(rows),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          const FooterPage(),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<DayAvailability> data) {
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 700),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.blue.shade100),
              columnSpacing: 24,
              horizontalMargin: 16,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 72,
              border: TableBorder.all(color: Colors.grey.shade300),
              columns: const [
                DataColumn(
                  label: Text(
                    '📅 Date',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Morning\n8:00–12:00',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Afternoon\n2:00–5:00',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Action',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows:
                  data.map((day) {
                    final dateStr = DateFormat('EEE, dd MMM').format(day.date);
                    final isToday =
                        day.date.day == now.day &&
                        day.date.month == now.month &&
                        day.date.year == now.year;
                    final k = _dateKey(day.date);
                    final sel = _userSelections[k];

                    Widget morningCell;
                    if (day.morningBooked) {
                      morningCell = const Text(
                        '❌',
                        style: TextStyle(color: Colors.redAccent),
                      );
                    } else {
                      morningCell = Checkbox(
                        value: sel?['morning'] == true,
                        onChanged: (_) => _toggleDayShift(day, 'morning'),
                      );
                    }

                    Widget afternoonCell;
                    if (day.afternoonBooked) {
                      afternoonCell = const Text(
                        '❌',
                        style: TextStyle(color: Colors.redAccent),
                      );
                    } else {
                      afternoonCell = Checkbox(
                        value: sel?['afternoon'] == true,
                        onChanged: (_) => _toggleDayShift(day, 'afternoon'),
                      );
                    }

                    Widget actionCell;
                    if (day.isFull) {
                      actionCell = const Text(
                        '-',
                        style: TextStyle(color: Colors.grey),
                      );
                    } else {
                      actionCell = Wrap(
                        spacing: 4,
                        children: [
                          if (!day.morningBooked)
                            ElevatedButton(
                              onPressed: () => _bookSingle(day, morning: true),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                              child: const Text('Book AM'),
                            ),
                          if (!day.afternoonBooked)
                            ElevatedButton(
                              onPressed: () => _bookSingle(day, morning: false),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                              child: const Text('Book PM'),
                            ),
                          if (sel != null &&
                              (sel['morning'] == true ||
                                  sel['afternoon'] == true))
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              tooltip: 'Clear selection',
                              onPressed: () => _clearSelectionForDay(day),
                            ),
                        ],
                      );
                    }

                    return DataRow(
                      color: WidgetStateProperty.all(
                        isToday ? Colors.lightBlue.shade50 : null,
                      ),
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              if (isToday)
                                const Icon(
                                  Icons.today,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                              if (isToday) const SizedBox(width: 4),
                              Text(dateStr),
                            ],
                          ),
                        ),
                        DataCell(Center(child: morningCell)),
                        DataCell(Center(child: afternoonCell)),
                        DataCell(actionCell),
                      ],
                    );
                  }).toList(),
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
        color: Colors.blueGrey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available,
                size: 18,
                color: Colors.blueGrey,
              ),
              const SizedBox(width: 6),
              Text('Selected: $total shift${total == 1 ? '' : 's'}'),
              const Spacer(),
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: hasSel ? () => _bookSelected(rows) : null,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Book Selected'),
                ),
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
                  return Chip(label: Text('$shortDate $shortShift'));
                }),
                if (remaining > 0) Chip(label: Text('+$remaining more')),
              ],
            ),
        ],
      ),
    );
  }
}

// ----------------
// Day availability
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
