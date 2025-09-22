import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/add_event_page.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/pages/loginpage.dart';
import 'package:withfbase/widgets/home_header.dart';

class BookingForm extends StatefulWidget {
  const BookingForm({super.key});

  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  String? selectedVenue = 'Main Hall';
  DateTime selectedMonth = DateTime.now();
  DateTime? selectedDate;

  final Set<DateTime> selectedDates = {};
  final Map<DateTime, Set<String>> selectedShifts = {};

  final List<String> venues = ['Main Hall'];
  final List<String> allSlots = ["08:00 AM - 12:00 PM", "02:00 PM - 05:00 PM"];
  List<Map<String, String>> slotData = [];

  final ScrollController _scrollController = ScrollController();

  /// ✅ bookedDates now holds {morning, afternoon, status}
  Map<String, Map<String, dynamic>> bookedDates = {};

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();

    // ✅ Real-time listener
    FirebaseFirestore.instance.collection('booking').snapshots().listen((
      snapshot,
    ) {
      final Map<String, Map<String, bool>> tempBookedDates = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('date') && data['date'] is Timestamp) {
          final timestamp = data['date'] as Timestamp;
          final date = timestamp.toDate();
          final key = "${date.year}-${date.month}-${date.day}";
          tempBookedDates[key] = {
            'morning': data['morning'] ?? false,
            'afternoon': data['afternoon'] ?? false,
          };
        }
      }
      setState(() {
        bookedDates = tempBookedDates;
        _generateSlotData();
      });
    });
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isPastDate(DateTime d) {
    final today = _startOfToday();
    final dateOnly = DateTime(d.year, d.month, d.day);
    return dateOnly.isBefore(today);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _generateSlotData() {
    if (selectedDate == null) return;
    final key =
        "${selectedDate!.year}-${selectedDate!.month}-${selectedDate!.day}";
    final slots = bookedDates[key] ?? {'morning': false, 'afternoon': false};

    slotData = [
      {
        'time': allSlots[0],
        'status': slots['morning'] == true ? 'Booked' : 'Available',
      },
      {
        'time': allSlots[1],
        'status': slots['afternoon'] == true ? 'Booked' : 'Available',
      },
    ];
  }

  void _goToPreviousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
    });
  }

  void _toggleDateSelection(DateTime date) {
    if (_isPastDate(date)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Past dates cannot be booked')),
      );
      return;
    }

    setState(() {
      if (selectedDates.contains(date)) {
        selectedDates.remove(date);
        selectedShifts.remove(date);
      } else {
        selectedDates.add(DateTime(date.year, date.month, date.day));
        selectedShifts[DateTime(date.year, date.month, date.day)] = {};
      }
      selectedDate = date;
      _generateSlotData();
    });
  }

  /// ✅ Halkan ayaan saxay
  Future<void> _bookSelected() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    final validDates = selectedDates.where((d) => !_isPastDate(d)).toList();
    if (validDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select today or future dates')),
      );
      return;
    }

    for (var date in validDates) {
      final shifts = selectedShifts[date] ?? {};
      if (shifts.isEmpty) continue;

      // ✅ Pass all selected shifts at once
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => AddEventPage(
                venue: selectedVenue!,
                date: date,
                timeSlot: shifts.join(
                  ", ",
                ), // e.g. "08:00 AM - 12:00 PM, 02:00 PM - 05:00 PM"
                eventId: '',
                isUserMode: true,
                selectedShifts: shifts.toList(),
                shift:
                    '', // 👉 waa inaad AddEventPage ka dhigtaa inuu qaato list
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _startOfToday();

    return Scaffold(
      body: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 6,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 160)),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Hall Availability Calendar',
                      style: TextStyle(
                        fontSize: 33,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              value: selectedVenue,
                              decoration: const InputDecoration(
                                labelText: 'Select Venue',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  venues
                                      .map(
                                        (venue) => DropdownMenuItem(
                                          value: venue,
                                          child: Text(venue),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedVenue = value;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildCalendarHeader(),
                            const SizedBox(height: 10),
                            _buildCalendarGrid(today),
                            const SizedBox(height: 10),
                            _buildLegend(),
                            const SizedBox(height: 20),
                            _buildSelectedShiftsTable(),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed:
                                  selectedDates.isEmpty ? null : _bookSelected,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize: const Size.fromHeight(45),
                              ),
                              child: const Text(
                                'Book Selected Dates & Shifts',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                const SliverToBoxAdapter(child: FooterPage()),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Builder(
              builder:
                  (context) => HomeHeader(
                    onMenuTap: () => Scaffold.of(context).openEndDrawer(),
                    title: '',
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 12,
      runSpacing: 8,
      children: [
        _legendItem(Colors.white, "Available"),
        _legendItem(Colors.yellow.shade200, "Partially Booked"),
        _legendItem(Colors.red.shade200, "Fully Booked"),
        _legendItem(Colors.blue, "Selected"),
        _legendItem(Colors.grey.shade300, "Unavailable (Past)"),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "${_getMonthName(selectedMonth.month)} ${selectedMonth.year}",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            IconButton(
              onPressed: _goToPreviousMonth,
              icon: const Icon(Icons.arrow_left),
            ),
            IconButton(
              onPressed: _goToNextMonth,
              icon: const Icon(Icons.arrow_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(DateTime today) {
    final daysInMonth = DateUtils.getDaysInMonth(
      selectedMonth.year,
      selectedMonth.month,
    );
    final firstWeekday =
        DateTime(selectedMonth.year, selectedMonth.month, 1).weekday;
    final List<Widget> dayWidgets = [];

    List<String> weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    dayWidgets.addAll(
      weekDays.map(
        (d) => Center(
          child: Text(d, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );

    int offset = firstWeekday % 7;
    for (int i = 0; i < offset; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(selectedMonth.year, selectedMonth.month, day);
      final key = "${date.year}-${date.month}-${date.day}";
      final data = bookedDates[key];

      final bool morningBooked = data?['morning'] ?? false;
      final bool afternoonBooked = data?['afternoon'] ?? false;

      final bool isPast = _isPastDate(date);
      final bool isSelected = selectedDates.any((d) => _isSameDay(d, date));
      final bool isToday = _isSameDay(date, today);

      Color bgColor;
      if (isPast) {
        bgColor = Colors.grey.shade300;
      } else if (isSelected) {
        bgColor = Colors.blue;
      } else if (morningBooked && afternoonBooked) {
        bgColor = Colors.red.shade200; // fully booked
      } else if (morningBooked || afternoonBooked) {
        bgColor = Colors.yellow.shade200; // partially booked
      } else {
        bgColor = Colors.white; // available
      }

      Widget dayBox = Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border:
              isToday
                  ? Border.all(color: Colors.blueAccent, width: 2)
                  : Border.all(color: Colors.grey.shade300, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          day.toString(),
          style: TextStyle(
            color:
                isSelected
                    ? Colors.white
                    : (isPast ? Colors.grey.shade700 : Colors.black),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      dayWidgets.add(
        GestureDetector(
          onTap: isPast ? null : () => _toggleDateSelection(date),
          child: AbsorbPointer(absorbing: isPast, child: dayBox),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildSelectedShiftsTable() {
    if (selectedDates.isEmpty) {
      return const Text(
        "No dates selected.",
        style: TextStyle(color: Colors.grey),
      );
    }

    final futureOrToday = selectedDates.where((d) => !_isPastDate(d)).toList();
    if (futureOrToday.isEmpty) {
      return const Text(
        "No valid (today/future) dates selected.",
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          futureOrToday.map((date) {
            final key = "${date.year}-${date.month}-${date.day}";
            final slots =
                bookedDates[key] ?? {'morning': false, 'afternoon': false};

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${_getMonthName(date.month)} ${date.day}, ${date.year}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children:
                          allSlots.map((slot) {
                            bool isBooked =
                                (slot == allSlots[0]
                                    ? slots['morning']
                                    : slots['afternoon'])!;

                            bool isPastSlot = false;

                            // ✅ Check haddii maanta la joogo
                            if (_isSameDay(date, DateTime.now())) {
                              final now = DateTime.now();

                              if (slot == allSlots[0]) {
                                // Morning slot ends 12:00 PM
                                final end = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  12,
                                  0,
                                );
                                if (now.isAfter(end)) isPastSlot = true;
                              } else if (slot == allSlots[1]) {
                                // Afternoon slot ends 5:00 PM
                                final end = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  17,
                                  0,
                                );
                                if (now.isAfter(end)) isPastSlot = true;
                              }
                            }

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value:
                                      selectedShifts[date]?.contains(slot) ??
                                      false,
                                  onChanged:
                                      (isBooked || isPastSlot)
                                          ? null
                                          : (val) {
                                            setState(() {
                                              final set = selectedShifts[date]!;
                                              if (val == true) {
                                                set.add(slot);
                                              } else {
                                                set.remove(slot);
                                              }
                                            });
                                          },
                                ),
                                Text(
                                  slot +
                                      (isBooked
                                          ? " (Booked)"
                                          : isPastSlot
                                          ? " (Closed)"
                                          : ""),
                                  style: TextStyle(
                                    color:
                                        isBooked || isPastSlot
                                            ? Colors.red
                                            : Colors.black,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
