import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuTap;
  final VoidCallback? onFilterTap;
  final bool showMenu; // <--- Add this

  const HomeHeader({
    super.key,
    required this.onMenuTap,
    this.onFilterTap,
    this.showMenu = true,
    required String title, // <--- default true
  });
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    String formattedDate = DateFormat('EEE, MMM d').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 12),
      width: double.infinity,
      color: Colors.blue.shade900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Logo + Search + Menu
          Row(
            children: [
              Image.asset('assets/logo.png', height: 66),
              const Spacer(),
              const Icon(Icons.search, color: Colors.white),
              const SizedBox(width: 12),
              if (showMenu) // <--- Only show if true
                GestureDetector(
                  onTap: onMenuTap,
                  child: const Icon(Icons.menu, color: Colors.white),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.circle, size: 10, color: Colors.greenAccent),
                  SizedBox(width: 6),
                  Text(
                    "Connected",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              Text(
                formattedDate,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
