import 'package:flutter/material.dart';

class ProfileExpandableMenu extends StatefulWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const ProfileExpandableMenu({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  State<ProfileExpandableMenu> createState() => _ProfileExpandableMenuState();
}

class _ProfileExpandableMenuState extends State<ProfileExpandableMenu> {
  bool isExpanded = false;

  void toggleExpand() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Menu button
        _buildMenuButton(
          icon: widget.icon,
          text: widget.title,
          isOpen: isExpanded,
          onTap: toggleExpand,
        ),

        // Expandable content
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.children,
            ),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    required bool isOpen,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6F9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF212121),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                isOpen ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF757575),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
