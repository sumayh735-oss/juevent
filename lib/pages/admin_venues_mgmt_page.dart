import 'package:flutter/material.dart';
import 'package:withfbase/pages/add_venues_page.dart';
import 'package:withfbase/widgets/admin_venues_list.dart';
import 'package:withfbase/widgets/home_header.dart'; // ✅ Import HomeHeader

class AdminVenuesMgmtPage extends StatefulWidget {
  const AdminVenuesMgmtPage({super.key});

  @override
  State<AdminVenuesMgmtPage> createState() => _AdminVenuesMgmtPageState();
}

class _AdminVenuesMgmtPageState extends State<AdminVenuesMgmtPage> {
  String searchQuery = '';

  void _showAddVenueModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddVenuePage(venueId: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ HomeHeader sida AppBar (fixed)
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: HomeHeader(
          title: "Venues Management",
          onMenuTap: () => Scaffold.of(context).openEndDrawer(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ Venue Cards List
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    AdminVenuesList(searchQuery: searchQuery),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
