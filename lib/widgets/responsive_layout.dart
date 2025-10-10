import 'package:flutter/material.dart';
import 'package:withfbase/pages/mobile/homepage_mobile.dart';
import 'package:withfbase/pages/desktop/homepage_desktop.dart';

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key});

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 1024; // 0 - 1023

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024; // 1024++

  @override
  Widget build(BuildContext context) {
    if (isDesktop(context)) {
      return const HomepageDesktop();
    } else {
      return const HomepageMobile();
    }
  }
}
