import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const List<String> categories = [
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children:
            categories.map((label) {
              final bool isSelected = label == selected;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(label, style: const TextStyle(fontSize: 14)),
                  selected: isSelected,
                  onSelected: (_) => onSelected(label),
                  backgroundColor: Colors.grey.shade200,
                  selectedColor: Colors.blue.shade700,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
