import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:withfbase/pages/desktop/help_center_desktop.dart';

// Kuwo kaa jooga app-kaaga
import 'package:withfbase/pages/desktop/home_header_desktop.dart';
import 'package:withfbase/pages/desktop/homepage_desktop.dart';
import 'package:withfbase/pages/desktop/loginpage_desktop.dart';
import 'package:withfbase/pages/desktop/mycreated_events_page_desktop.dart';
import 'package:withfbase/pages/desktop/support_desktop.dart';
import 'package:withfbase/pages/settings_page.dart';
import 'package:withfbase/services/privacy_policypage.dart';

class ProfileDesktop extends StatefulWidget {
  const ProfileDesktop({super.key});
  @override
  State<ProfileDesktop> createState() => _ProfileDesktopState();
}

class _ProfileDesktopState extends State<ProfileDesktop> {
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
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        userData = snap.data();
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void _openFullSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsPage(
          isDarkMode: isDarkMode,
          onThemeChanged: (val) => setState(() => isDarkMode = val),
        ),
      ),
    );
  }

  // ---------- Quick Actions ----------
  Future<void> _openQuickAction(String key) async {
    switch (key) {
      case 'myEvents':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MycreatedEventsPageDesktop()),
        );
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        children: [
          // Header – waxaa laga qaaday Stack/Positioned; si toos ah ayaan u dul saarnay
          HomeHeaderDesktop(
            onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            title: 'Profile',
          ),
          // Content
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
    );
  }

  Widget _buildBody() {
    final user = currentUser;

    // ---------- GUEST VIEW ----------
    if (user == null || userData == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const _HeroBannerGuest(),
          const SizedBox(height: 18),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginpageDesktop()),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Login to your account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A5AE0),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    // ---------- AUTH VIEW ----------
    final photo = user.photoURL;
    final username = (userData!['username'] ?? 'User').toString();
    final email = (user.email ?? '—').toString();
    final role = (userData!['role'] ?? 'User').toString();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Hero + avatar + name
        _HeroBanner(
          name: username,
          email: email,
          role: role,
          photoUrl: photo,
          onEdit: () => _openQuickAction('edit'),
        ),
        const SizedBox(height: 18),

        // Quick actions
        _QuickActionsBar(
          onTapMyEvents: () => _openQuickAction('myEvents'),
          onTapEdit: () => _openQuickAction('edit'),
          onTapSecurity: () => _openQuickAction('security'),
          onTapHistory: () => _openQuickAction('history'),
        ),
        const SizedBox(height: 18),

        // Info + Settings (2 columns on wide screens)
        LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 1000;
            return Flex(
              direction: isWide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: _InfoCard(
                    title: 'Account details',
                    items: [
                      _InfoRow(label: 'Username', value: username),
                      _InfoRow(label: 'Email', value: email),
                      _InfoRow(label: 'Role', value: role),
                    ],
                  ),
                ),
                SizedBox(width: isWide ? 18 : 0, height: isWide ? 0 : 18),
                Expanded(
                  flex: 1,
                  child: _SettingsCard(
                    isDark: isDarkMode,
                    onDarkChanged: (v) => setState(() => isDarkMode = v),
                    onOpenSettings: _openFullSettings, // ← callback sax ah
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),

        // Help + Links (Terms & Policy clickable)
       _HelpCard(
  onOpenFaq: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const HelpCenterDesktop()),
  ),
  onOpenSupport: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SupportDesktop()),
  ),
  onOpenTerms: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PolicyTermsDialog()),
  ),
  onOpenPolicy: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PolicyTermsDialog()),
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
              MaterialPageRoute(builder: (_) => const HomepageDesktop()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}

/* =========================
        Fancy Widgets
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
    final primary = const Color(0xFF6A5AE0);

    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A5AE0), Color(0xFF8A82F0)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // subtle pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.blur_on,
                size: 180, color: Colors.white.withOpacity(.08)),
          ),

          // content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(.35),
                    ),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: Colors.white,
                      backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                          ? NetworkImage(photoUrl!)
                          : null,
                      child: (photoUrl == null || photoUrl!.isEmpty)
                          ? Icon(Icons.person, color: primary, size: 46)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name + email + chips
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: onEdit,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    Colors.white.withOpacity(.15),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style:
                              TextStyle(color: Colors.white.withOpacity(.9)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            _Chip(
                                text: role.toUpperCase(),
                                icon: Icons.verified_user),
                            const _Chip(
                                text: 'PROFILE', icon: Icons.person_outline),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBannerGuest extends StatelessWidget {
  const _HeroBannerGuest();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF94A3B8), Color(0xFFCBD5E1)],
        ),
      ),
      child: const Center(
        child: Text(
          'Welcome! Sign in to manage your profile',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _QuickActionsBar extends StatelessWidget {
  final VoidCallback onTapMyEvents, onTapEdit, onTapSecurity, onTapHistory;

  const _QuickActionsBar({
    required this.onTapMyEvents,
    required this.onTapEdit,
    required this.onTapSecurity,
    required this.onTapHistory,
  });

  Widget _btn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF6A5AE0).withOpacity(.12),
                child: const Icon(Icons.chevron_right,
                    size: 18, color: Color(0xFF6A5AE0)),
              ),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _btn(Icons.event, 'My Events', onTapMyEvents),
        _btn(Icons.edit_outlined, 'Edit', onTapEdit),
        _btn(Icons.lock_outline, 'Security', onTapSecurity),
        _btn(Icons.history, 'History', onTapHistory),
      ],
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
