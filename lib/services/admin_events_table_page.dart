// // -----------------------------------------------------------------------------
// // admin_events_table_page.dart (UPDATED - No Delete Option)
// // -----------------------------------------------------------------------------
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:mailer/mailer.dart';
// import 'package:mailer/smtp_server.dart';
// import 'package:withfbase/widgets/home_header.dart';
// import 'package:withfbase/pages/add_event_page.dart';
// import 'package:withfbase/pages/footer.dart';

// // -----------------------------------------------------------------------------
// // SMTP Email Helper
// // -----------------------------------------------------------------------------
// Future<void> sendEmail({
//   required String recipientEmail,
//   required String subject,
//   required String body,
// }) async {
//   const String username = 'sumayh735@gmail.com';
//   const String password = 'kuqo fmer odgv awqe'; // Gmail app password

//   final smtpServer = gmail(username, password);

//   final message =
//       Message()
//         ..from = Address(username, 'Jazeera University Admin')
//         ..recipients.add(recipientEmail)
//         ..subject = subject
//         ..text = body;

//   try {
//     await send(message, smtpServer);
//     debugPrint('✅ Email sent to $recipientEmail');
//   } catch (e) {
//     debugPrint('❌ Email error: $e');
//   }
// }

// class AdminEventsTablePage extends StatefulWidget {
//   const AdminEventsTablePage({super.key});

//   @override
//   State<AdminEventsTablePage> createState() => _AdminEventsTablePageState();
// }

// class _AdminEventsTablePageState extends State<AdminEventsTablePage> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchTerm = '';

//   @override
//   void initState() {
//     super.initState();
//     _searchController.addListener(() {
//       setState(() => _searchTerm = _searchController.text.toLowerCase());
//     });
//     expireApprovedEvents();
//     checkAndSendReminders();
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   bool _matchesSearch(String title) =>
//       title.toLowerCase().contains(_searchTerm);

//   String normalizeStatus(String? raw) {
//     if (raw == null) return 'pending';
//     return raw.toString().toLowerCase().trim();
//   }

//   String displayStatus(String? raw) {
//     final s = normalizeStatus(raw);
//     switch (s) {
//       case 'approved':
//         return 'Approved';
//       case 'completed':
//         return 'Completed';
//       case 'rejected':
//         return 'Rejected';
//       case 'expired':
//         return 'Expired';

//       default:
//         return 'Pending';
//     }
//   }

//   Color statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'approved':
//         return Colors.green;
//       case 'completed':
//         return Colors.blue;
//       case 'rejected':
//         return Colors.red;
//       case 'expired':
//         return Colors.black54;

//       default:
//         return Colors.orange;
//     }
//   }

//   DateTime? parseDate(dynamic raw) {
//     if (raw == null) return null;
//     if (raw is Timestamp) return raw.toDate();
//     if (raw is String) return DateTime.tryParse(raw);
//     return null;
//   }

//   // ---------------------------------------------------------------------------
//   // Event Actions
//   // ---------------------------------------------------------------------------
//   Future<void> _approveEventDoc(
//     QueryDocumentSnapshot<Map<String, dynamic>> doc,
//   ) async {
//     await doc.reference.update({
//       'status': 'approved',
//       'approvedAt': FieldValue.serverTimestamp(),
//       'approvedBy': FirebaseAuth.instance.currentUser?.uid,
//     });

//     final data = doc.data();
//     await sendEmail(
//       recipientEmail: data['organizerEmail'] ?? '',
//       subject: 'Event Approved - ${data['title']}',
//       body: 'Your event "${data['title']}" has been approved.',
//     );

//     if (mounted) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Event approved')));
//     }
//   }

//   Future<void> _completeEventDoc(
//     QueryDocumentSnapshot<Map<String, dynamic>> doc,
//   ) async {
//     await doc.reference.update({
//       'status': 'completed',
//       'completedAt': FieldValue.serverTimestamp(),
//       'completedBy': FirebaseAuth.instance.currentUser?.uid,
//     });

//     final data = doc.data();
//     await sendEmail(
//       recipientEmail: data['organizerEmail'] ?? '',
//       subject: 'Event Completed - ${data['title']}',
//       body: 'Your event "${data['title']}" has been marked as completed.',
//     );

//     if (mounted) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Event completed')));
//     }
//   }

