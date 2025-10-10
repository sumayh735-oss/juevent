import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:withfbase/pages/desktop/home_header_desktop.dart';
import 'package:withfbase/pages/main_page.dart';

class ProfileDesktop extends StatefulWidget {
  const ProfileDesktop({super.key});

  @override
  State<ProfileDesktop> createState() => _ProfileDesktopState();
}

class _ProfileDesktopState extends State<ProfileDesktop> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const double kHeaderPad =
      190; // hagaaji haddii HomeHeader uu ka weyn/yar yahay

  User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .get();

        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          userData = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() {
        isLoading = false;
        userData = null;
      });
    }
  }

  // ---------------- added: quick actions navigation + refresh after edit ----------------
  Future<void> _openQuickAction(String key) async {
    switch (key) {
      case 'edit':
        {
          final changed = await Navigator.pushNamed(context, '/profile/edit');
          if (changed == true) {
            await loadUserData(); // refresh user info if edited
          }
          break;
        }
      case 'security':
        await Navigator.pushNamed(context, '/profile/security');
        break;
      case 'notifications':
        await Navigator.pushNamed(context, '/profile/notifications');
        break;
      case 'history':
        await Navigator.pushNamed(context, '/profile/history');
        break;
    }
  }
  // --------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = currentUser;

    // -------- GUEST VIEW --------
    if (user == null || userData == null) {
      return Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HomeHeaderDesktop(onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(), title: 'Event Page',),
            ),
            Positioned.fill(
              top: kHeaderPad,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: const [
                  Center(
                    child: Text(
                      'Welcome, Guest! Please log in to see your profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  SizedBox(height: 16),
                  _PrimaryButton(
                    icon: Icons.login,
                    label: 'Login',
                    routeName: '/login',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // -------- AUTH VIEW --------
    final username = (userData!['username'] ?? 'No username').toString();
    final email = (user.email ?? 'No email').toString();
    final role = (userData!['role'] ?? 'No role').toString();
    final photo = user.photoURL;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeaderDesktop(onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(), title: 'Event Page',),
          ),

          Positioned.fill(
            top: kHeaderPad,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Profile card + avatar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ProfileCard(
                          name: username,
                          email: email,
                          photoUrl: photo,
                          onEdit: () => _openQuickAction('edit'), // <-- added
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Admin CTA (kaliya admin)
                      if (role.toLowerCase() == 'admin')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _PrimaryButton(
                            icon: Icons.admin_panel_settings,
                            label: 'Go to Admin Dashboard',
                            routeName: '/admin',
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Quick actions
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _QuickActions(
                          onAction: _openQuickAction, // <-- added
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Sections
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            _SectionTile(
                              icon: Icons.person_outline,
                              title: 'My Account',
                              children: [
                                _InfoRow(label: 'Username', value: username),
                                _InfoRow(label: 'Email', value: email),
                                _InfoRow(label: 'Role', value: role),
                              ],
                            ),
                            _SectionTile(
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              children: [
                                const _InfoRow(
                                  label: 'Profile Settings',
                                  value: 'Manage your details',
                                ),
                                const _InfoRow(
                                  label: 'Privacy',
                                  value: 'Control visibility & security',
                                ),
                                const _InfoRow(
                                  label: 'Notifications',
                                  value: 'Email & push alerts',
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Dark Mode',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      Switch(
                                        value: isDarkMode,
                                        onChanged:
                                            (v) =>
                                                setState(() => isDarkMode = v),
                                      ),
                                    ],
                                  ),
                                ),
                                // ---- open full settings page button
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 12,
                                    bottom: 6,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed:
                                          () => Navigator.pushNamed(
                                            context,
                                            '/settings',
                                          ),
                                      icon: const Icon(Icons.open_in_new),
                                      label: const Text('Open full Settings'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _SectionTile(
                              icon: Icons.help_outline,
                              title: 'Help Center',
                              children: const [
                                _InfoRow(
                                  label: 'FAQ',
                                  value: 'Common questions & answers',
                                ),
                                _InfoRow(
                                  label: 'Contact Support',
                                  value: 'support@example.com',
                                ),
                                _InfoRow(
                                  label: 'Terms of Service',
                                  value: 'Read our policy',
                                ),
                              ],
                            ),
                            // ---- open help center page button
                            Padding(
                              padding: const EdgeInsets.only(right: 20, top: 6),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed:
                                      () =>
                                          Navigator.pushNamed(context, '/help'),
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('Open Help Center'),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: _DangerTile(
                                icon: Icons.logout,
                                title: 'Log Out',
                                onTap: () async {
                                  await FirebaseAuth.instance.signOut();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              const MainPage(initialIndex: 0),
                                    ),
                                    (route) => false,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* =========================
        Widgets
========================= */

class _ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final VoidCallback? onEdit;

  const _ProfileCard({
    required this.name,
    required this.email,
    this.photoUrl,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 3,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: 8,
          child: IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit profile',
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: -36,
          child: Center(
            child: CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF7F9CF5),
              backgroundImage:
                  (photoUrl != null && photoUrl!.isNotEmpty)
                      ? NetworkImage(photoUrl!)
                      : null,
              child:
                  (photoUrl == null || photoUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 36, color: Colors.white)
                      : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final void Function(String key) onAction;
  const _QuickActions({required this.onAction});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionItem('Edit', Icons.edit_outlined, 'edit'),
      _ActionItem('Security', Icons.lock_outline, 'security'),
      _ActionItem(
        'Notifications',
        Icons.notifications_active_outlined,
        'notifications',
      ),
      _ActionItem('History', Icons.history, 'history'),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: .9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (_, i) {
        final it = items[i];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onAction(it.key),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6F9),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF6A5AE0),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(it.icon, color: Colors.white, size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  it.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionItem {
  final String label;
  final IconData icon;
  final String key;
  _ActionItem(this.label, this.icon, this.key);
}

class _SectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionTile({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF6A5AE0),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: children,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String routeName;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, routeName),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6A5AE0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _DangerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFF5A5F),
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFF5A5F),
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFFFF5A5F),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
