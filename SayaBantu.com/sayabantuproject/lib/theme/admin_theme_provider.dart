import 'package:flutter/material.dart';

import 'admin_theme.dart';

class AdminThemeProvider extends InheritedWidget {
  final AdminTheme theme;

  const AdminThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  factory AdminThemeProvider.fromRole({
    Key? key,
    required String? role,
    required Widget child,
  }) {
    return AdminThemeProvider(
      key: key,
      theme: AdminTheme.of(role),
      child: child,
    );
  }

  static AdminTheme of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<AdminThemeProvider>();
    assert(
      provider != null,
      'AdminThemeProvider tidak ditemukan di widget tree.',
    );
    return provider!.theme;
  }

  @override
  bool updateShouldNotify(AdminThemeProvider oldWidget) =>
      oldWidget.theme.role != theme.role;
}