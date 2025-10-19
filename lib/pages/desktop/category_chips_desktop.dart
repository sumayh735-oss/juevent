import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Beautiful, centered category chips for desktop.
/// - Shows "All Events" first
/// - Gradient + shadow when selected
/// - Hover lift + ripple
/// - Skeleton pills while loading
class CategoryChipsDesktop extends StatelessWidget {
  final String selected;
  final Function(String) onSelected;

  const CategoryChipsDesktop({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _ChipsSkeleton();
        }
        if (snap.hasError) {
          return const SizedBox(
            height: 48,
            child: Center(child: Text('Failed to load categories')),
          );
        }

        // Collect names
        final List<String> categories = ['All Events'];
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          for (final d in snap.data!.docs) {
            final name = (d.data() as Map<String, dynamic>?)?['name']?.toString().trim();
            if (name != null && name.isNotEmpty) categories.add(name);
          }
        }

        return Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final c in categories) ...[
                  _CuteChip(
                    label: c,
                    icon: _iconFor(c),
                    selected: selected == c,
                    onTap: () => onSelected(c),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Icon suggestions per category name (fallback provided)
IconData _iconFor(String name) {
  final n = name.toLowerCase();
  if (n.contains('all')) return Icons.apps_rounded;
  if (n.contains('seminar')) return Icons.school_rounded;
  if (n.contains('workshop')) return Icons.handyman_rounded;
  if (n.contains('conference')) return Icons.forum_rounded;
  if (n.contains('meeting')) return Icons.groups_2_rounded;
  if (n.contains('sports')) return Icons.sports_basketball_rounded;
  if (n.contains('music')) return Icons.music_note_rounded;
  if (n.contains('tech')) return Icons.memory_rounded;
  if (n.contains('career')) return Icons.badge_rounded;
  if (n.contains('health')) return Icons.monitor_heart_rounded;
  return Icons.local_offer_rounded;
}

/// Pretty chip with hover & selection animations.
class _CuteChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CuteChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CuteChip> createState() => _CuteChipState();
}

class _CuteChipState extends State<_CuteChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    final gradient = const LinearGradient(
      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final baseBg = _hover && !selected ? Colors.blueGrey.shade50 : Colors.white;
    final borderColor = selected ? Colors.transparent : Colors.blueGrey.shade200;
    final textColor = selected ? Colors.white : Colors.blueGrey.shade800;
    final iconColor = selected ? Colors.white : Colors.blueGrey.shade700;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? gradient : null,
              color: selected ? null : baseBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor),
              boxShadow: selected || _hover
                  ? [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal skeleton while categories load (no layout issues).
class _ChipsSkeleton extends StatelessWidget {
  const _ChipsSkeleton();

  @override
  Widget build(BuildContext context) {
    final pills = [90.0, 110.0, 100.0, 120.0, 95.0];
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final w in pills) ...[
              _SkeletonPill(width: w),
              const SizedBox(width: 8),
            ]
          ],
        ),
      ),
    );
  }
}

class _SkeletonPill extends StatefulWidget {
  final double width;
  const _SkeletonPill({required this.width});

  @override
  State<_SkeletonPill> createState() => _SkeletonPillState();
}

class _SkeletonPillState extends State<_SkeletonPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);
  late final Animation<double> _a =
      Tween(begin: .45, end: .9).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: Container(
        width: widget.width,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
