import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> ensureUserFields(String userId) async {
  final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
  final snapshot = await userDocRef.get();

  if (!snapshot.exists) return;

  final data = snapshot.data() ?? {};

  Map<String, dynamic> updates = {};

  if (!data.containsKey('missedEventsCount')) {
    updates['missedEventsCount'] = 0;
  }

  if (!data.containsKey('expiredCount')) {
    updates['expiredCount'] = 0;
  }

  if (!data.containsKey('blacklisted')) {
    updates['blacklisted'] = false;
  }

  if (!data.containsKey('blockedAt')) {
    updates['blockedAt'] = null;
  }

  if (!data.containsKey('documentUrl')) {
    updates['documentUrl'] = '';
  }

  if (updates.isNotEmpty) {
    await userDocRef.update(updates);
    print("Updated missing fields for user $userId");
  }
}
