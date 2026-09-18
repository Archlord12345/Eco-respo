import 'package:flutter/material.dart';

enum AppBreakpoint { mobile, tablet, desktop }

class ResponsiveHelper {
  static AppBreakpoint of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 600) return AppBreakpoint.mobile;
    if (w < 1024) return AppBreakpoint.tablet;
    return AppBreakpoint.desktop;
  }

  static bool isDesktop(BuildContext context) =>
      of(context) == AppBreakpoint.desktop;

  static bool isCompact(BuildContext context) =>
      of(context) == AppBreakpoint.mobile;
}
