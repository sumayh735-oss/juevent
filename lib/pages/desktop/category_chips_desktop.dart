import 'package:flutter/material.dart';

class CategoryChipsDesktop extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryChipsDesktop({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const List<String> categories = [
    "All Events",
    "Conferences",
    "Workshops",
    "Seminars",
    "Cultural",
    "Sports",
    "Competitions",
    "Guest Talks",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white, // ✅ background ka cad
      child: Center(
        child: Wrap(
          spacing: 12, // boos u dhexeeya chips
          runSpacing: 8,
          alignment: WrapAlignment.center, // ✅ bartamaha
          children: categories.map((label) {
            final bool isSelected = label == selected;
            return ChoiceChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(label),
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24), // pill shape
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            );
          }).toList(),
        ),
      ),
    );
  }
}