//   Future<void> _rejectEventDoc(
//     QueryDocumentSnapshot<Map<String, dynamic>> doc,
//   ) async {
//     final reasonCtrl = TextEditingController();
//     final reason = await showDialog<String>(
//       context: context,
//       builder:
//           (ctx) => AlertDialog(
//             title: const Text('Reject Event'),
//             content: TextField(
//               controller: reasonCtrl,
//               decoration: const InputDecoration(hintText: 'Enter reason'),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(ctx),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
//                 child: const Text('Reject'),
//               ),
//             ],
//           ),
//     );
//     if (reason == null || reason.isEmpty) return;

//     await doc.reference.update({
//       'status': 'rejected',
//       'rejectedAt': FieldValue.serverTimestamp(),
//       'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
//       'rejectedReason': reason,
//     });

//     final data = doc.data();
//     await sendEmail(
//       recipientEmail: data['organizerEmail'] ?? '',
//       subject: 'Event Rejected - ${data['title']}',
//       body: 'Your event "${data['title']}" has been rejected.\nReason: $reason',
//     );

//     if (mounted) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Event rejected')));
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // Expire + Reminders
//   // ---------------------------------------------------------------------------
//   Future<void> expireApprovedEvents() async {
//   final now = DateTime.now();

//   try {
//     final querySnapshot = await FirebaseFirestore.instance
//         .collection('events')
//         .where('status', isEqualTo: 'Approved')
//         .get();

//     for (final doc in querySnapshot.docs) {
//       final data = doc.data();

//       DateTime? endDateTime;
//       final rawEnd = data['endDateTime'];

//       if (rawEnd is Timestamp) {
//         endDateTime = rawEnd.toDate();
//       } else if (rawEnd is String) {
//         endDateTime = DateTime.tryParse(rawEnd);
//       }

//       if (endDateTime == null) continue;

//       final currentStatus = (data['status'] ?? '').toString().toLowerCase();

//       // ✅ expire only if still Approved
//       if (currentStatus == 'approved' && endDateTime.isBefore(now)) {
//         await doc.reference.update({'status': 'Expired'});
//         debugPrint('⚠️ Event expired: ${data['title'] ?? doc.id}');

//         // --- Update organizer user doc ---
//         final organizerId = data['organizerId'];
//         if (organizerId != null) {
//           final userRef = FirebaseFirestore.instance.collection('users').doc(organizerId);
//           final userDoc = await userRef.get();

//           if (userDoc.exists) {
//             final userData = userDoc.data();
//             int expiredCount = (userData?['expiredCount'] ?? 0) + 1;

//             final Map<String, dynamic> updateData = {
//               'expiredCount': expiredCount,
//               'updatedAt': FieldValue.serverTimestamp(),
//             };

//             // ✅ if user hit 3+ expired events → blacklist automatically
//             if (expiredCount >= 3) {
//               updateData['blacklisted'] = true;
//               updateData['blockedAt'] = FieldValue.serverTimestamp();

//               final userEmail = userData?['email'] ?? '';
//               final userName = userData?['fullName'] ?? 'Organizer';

//               if (userEmail.isNotEmpty) {
//                 await sendEmail(
//                   recipientEmail: userEmail,
//                   subject: 'Account Blacklisted - Jazeera University',
//                   body: '''
// Hello $userName,

// Your account has been BLACKLISTED due to 3 or more expired events.

// You are no longer allowed to create or manage new events until further notice.

// If you believe this is a mistake, please contact the administrator.

// -- Jazeera University Admin
// ''',
//                 );
//               }

//               debugPrint("🚫 User $organizerId blacklisted after $expiredCount expired events");
//             }

//             await userRef.update(updateData);
//           }
//         }
//       }
//     }
//   } catch (e) {
//     debugPrint('❌ Error expiring events: $e');
//   }
// }

//   Future<void> checkAndSendReminders() async {
//     final snapshot =
//         await FirebaseFirestore.instance
//             .collection('events')
//             .where('status', isEqualTo: 'approved')
//             .get();

