import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const kPrimary = Color(0xFF6A5AE0);

  late bool _darkMode;
  bool _emailNotifs = true;
  bool _pushNotifs = true;
  bool _showProfilePublic = true;
  bool _twoFactor = false;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode;
  }

  @override
  Widget build(BuildContext context) {
    final bg = Colors.grey.shade50;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _HeroHeader(),

            const SizedBox(height: 18),
            _SectionCard(
              title: 'Appearance',
              subtitle: 'Customize how the app looks and feels.',
              leadingIcon: Icons.color_lens_outlined,
              children: [
                _SwitchTile(
                  title: 'Dark Mode',
                  subtitle: 'Use a darker theme to reduce eye strain',
                  value: _darkMode,
                  onChanged: (v) {
                    setState(() => _darkMode = v);
                    widget.onThemeChanged(v);
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),
            _SectionCard(
              title: 'Notifications',
              subtitle: 'Choose how you want to be notified.',
              leadingIcon: Icons.notifications_active_outlined,
              children: [
                _SwitchTile(
                  title: 'Email updates',
                  subtitle: 'Event status & announcements',
                  value: _emailNotifs,
                  onChanged: (v) => setState(() => _emailNotifs = v),
                ),
                _SwitchTile(
                  title: 'Push notifications',
                  subtitle: 'Reminders and alerts',
                  value: _pushNotifs,
                  onChanged: (v) => setState(() => _pushNotifs = v),
                ),
              ],
            ),

            const SizedBox(height: 14),
            _SectionCard(
              title: 'Language & Region',
              subtitle: 'Dates and text will adapt to your choice.',
              leadingIcon: Icons.language_outlined,
              children: [
                _DropdownTile<String>(
                  title: 'Language',
                  value: _language,
                  onChanged: (v) => setState(() => _language = v ?? _language),
                  items: const ['English', 'Somali', 'Arabic'],
                ),
              ],
            ),

            const SizedBox(height: 14),
            _SectionCard(
              title: 'Privacy & Security',
              subtitle: 'Control what others can see and protect your account.',
              leadingIcon: Icons.lock_outline,
              children: [
                _SwitchTile(
                  title: 'Public profile',
                  subtitle: 'Allow others to see your name and avatar',
                  value: _showProfilePublic,
                  onChanged: (v) => setState(() => _showProfilePublic = v),
                ),
                _SwitchTile(
                  title: 'Two-factor authentication',
                  subtitle: 'Extra security at sign-in',
                  value: _twoFactor,
                  onChanged: (v) => setState(() => _twoFactor = v),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile/security');
                    },
                    icon: const Icon(Icons.password),
                    label: const Text('Change password'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            _DangerCard(
              onDelete: () async {
                // TODO: hook up to your delete flow
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delete account pressed')),
                );
              },
            ),

            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved')),
                  );
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------- Pieces ----------------- */

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF6A5AE0), Color(0xFF8A82F0)],
        ),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10, top: -10,
            child: Icon(Icons.blur_on, size: 120, color: Colors.white.withOpacity(.1)),
          ),
          const Positioned.fill(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Personalize your experience',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF6A5AE0).withOpacity(.12),
                child: const Icon(Icons.tune, color: Color(0xFF6A5AE0), size: 18),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle!, style: TextStyle(color: Colors.grey.shade600)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _DropdownTile<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;

  const _DropdownTile({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: SizedBox(
        width: 180,
        child: DropdownButtonFormField<T>(
          value: value,
          onChanged: onChanged,
          items: items
              .map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString())))
              .toList(),
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ),
    );
  }
}

class _DangerCard extends StatelessWidget {
  final VoidCallback onDelete;
  const _DangerCard({required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5A5F)),
              SizedBox(width: 8),
              Text('Danger zone', style: TextStyle(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            Text('Deleting your account is irreversible.', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF5A5F),
                  side: const BorderSide(color: Color(0xFFFF5A5F)),
                ),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
