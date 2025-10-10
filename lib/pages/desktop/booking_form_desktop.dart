import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/add_event_page.dart';
import 'package:withfbase/pages/desktop/home_header_desktop.dart';
import 'package:withfbase/pages/footer.dart';
import 'package:withfbase/pages/loginpage.dart';

class BookingFormDesktop extends StatefulWidget {
  const BookingFormDesktop({super.key});

  @override
  State<BookingFormDesktop> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingFormDesktop> {
  String? selectedVenue = 'Main Hall';
  DateTime selectedMonth = DateTime.now();
  DateTime? selectedDate;

  final Set<DateTime> selectedDates = {};
  final Map<DateTime, Set<String>> selectedShifts = {};

  final List<String> venues = ['Main Hall'];
  final List<String> allSlots = ["08:00 AM - 12:00 PM", "02:00 PM - 05:00 PM"];
  List<Map<String, String>> slotData = [];

  final ScrollController _scrollController = ScrollController();
  Map<String, Map<String, bool>> bookedDates = {};

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();

    /// ✅ Listen to booking collection (realtime updates to calendar)
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

    /// ✅ Listen to events collection → auto update booking
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

  // ✅ Qaado maalinta ugu horeysa si AddEventPage uu u helo date/time default
  final firstDate = validDates.first;
  final firstShifts = selectedShifts[firstDate]?.toList() ?? [];

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddEventPage(
        venue: selectedVenue!,
        date: firstDate,
        timeSlot: firstShifts.join(", "),
        eventId: '',
        isUserMode: true,
        shift: '',
        selectedShifts: firstShifts,

        // ✅ dir dhammaan maalmaha iyo shifts map si loo process gareeyo
        validDates: validDates,
        selectedShiftsMap: selectedShifts,
      ),
    ),
  );
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
              const SliverToBoxAdapter(child: SizedBox(height: 80)),

              /// 🔹 Title (margin left/right)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 350),
                  child: Text(
                    'Hall Availability Calendar',
                    style: TextStyle(
                      fontSize: 33,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              /// 🔹 Calendar Box (margin same as title)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 350),
                  child: Container(
                    padding: const EdgeInsets.all(24),
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
                          items: venues.map(
                            (venue) => DropdownMenuItem(
                              value: venue,
                              child: Text(venue),
                            ),
                          ).toList(),
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
                        const SizedBox(height: 20),

                        _buildLegend(),
                        const SizedBox(height: 20),

                        _buildSelectedShiftsTable(),
                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: selectedDates.isEmpty ? null : _bookSelected,
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
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(child: FooterPage()),
            ],
          ),
        ),

        /// 🔹 Fixed Header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Builder(
            builder: (context) => HomeHeaderDesktop(
              onMenuTap: () => Scaffold.of(context).openEndDrawer(), title: 'Booking Form',
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
      final status = bookedDates[key];
      bool morningBooked = status?['morning'] ?? false;
      bool afternoonBooked = status?['afternoon'] ?? false;

      final bool isPast = _isPastDate(date);
      final bool isSelected = selectedDates.any((d) => _isSameDay(d, date));

      Color bgColor;
      if (isPast) {
        bgColor =  const Color.fromARGB(255, 143, 142, 142);
      } else if (!morningBooked && !afternoonBooked) {
        bgColor = Colors.white;
      } else if (morningBooked && afternoonBooked) {
        bgColor = Colors.red.shade200;
      } else {
        bgColor = Colors.yellow.shade200;
      }

      final bool isToday = _isSameDay(date, today);

      Widget dayBox = Container(
  margin: const EdgeInsets.all(2), // 🔹 spacing yar
  padding: const EdgeInsets.all(4), // 🔹 gudaha yar
  constraints: const BoxConstraints(
    minWidth: 28, // 🔹 ballac yar
    minHeight: 28, // 🔹 dherer yar
  ),
  decoration: BoxDecoration(
    color: isSelected ? Colors.blue : bgColor,
    borderRadius: BorderRadius.circular(4),
    border: isToday
        ? Border.all(color: Colors.blueAccent, width: 2)
        : Border.all(color: Colors.grey.shade300, width: 1),
  ),
  alignment: Alignment.center,
  child: Text(
    day.toString(),
    style: TextStyle(
      fontSize: 12, // nambarka yar
      color: isSelected
          ? Colors.white
          : (isPast ? Colors.grey.shade700 : Colors.black),
      fontWeight: FontWeight.w500,
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
  crossAxisSpacing: 2,
  mainAxisSpacing: 2,
  childAspectRatio: 2.5, // ballac ka badan dherer (flat look)
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
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value:
                                      selectedShifts[date]?.contains(slot) ??
                                      false,
                                  onChanged:
                                      isBooked
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
                                  slot + (isBooked ? " (Booked)" : ""),
                                  style: TextStyle(
                                    color: isBooked ? Colors.red : Colors.black,
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
