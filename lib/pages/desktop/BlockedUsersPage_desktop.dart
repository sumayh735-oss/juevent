import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/admin_home_header_desktop.dart';

class BlockedUsersPageDesktop extends StatefulWidget {
  const BlockedUsersPageDesktop({super.key});

  @override
  State<BlockedUsersPageDesktop> createState() => _BlockedUsersPageDesktopState();
}

class _BlockedUsersPageDesktopState extends State<BlockedUsersPageDesktop> {
  static const double kHeaderPad = 80;

  bool isAdmin = false;
  bool loading = true;

  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    checkIfAdmin();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> checkIfAdmin() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        loading = false;
        isAdmin = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      setState(() {
        loading = false;
        isAdmin = doc.exists && (doc.data()?['role'] == 'admin');
      });
    } catch (_) {
      setState(() {
        loading = false;
        isAdmin = false;
      });
    }
  }

  Future<void> unblockUser(String docId, String displayName) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'blacklisted': false, // hubi in field-kan sax yahay
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$displayName has been unblocked'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(docId)
                  .update({'blacklisted': true});
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _unblockMany(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (docs.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unblock users'),
        content: Text('Unblock ${docs.length} user(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final batch = FirebaseFirestore.instance.batch();
      for (final d in docs) {
        batch.update(d.reference, {
          'blacklisted': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) Navigator.pop(context); // close progress dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AdminHomeHeaderDesktop(
                onMenuTap: () => Scaffold.of(context).openEndDrawer(), title: 'Block users',
              ),
            ),
            const Positioned.fill(
              top: kHeaderPad,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }

    if (!isAdmin) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AdminHomeHeaderDesktop(
                onMenuTap: () => Scaffold.of(context).openEndDrawer(), title: 'Block users',
              ),
            ),
            const Positioned.fill(
              top: kHeaderPad,
              child: Center(child: Text('Access denied: Admins only')),
            ),
          ],
        ),
      );
    }

    final query = FirebaseFirestore.instance
        .collection('users')
        .where('blacklisted', isEqualTo: true)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => snap.data() ?? {},
          toFirestore: (data, _) => data,
        );

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AdminHomeHeaderDesktop(
              onMenuTap: () => Scaffold.of(context).openEndDrawer(), title: 'Block users',
            ),
          ),
          Positioned.fill(
            top: kHeaderPad,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snap.data?.docs ?? [];
                final filtered = _query.isEmpty
                    ? all
                    : all.where((d) {
                        final m = d.data();
                        final name = (m['displayName'] ?? m['username'] ?? '')
                            .toString()
                            .toLowerCase();
                        final email = (m['email'] ?? '').toString().toLowerCase();
                        return name.contains(_query) || email.contains(_query);
                      }).toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Blocked Users',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search by name or email',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(.5),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (all.isEmpty)
                      const Expanded(
                        child: Center(child: Text('No blocked users found.')),
                      )
                    else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Row(
                          children: [
                            _StatChip(
                              icon: Icons.block,
                              label: 'Blocked',
                              value: all.length,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            _StatChip(
                              icon: Icons.filter_alt_outlined,
                              label: 'Shown',
                              value: filtered.length,
                              color: Colors.deepPurple,
                            ),
                            const Spacer(),
                            if (filtered.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => _unblockMany(filtered),
                                icon: const Icon(Icons.lock_open),
                                label: const Text('Unblock all shown'),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 0),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final doc = filtered[i];
                            final m = doc.data();
                            final name =
                                (m['displayName'] ?? m['username'] ?? 'Unnamed')
                                    .toString();
                            final email =
                                (m['email'] ?? 'No email').toString();
                            final role = (m['role'] ?? '').toString();
                            final ts =
                                (m['blockedAt'] as Timestamp?)?.toDate();

                            return Dismissible(
                              key: ValueKey(doc.id),
                              direction: DismissDirection.startToEnd,
                              background: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade500,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.centerLeft,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Row(
                                  children: [
                                    Icon(Icons.lock_open, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      'Unblock',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              confirmDismiss: (_) async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirm Unblock'),
                                    content: Text('Unblock $name?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Unblock'),
                                      ),
                                    ],
                                  ),
                                );
                                return ok == true;
                              },
                              onDismissed: (_) => unblockUser(doc.id, name),
                              child: _UserCard(
                                name: name,
                                email: email,
                                role:
                                    role.isEmpty ? null : role.toUpperCase(),
                                dateLabel:
                                    ts == null ? null : _fmt(ts),
                                onUnblock: () => unblockUser(doc.id, name),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/* ------------ Widgets ------------- */

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          Text('$value', style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String? role;
  final String? dateLabel;
  final VoidCallback onUnblock;

  const _UserCard({
    required this.name,
    required this.email,
    this.role,
    this.dateLabel,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: theme.colorScheme.primary.withOpacity(.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (role != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(email, style: TextStyle(color: Colors.grey.shade600)),
                  if (dateLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Blocked: $dateLabel',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: onUnblock,
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text('Unblock'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(DateTime dt) {
  final mm = dt.month.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  return '${dt.year}/$mm/$dd';
}
