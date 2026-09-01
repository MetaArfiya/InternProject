import 'package:flutter/material.dart';

class Responsive {
  static const double mobile = 768;
  static const double tablet = 1100;
  static const double desktop = 1440;

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static bool isMobile(BuildContext context) =>
      width(context) < mobile;

  static bool isTablet(BuildContext context) =>
      width(context) >= mobile &&
      width(context) < tablet;

  static bool isLaptop(BuildContext context) =>
      width(context) >= tablet &&
      width(context) < desktop;

  static bool isDesktop(BuildContext context) =>
      width(context) >= desktop;

  static double horizontalPadding(BuildContext context) {
    if (isDesktop(context)) return 60;
    if (isLaptop(context)) return 40;
    if (isTablet(context)) return 24;
    return 20;
  }

  static double titleSize(BuildContext context) {
    if (isDesktop(context)) return 52;
    if (isLaptop(context)) return 46;
    if (isTablet(context)) return 40;
    return 34;
  }

  static double subtitleSize(BuildContext context) {
    if (isDesktop(context)) return 54;
    if (isLaptop(context)) return 48;
    if (isTablet(context)) return 42;
    return 34;
  }
}