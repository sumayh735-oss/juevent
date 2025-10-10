import 'package:flutter/material.dart';
import 'package:withfbase/pages/desktop/add_venues_page_desktop.dart';
import 'package:withfbase/pages/desktop/admin_home_header_desktop.dart';
import 'package:withfbase/widgets/admin_venues_list.dart';

class AdminVenuesMgmtPageDesktop extends StatefulWidget {
  const AdminVenuesMgmtPageDesktop({super.key});

  @override
  State<AdminVenuesMgmtPageDesktop> createState() => _AdminVenuesMgmtPageState();
}

class _AdminVenuesMgmtPageState extends State<AdminVenuesMgmtPageDesktop> {
  String searchQuery = '';

  void _showAddVenueModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddVenuesPageDesktop(venueId: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: AdminHomeHeaderDesktop(
          title: "Venues Management",
          onMenuTap: () => Scaffold.of(context).openEndDrawer(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 Search + Add Button Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => searchQuery = val),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      hintText: 'Search venues...',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAddVenueModal(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('New Venue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 📋 Venue Cards Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AdminVenuesList(searchQuery: searchQuery),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
