import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Round avatar for the support agent with a headset badge and an optional
/// green "online" dot.
class SupportAvatar extends StatelessWidget {
  const SupportAvatar({super.key, required this.initial, this.size = 40, this.online = false, this.ring});

  final String initial;
  final double size;
  final bool online;

  /// Colour of the gap around the online dot; defaults to the surface colour.
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dot = (size * 0.28).clamp(10.0, 18.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.accent, c.accentDark],
              ),
            ),
            child: Text(
              initial,
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
                color: AppColors.onAccent,
                height: 1,
              ),
            ),
          ),
          Positioned(
            left: -size * 0.04,
            bottom: -size * 0.04,
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
                border: Border.all(color: ring ?? c.surface, width: 1.5),
              ),
              child: FaIcon(FontAwesomeIcons.headset, size: size * 0.18, color: Colors.white),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  shape: BoxShape.circle,
                  border: Border.all(color: ring ?? c.surface, width: 2.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small red count bubble, e.g. unread chat messages.
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Container(
        constraints: const BoxConstraints(minWidth: 22),
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.danger, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
        ),
      ),
    );
  }
}
