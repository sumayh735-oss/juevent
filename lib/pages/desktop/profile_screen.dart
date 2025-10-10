import 'package:flutter/material.dart';
import 'profile_expandable_menu.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                "https://i.postimg.cc/0jqKB6mS/Profile-Image.png",
              ),
            ),
            const SizedBox(height: 30),

            /// My Account
            ProfileExpandableMenu(
              icon: Icons.person,
              title: "My Account",
              children: const [
                SizedBox(height: 10),
                Text("Username: Sarah J.", style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Text(
                  "Email: sarah@example.com",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text("Phone: +252 61 2345678", style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
              ],
            ),

            /// Orders Section
            ProfileExpandableMenu(
              icon: Icons.shopping_cart,
              title: "My Orders",
              children: const [
                SizedBox(height: 10),
                Text("Order #1245 - Delivered", style: TextStyle(fontSize: 16)),
                SizedBox(height: 6),
                Text(
                  "Order #1246 - Processing",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
              ],
            ),

            /// Settings Section
            ProfileExpandableMenu(
              icon: Icons.settings,
              title: "Settings",
              children: const [
                SizedBox(height: 10),
                Text("Notifications: Enabled", style: TextStyle(fontSize: 16)),
                SizedBox(height: 6),
                Text("Language: English", style: TextStyle(fontSize: 16)),
                SizedBox(height: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
