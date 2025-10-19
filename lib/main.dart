// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:withfbase/pages/main_admin_page.dart';
import 'package:withfbase/pages/mycreated_events_page.dart';
import 'package:withfbase/widgets/activity_history_page.dart';
import 'package:withfbase/widgets/app_settings_page.dart';
import 'package:withfbase/widgets/edit_profile_page.dart';
import 'package:withfbase/widgets/help_center_page.dart';
import 'package:withfbase/widgets/notification_service.dart';
import 'package:withfbase/widgets/notification_settings_page.dart';
import 'package:withfbase/widgets/responsive_layout.dart';
import 'package:withfbase/widgets/security_page.dart';
import 'firebase_options.dart';

// ✅ Supabase

// Pages
import 'package:withfbase/pages/loginpage.dart';
import 'package:withfbase/pages/signup.dart';
import 'package:withfbase/pages/homepage.dart';
import 'package:withfbase/pages/main_page.dart';

// Notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;


// ScreenUtil
import 'package:flutter_screenutil/flutter_screenutil.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Init Supabase

  // Init timezone data
  tz.initializeTimeZones();

  // Initialize notifications using your service class
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // base design (iPhone X)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
      return MaterialApp(
  title: 'Hallevent',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor: Colors.grey[100],
    fontFamily: 'Roboto',
    visualDensity: VisualDensity.adaptivePlatformDensity,
  ),
  initialRoute: '/main',
  routes: { '/main': (context) => const MainPage(), '/login': (context) => 
  const LoginPage(), '/logout': (context) => const LoginPage(), '/signup': (context) => 
  const SignupPage(), '/home': (context) => const Homepage(), '/admin': (context) => const MainAdminPage(), '/profile/edit': (_) => 
  const EditProfilePage(),'/profile/my_events': (context) => const MycreatedEventsPage(),
'/profile/security': (_) => const SecurityPage(), '/profile/notifications': (_) => 
const NotificationSettingsPage(), '/profile/history': (_) => const ActivityHistoryPage(), '/settings': (_) => 
const AppSettingsPage(), '/help': (_) => const HelpCenterPage(), },

  // ✅ Halkan ResponsiveBreakpoints waa laga saaray
  builder: (context, widget) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox.expand( // buuxi width + height screen dhan
          child: widget,
        );
      },
    );
  },

  onUnknownRoute: (settings) =>
      MaterialPageRoute(builder: (context) => const UnknownPage()),

  home: const ResponsiveLayout(), // ✅ default home = responsive
);

      },
      child: const MainPage(),
    );
  }
}

class UnknownPage extends StatelessWidget {
  const UnknownPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("404 - Page Not Found")),
      body: Center(
        child: Text(
          "Oops! This page does not exist.",
          style: TextStyle(fontSize: 16.sp), // Responsive font size
        ),
      ),
    );
  }
}
