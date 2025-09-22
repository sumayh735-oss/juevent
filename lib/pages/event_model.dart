import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String status;
  final String venue;
  final String description;
  final String category;
  final String imageUrl;
  final String organizerName;
  final String organizerEmail;
  final String businessDocumentUrl;
  final bool reminderSent;
  final int seats;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final DateTime createdAt;
  final DateTime approvedAt;
  final String approvedBy;
  // 🔹 Fields cusub
  final String? time;
  final String? tag;

  EventModel({
    required this.id,
    required this.title,
    required this.status,
    required this.venue,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.organizerName,
    required this.organizerEmail,
    required this.businessDocumentUrl,
    required this.reminderSent,
    required this.seats,
    required this.startDateTime,
    required this.endDateTime,
    required this.createdAt,
    required this.approvedAt,
    required this.approvedBy,
    this.tag,
    this.time,
  });

  factory EventModel.fromMap(Map<String, dynamic> data, String id) {
    return EventModel(
      id: id,
      title: data['title'] ?? '',
      status: data['status'] ?? '',
      venue: data['venue'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      organizerName: data['organizerName'] ?? '',
      organizerEmail: data['organizerEmail'] ?? '',
      businessDocumentUrl: data['businessDocumentUrl'] ?? '',
      reminderSent: data['reminderSent'] ?? false,
      seats: (data['seats'] ?? 0) is int ? data['seats'] : 0,
      startDateTime:
          data['startDateTime'] != null
              ? (data['startDateTime'] as Timestamp).toDate()
              : DateTime.now(),
      endDateTime:
          data['endDateTime'] != null
              ? (data['endDateTime'] as Timestamp).toDate()
              : DateTime.now().add(const Duration(hours: 1)),
      createdAt:
          data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      approvedAt:
          data['approvedAt'] != null
              ? (data['approvedAt'] as Timestamp).toDate()
              : DateTime.now(),
      approvedBy: data['approvedBy'] ?? '',
      // 🔹 Cusub
      time: data['time'],
      tag: data['tag'],
    );
  }
}
