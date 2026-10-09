import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Wrapper `MouseRegion` yang aman untuk web.
///
/// Di web + mobile (touch screen), `MouseRegion` bisa memicu spam error:
///   "Cannot hit test a render box with no size."
/// Ini karena browser mengirim event mouse "virtual" untuk touch, dan
/// Flutter bingung menghitung posisi.
///
/// `SafeMouseRegion` hanya mengaktifkan `MouseRegion` kalau:
///   - `kIsWeb == true` (aplikasi web), DAN
///   - lebar layar >= 768 (tablet / desktop)
///
/// Di mobile, widget langsung render tanpa `MouseRegion`.
class SafeMouseRegion extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;
  final MouseCursor cursor;

  const SafeMouseRegion({
    super.key,
    required this.child,
    this.onEnter,
    this.onExit,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  Widget build(BuildContext context) {
    // Non-web (Android/iOS) → tidak butuh MouseRegion sama sekali
    if (!kIsWeb) return child;

    final width = MediaQuery.of(context).size.width;

    // Mobile / tablet kecil → skip MouseRegion
    if (width < 768) return child;

    return MouseRegion(
      cursor: cursor,
      onEnter: onEnter != null ? (_) => onEnter!() : null,
      onExit: onExit != null ? (_) => onExit!() : null,
      child: child,
    );
  }
}