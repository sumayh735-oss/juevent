// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:withfbase/pages/main_admin_page.dart';
import 'package:withfbase/widgets/activity_history_page.dart';
import 'package:withfbase/widgets/app_settings_page.dart';
import 'package:withfbase/widgets/edit_profile_page.dart';
import 'package:withfbase/widgets/help_center_page.dart';
import 'package:withfbase/widgets/notification_service.dart';
import 'package:withfbase/widgets/notification_settings_page.dart';
import 'package:withfbase/widgets/security_page.dart';
import 'firebase_options.dart';

// Pages
import 'package:withfbase/pages/loginpage.dart';
import 'package:withfbase/pages/signup.dart';
import 'package:withfbase/pages/homepage.dart';
import 'package:withfbase/pages/main_page.dart';

// Notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

// Responsive framework
import 'package:responsive_framework/responsive_framework.dart';

// ScreenUtil
import 'package:flutter_screenutil/flutter_screenutil.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
          routes: {
            '/main': (context) => const MainPage(),
            '/login': (context) => const LoginPage(),
            '/logout': (context) => const LoginPage(),
            '/signup': (context) => const SignupPage(),
            '/home': (context) => const Homepage(),
            '/admin': (context) => const MainAdminPage(),
            '/profile/edit': (_) => const EditProfilePage(),
            '/profile/security': (_) => const SecurityPage(),
            '/profile/notifications': (_) => const NotificationSettingsPage(),
            '/profile/history': (_) => const ActivityHistoryPage(),
            '/settings': (_) => const AppSettingsPage(),
            '/help': (_) => const HelpCenterPage(),
          },

          // ✅ Responsive Framework
          builder:
              (context, widget) => ResponsiveBreakpoints.builder(
                child: widget!,
                breakpoints: [
                  const Breakpoint(start: 0, end: 450, name: MOBILE),
                  const Breakpoint(start: 451, end: 800, name: TABLET),
                  const Breakpoint(start: 801, end: 1200, name: DESKTOP),
                  const Breakpoint(
                    start: 1201,
                    end: double.infinity,
                    name: '4K',
                  ),
                ],
              ),

          onUnknownRoute:
              (settings) =>
                  MaterialPageRoute(builder: (context) => const UnknownPage()),

          home: child, // ScreenUtilInit child
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
