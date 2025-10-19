import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:withfbase/pages/main_page.dart';
import 'package:withfbase/pages/settings_page.dart';
import 'package:withfbase/pages/supportpage.dart';
import 'package:withfbase/services/privacy_policypage.dart';
import 'package:withfbase/widgets/help_center_page.dart';
import 'package:withfbase/widgets/home_header.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  User? currentUser;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        userData = doc.data();
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _openQuickAction(String key) async {
    switch (key) {
      case 'myEvents':
        await Navigator.pushNamed(context, '/profile/my_events');
        break;
      case 'edit':
        final changed = await Navigator.pushNamed(context, '/profile/edit');
        if (changed == true) await _loadUser();
        break;
      case 'security':
        await Navigator.pushNamed(context, '/profile/security');
        break;
      case 'history':
        await Navigator.pushNamed(context, '/profile/history');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = currentUser;

    // Guest View
    if (user == null || userData == null) {
      return Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _HeroBannerGuest(),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login),
              label: const Text('Login to your account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5AE0),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Authenticated view
    final name = (userData!['username'] ?? 'User').toString();
    final email = (user.email ?? '—').toString();
    final role = (userData!['role'] ?? 'User').toString();
    final photo = user.photoURL;

    return Scaffold(
      key: _scaffoldKey,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: HomeHeader(
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
              title: 'Profile',
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _HeroBanner(
                name: name,
                email: email,
                role: role,
                photoUrl: photo,
                onEdit: () => _openQuickAction('edit'),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _QuickActionsGrid(onTap: _openQuickAction),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _InfoCard(
                    title: 'My Account',
                    items: [
                      _InfoRow(label: 'Username', value: name),
                      _InfoRow(label: 'Email', value: email),
                      _InfoRow(label: 'Role', value: role),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SettingsCard(
                    isDark: isDarkMode,
                    onDarkChanged: (v) => setState(() => isDarkMode = v),
                    onOpenSettings: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SettingsPage(
                          isDarkMode: isDarkMode,
                          onThemeChanged: (v) =>
                              setState(() => isDarkMode = v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _HelpCard(
                    onOpenFaq: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpCenterPage()),
                    ),
                    onOpenSupport: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Supportpage()),
                    ),
                    onOpenTerms: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PolicyTermsDialog(),
                      ),
                    ),
                    onOpenPolicy: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PolicyTermsDialog(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DangerTile(
                    icon: Icons.logout,
                    title: 'Log out',
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const MainPage(initialIndex: 0),
                        ),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
    );
  }
}

/* =========================
        Widgets
========================= */

class _HeroBanner extends StatelessWidget {
  final String name, email, role;
  final String? photoUrl;
  final VoidCallback onEdit;

  const _HeroBanner({
    required this.name,
    required this.email,
    required this.role,
    required this.photoUrl,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6A5AE0);
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF6A5AE0), Color(0xFF8A82F0)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(Icons.blur_on,
                size: 140, color: Colors.white.withOpacity(.08)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                      ? NetworkImage(photoUrl!)
                      : null,
                  child: (photoUrl == null || photoUrl!.isEmpty)
                      ? const Icon(Icons.person,
                          color: primary, size: 36)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      Text(email,
                          style: TextStyle(
                              color: Colors.white.withOpacity(.9),
                              fontSize: 14)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: [
                          _Chip(text: role.toUpperCase(), icon: Icons.verified),
                          const _Chip(text: 'PROFILE', icon: Icons.person_outline),
                        ],
                      ),
                      // ✅ Admin Button (in the marked area)
                      if (role.toLowerCase() == 'admin') ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/admin');
                            },
                            icon: const Icon(Icons.admin_panel_settings, size: 18),
                            label: const Text('Go to Admin Dashboard'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: Colors.white24),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _QuickActionsGrid extends StatelessWidget {
  final void Function(String key) onTap;
  const _QuickActionsGrid({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'icon': Icons.event, 'label': 'My Events', 'key': 'myEvents'},
      {'icon': Icons.edit, 'label': 'Edit', 'key': 'edit'},
      {'icon': Icons.lock, 'label': 'Security', 'key': 'security'},
      {'icon': Icons.history, 'label': 'History', 'key': 'history'},
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 80,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, i) {
        final a = actions[i];
        return InkWell(
          onTap: () => onTap(a['key'] as String),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a['icon'] as IconData, color: const Color(0xFF6A5AE0)),
                const SizedBox(height: 6),
                Text(
                  a['label'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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


class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.person_outline,
                  size: 18, color: Color(0xFF6A5AE0)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            ...items,
          ],
        ),
      ),
    );
  }
}
class _Chip extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Chip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
      ]),
    );
  }
}

class _HeroBannerGuest extends StatelessWidget {
  const _HeroBannerGuest();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFFCBD5E1)],
        ),
      ),
      child: const Center(
        child: Text(
          'Welcome! Sign in to view your profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onDarkChanged;
  final VoidCallback onOpenSettings;
  const _SettingsCard({
    required this.isDark,
    required this.onDarkChanged,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.settings_suggest_outlined,
                  size: 18, color: Color(0xFF6A5AE0)),
              SizedBox(width: 8),
              Text('Preferences',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark Mode'),
                Switch(value: isDark, onChanged: onDarkChanged),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open full Settings'),
                onPressed: onOpenSettings, // ← callback sax ah
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final VoidCallback onOpenFaq;
  final VoidCallback onOpenSupport;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPolicy;

  const _HelpCard({
    required this.onOpenFaq,
    required this.onOpenSupport,
    required this.onOpenTerms,
    required this.onOpenPolicy,
  });

  @override
  Widget build(BuildContext context) {
    Widget tile({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
    }) {
      return ListTile(
        onTap: onTap,
        dense: true,
        leading: Icon(icon, color: Colors.grey.shade700),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.open_in_new, size: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
    }

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(
          children: [
            tile(icon: Icons.question_answer_outlined, title: 'FAQ', onTap: onOpenFaq),
            tile(icon: Icons.support_agent_outlined, title: 'Contact Support', onTap: onOpenSupport),
            const Divider(height: 8),
            tile(icon: Icons.article_outlined, title: 'Terms of Service', onTap: onOpenTerms), // ✅ clickable
            tile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: onOpenPolicy), // ✅ clickable
          ],
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
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _DangerTile(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: Container(
        decoration: const BoxDecoration(
            color: Color(0xFFFF5A5F), shape: BoxShape.circle),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Color(0xFFFF5A5F), fontWeight: FontWeight.w800)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFFF5A5F)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

