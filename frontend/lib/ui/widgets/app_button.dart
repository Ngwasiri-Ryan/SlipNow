import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'pressable.dart';

enum ButtonVariant { primary, accent, ghost, success, whatsapp, danger, white, outlineWhite }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = ButtonVariant.primary,
    this.loading = false,
    this.expand = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final FaIconData? icon;
  final FaIconData? trailingIcon;
  final ButtonVariant variant;
  final bool loading;
  final bool expand;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg, border, shadow) = switch (variant) {
      ButtonVariant.primary => (c.primary, Colors.white, null, c.primary.withValues(alpha: 0.25)),
      ButtonVariant.accent => (c.accent, AppColors.onAccent, null, c.accent.withValues(alpha: 0.3)),
      ButtonVariant.ghost => (c.surface, c.text, c.border, null),
      ButtonVariant.success => (c.success, Colors.white, null, null),
      ButtonVariant.whatsapp => (AppColors.whatsapp, Colors.white, null, null),
      ButtonVariant.danger => (c.danger, Colors.white, null, null),
      ButtonVariant.white => (Colors.white, c.primary, null, null),
      ButtonVariant.outlineWhite => (Colors.transparent, Colors.white, Colors.white.withValues(alpha: 0.35), null),
    };
    final disabled = onPressed == null && !loading;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg, backgroundColor: fg.withValues(alpha: 0.35)),
          )
        else if (icon != null)
          FaIcon(icon, size: 15, color: fg),
        if (loading || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: compact ? 14 : 15, fontWeight: FontWeight.w700, letterSpacing: 0.1, color: fg),
          ),
        ),
        if (trailingIcon != null && !loading) ...[const SizedBox(width: 10), FaIcon(trailingIcon, size: 14, color: fg)],
      ],
    );

    return Pressable(
      onTap: loading || disabled ? null : onPressed,
      child: AnimatedOpacity(
        opacity: disabled ? 0.45 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 48 : 52),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: compact ? 12 : 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(compact ? AppRadius.sm : AppRadius.md),
            border: border == null ? null : Border.all(color: border, width: 1.5),
            boxShadow: shadow == null ? null : [BoxShadow(color: shadow, blurRadius: 14, offset: const Offset(0, 4))],
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Round 44px icon button used in top bars.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 16,
    this.semanticLabel,
    this.badge,
    this.onDark = false,
  });

  final FaIconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;
  final String? semanticLabel;
  final Widget? badge;

  /// Translucent white style for use on the green brand header.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onPressed,
      scale: 0.9,
      semanticLabel: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: onDark ? Colors.white.withValues(alpha: 0.14) : c.surface,
              shape: BoxShape.circle,
              border: Border.all(color: onDark ? Colors.white.withValues(alpha: 0.22) : c.border),
            ),
            alignment: Alignment.center,
            child: FaIcon(icon, size: iconSize, color: onDark ? Colors.white : c.text),
          ),
          if (badge != null) Positioned(top: 4, right: 4, child: badge!),
        ],
      ),
    );
  }
}
