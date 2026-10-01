import 'package:flutter/material.dart';

final navigatorKey = GlobalKey<NavigatorState>();

/// Fade + small upward slide, matching the web app's screen transition.
Route<T> fadeRoute<T>(Widget page, {bool fullscreenDialog = false}) {
  return PageRouteBuilder<T>(
    fullscreenDialog: fullscreenDialog,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

extension NavContext on BuildContext {
  Future<T?> push<T>(Widget page) => Navigator.of(this).push<T>(fadeRoute(page));

  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  void replaceAll(Widget page) => Navigator.of(this).pushAndRemoveUntil(fadeRoute(page), (_) => false);
}
