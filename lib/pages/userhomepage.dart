// import 'package:flutter/material.dart';

// class UserHomePage extends StatelessWidget {
//   const UserHomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('User Dashboard')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pushNamed(context, '/events');
//               },
//               icon: const Icon(Icons.event),
//               label: const Text('View Events'),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pushNamed(context, '/booking-form');
//               },
//               icon: const Icon(Icons.book_online),
//               label: const Text('Book a Hall'),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pushNamed(context, '/venues');
//               },
//               icon: const Icon(Icons.meeting_room),
//               label: const Text('Check Hall Availability'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