//     for (final doc in snapshot.docs) {
//       final data = doc.data();
//       final startDate = parseDate(data['startDate'] ?? data['startDateTime']);
//       if (startDate != null && data['reminderSent'] != true) {
//         await sendEmail(
//           recipientEmail: data['organizerEmail'] ?? '',
//           subject: 'Event Reminder',
//           body:
//               'Reminder: Your event "${data['title']}" is starting on $startDate',
//         );
//         await doc.reference.update({'reminderSent': true});
//       }
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // Build
//   // ---------------------------------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           Builder(
//             builder:
//                 (context) => HomeHeader(
//                   onMenuTap: () => Scaffold.of(context).openEndDrawer(),
//                   title: 'Manage Events',
//                 ),
//           ),
//           Expanded(
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     TextField(
//                       controller: _searchController,
//                       decoration: InputDecoration(
//                         prefixIcon: const Icon(Icons.search),
//                         hintText: 'Search events...',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),

//                     StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                       stream:
//                           FirebaseFirestore.instance
//                               .collection('events')
//                               .orderBy('createdAt', descending: true)
//                               .snapshots(),
//                       builder: (context, snapshot) {
//                         if (!snapshot.hasData) {
//                           return const Center(
//                             child: CircularProgressIndicator(),
//                           );
//                         }

//                         final docs =
//                             snapshot.data!.docs.where((doc) {
//                               final title = (doc['title'] ?? '') as String;
//                               return _matchesSearch(title);
//                             }).toList();

//                         if (docs.isEmpty) {
//                           return const Text('No matching events found.');
//                         }

//                         return SingleChildScrollView(
//                           scrollDirection: Axis.horizontal,
//                           child: DataTable(
//                             columns: const [
//                               DataColumn(label: Text('Title')),
//                               DataColumn(label: Text('Date')),
//                               DataColumn(label: Text('Venue')),
//                               DataColumn(label: Text('Organizer')),
//                               DataColumn(label: Text('Status')),
//                               DataColumn(label: Text('Action')),
//                             ],
//                             rows:
//                                 docs.map((doc) {
//                                   final data = doc.data();
//                                   final rawStatus = normalizeStatus(
//                                     data['status'],
//                                   );
//                                   final statusLabel = displayStatus(
//                                     data['status'],
//                                   );
//                                   final start = parseDate(
//                                     data['startDate'] ?? data['startDateTime'],
//                                   );
//                                   final dateStr =
//                                       start != null
//                                           ? DateFormat(
//                                             'yyyy-MM-dd',
//                                           ).format(start)
//                                           : 'N/A';

//                                   return DataRow(
//                                     cells: [
//                                       DataCell(
//                                         Text(data['title'] ?? 'Untitled'),
//                                       ),
//                                       DataCell(Text(dateStr)),
//                                       DataCell(Text(data['venue'] ?? 'N/A')),
//                                       DataCell(
//                                         Text(data['organizerName'] ?? 'N/A'),
//                                       ),
//                                       DataCell(
//                                         Chip(
//                                           label: Text(
//                                             statusLabel,
//                                             style: const TextStyle(
//                                               color: Colors.white,
//                                             ),
//                                           ),
//                                           backgroundColor: statusColor(
//                                             rawStatus,
//                                           ),
//                                         ),
//                                       ),
//                                       DataCell(
//                                         PopupMenuButton<String>(
//                                           onSelected: (val) async {
//                                             if (val == 'approve') {
//                                               await _approveEventDoc(doc);
//                                             } else if (val == 'reject') {
//                                               await _rejectEventDoc(doc);
//                                             } else if (val == 'complete') {
//                                               await _completeEventDoc(doc);
//                                             }
//                                           },
//                                           itemBuilder: (context) {
//                                             if (rawStatus == 'pending') {
//                                               return const [
//                                                 PopupMenuItem(
//                                                   value: 'approve',
//                                                   child: Text('Approve'),
//                                                 ),
//                                                 PopupMenuItem(
//                                                   value: 'reject',
//                                                   child: Text('Reject'),
//                                                 ),
//                                               ];
//                                             } else if (rawStatus ==
//                                                 'approved') {
//                                               return const [
//                                                 PopupMenuItem(
//                                                   value: 'complete',
//                                                   child: Text('Complete'),
//                                                 ),
//                                               ];
//                                             } else {
//                                               return const [];
//                                             }
//                                           },
//                                         ),
//                                       ),
//                                     ],
//                                   );
//                                 }).toList(),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//           const FooterPage(),
//         ],
//       ),
//     );
//   }
// }
