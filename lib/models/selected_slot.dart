// -----------------------------------------------------------------------------
// multi_select_booking_patch.dart
// -----------------------------------------------------------------------------
// This file shows the updated shared model, AddEventPage (multi-range aware),
// and AvailabilityPage changes so that tapping "Book Selected" routes to
// AddEventPage with a disabled start/end date+time range derived from the user's
// selected days & shifts. All days in the inclusive range are booked; if a day
// inside the range was *not* explicitly selected, both shifts are booked (per
// user choice C: "waa qoraynaa").
// -----------------------------------------------------------------------------

// ==============================
// 1. SHARED MODEL: SelectedSlot
// ==============================
// Put this in: lib/models/selected_slot.dart
// ------------------------------------------
// Represents a single (date, shift) choice from the availability table.
// shiftKey: 'morning' | 'afternoon'
// slotLabel: display string (e.g., '8:00–12:00').

class SelectedSlot {
  final DateTime date;
  final String shiftKey; // 'morning' | 'afternoon'
  final String slotLabel;
  const SelectedSlot({
    required this.date,
    required this.shiftKey,
    required this.slotLabel,
  });
}
