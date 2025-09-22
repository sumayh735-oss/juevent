// lib/services/event_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventService {
  static Future<List<Map<String, String>>> fetchSlotData(
    DateTime date,
    String venue,
  ) async {
    final firestore = FirebaseFirestore.instance;

    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59);

    final querySnapshot =
        await firestore
            .collection('events')
            .where('venue', isEqualTo: venue)
            .where('startDate', isLessThanOrEqualTo: endOfDay)
            .where('endDate', isGreaterThanOrEqualTo: startOfDay)
            .get();

    final bookedSlots =
        querySnapshot.docs.map((doc) {
          final startDate = (doc['startDate'] as Timestamp).toDate();
          final endDate = (doc['endDate'] as Timestamp).toDate();
          final startTime = _parseTime(doc['startTime']);
          final endTime = _parseTime(doc['endTime']);

          final start = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
            startTime.hour,
            startTime.minute,
          );
          final end = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            endTime.hour,
            endTime.minute,
          );

          return {
            "start": start.toIso8601String(),
            "end": end.toIso8601String(),
          };
        }).toList();

    final predefinedSlots = [
      {"time": "08:00 AM - 10:00 AM", "start": 8, "end": 10},
      {"time": "10:00 AM - 12:00 PM", "start": 10, "end": 12},
      {"time": "12:00 PM - 02:00 PM", "start": 12, "end": 14},
      {"time": "02:00 PM - 04:00 PM", "start": 14, "end": 16},
    ];

    return predefinedSlots.map((slot) {
      final slotStart = DateTime(
        date.year,
        date.month,
        date.day,
        slot['start'] as int,
      );
      final slotEnd = DateTime(
        date.year,
        date.month,
        date.day,
        slot['end'] as int,
      );

      final isBooked = bookedSlots.any((booking) {
        final bookingStart = DateTime.parse(booking['start']!);
        final bookingEnd = DateTime.parse(booking['end']!);
        return slotStart.isBefore(bookingEnd) && slotEnd.isAfter(bookingStart);
      });

      return {
        "time": slot["time"] as String,
        "status": isBooked ? "Booked" : "Available",
      };
    }).toList();
  }

  static TimeOfDay _parseTime(String timeString) {
    final format = DateFormat.jm();
    final dt = format.parse(timeString);
    return TimeOfDay.fromDateTime(dt);
  }
}
