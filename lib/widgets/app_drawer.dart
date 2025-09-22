import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final String role;
  final int currentIndex;
  final Function(int) onItemSelected;
  final bool isLoggedIn; // ✅ Add this

  const AppDrawer({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onItemSelected,
    required this.isLoggedIn, // ✅ Add this
  });

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width >= 600;

    final drawerItems = [
      {'icon': Icons.home, 'label': 'Home'},
      {'icon': Icons.event, 'label': 'Events'},
      {'icon': Icons.place, 'label': 'Venues'},
      {'icon': Icons.event, 'label': 'Calendar'},
    ];

    return isWideScreen
        ? Row(
          children: [
            NavigationRail(
              backgroundColor: const Color(0xFF0D47A1),
              selectedIndex: currentIndex,
              onDestinationSelected: (index) {
                if (drawerItems[index]['label'] == 'Admin') {
                  if (isLoggedIn) {
                    Navigator.pushNamed(context, '/adminhome');
                  } else {
                    Navigator.pushNamed(context, '/login');
                  }
                } else {
                  onItemSelected(index);
                }
              },
              labelType: NavigationRailLabelType.all,
              destinations:
                  drawerItems.map((item) {
                    return NavigationRailDestination(
                      icon: Icon(item['icon'] as IconData),
                      selectedIcon: Icon(
                        item['icon'] as IconData,
                        color: Colors.white,
                      ),
                      label: Text(item['label'] as String),
                    );
                  }).toList(),
              selectedIconTheme: const IconThemeData(color: Colors.white),
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedLabelTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
            ),
            const VerticalDivider(width: 1),
          ],
        )
        : Drawer(
          width: 430,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0D47A1), Color(0xFFE3F2FD)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 10),

                SingleChildScrollView(
                  child: Column(
                    children: [
                      ...drawerItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return _buildModernDrawerItem(
                          context,
                          icon: item['icon'] as IconData,
                          label: item['label'] as String,
                          selected: index == currentIndex,
                          onTap: () async {
                            if (item['label'] == 'Admin') {
                              if (isLoggedIn) {
                                Navigator.pushNamed(context, '/adminhome');
                              } else {
                                Navigator.pushNamed(context, '/login');
                              }
                            } else {
                              onItemSelected(index);
                            }

                            await Future.delayed(
                              const Duration(milliseconds: 150),
                            );
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                        );
                      }),

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              'Login / Register',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF1976D2),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                    image: const DecorationImage(
                      image: AssetImage('assets/logoicon.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Jazeera University',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Hall Management',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () async {
          // Halkan kala saar admin iyo kuwa kale
          if (label == 'Admin') {
            if (isLoggedIn) {
              Navigator.pushNamed(context, '/adminhome');
            } else {
              Navigator.pushNamed(context, '/login');
            }
          } else {
            onTap(); // pages-ka kale
          }

          await Future.delayed(const Duration(milliseconds: 150));
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color:
                selected ? Colors.white.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 53, 64, 73).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
