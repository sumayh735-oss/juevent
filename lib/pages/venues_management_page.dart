import 'package:flutter/material.dart';
import 'package:withfbase/pages/add_venues_page.dart';
import 'package:withfbase/widgets/admin_venues_list.dart';

class VenuesManagementPage extends StatefulWidget {
  const VenuesManagementPage({super.key});

  @override
  State<VenuesManagementPage> createState() => _VenuesManagementPageState();
}

class _VenuesManagementPageState extends State<VenuesManagementPage> {
  String searchQuery = '';

  void _showAddVenueModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddVenuePage(venueId: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Venues Management",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),

          // 🔍 Search + ➕ Add Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => searchQuery = val),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search venues...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddVenueModal(context),
                icon: const Icon(Icons.add),
                label: const Text('New Venue'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ✅ Venue Cards List
          AdminVenuesList(searchQuery: searchQuery),

          const SizedBox(height: 16),

          // Optional: Empty Message (not used because AdminVenuesList handles it)
          // You can remove this part
        ],
      ),
    );
  }
}
