import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/l10n.dart';
import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'app_button.dart';
import 'pressable.dart';

const kScreenPadding = EdgeInsets.symmetric(horizontal: 22);

/// Back button + centred title, used on pushed screens.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      child: Row(
        children: [
          CircleIconButton(
            icon: FontAwesomeIcons.arrowLeft,
            semanticLabel: context.tr('Back', 'Retour'),
            onPressed: onBack ?? () => context.pop(),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: c.text),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Small grey eyebrow + large title, used at the top of tab screens.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.eyebrow, required this.title, this.trailing, this.bottomPadding = 20});

  final String eyebrow;
  final String title;
  final Widget? trailing;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 20, 22, bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text2),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    height: 1.2,
                    color: c.text,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A pushed (non-tab) screen: top bar + scrollable padded body, with an
/// optional sticky [bottomBar].
class SubScreen extends StatefulWidget {
  const SubScreen({super.key, required this.title, required this.children, this.onBack, this.bottomBar});

  final String title;
  final List<Widget> children;
  final VoidCallback? onBack;
  final Widget? bottomBar;

  @override
  State<SubScreen> createState() => _SubScreenState();
}

class _SubScreenState extends State<SubScreen> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0) {
      final scrolled = n.metrics.pixels > 4;
      if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottomPad = widget.bottomBar != null ? 24.0 : 32 + MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(bottom: BorderSide(color: _scrolled ? c.border : c.border.withValues(alpha: 0))),
              ),
              child: TopBar(title: widget.title, onBack: widget.onBack),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _onScroll,
                child: ListView(padding: EdgeInsets.fromLTRB(22, 0, 22, bottomPad), children: widget.children),
              ),
            ),
            ?widget.bottomBar,
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: 14),
    this.animate = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
        boxShadow: c.shadowSm,
      ),
      child: child,
    );
    if (onTap != null) card = Pressable(onTap: onTap, scale: 0.98, child: card);
    return animate ? FadeSlideIn(child: card) : card;
  }
}

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400) + delay,
      curve: Interval(delay.inMilliseconds / (400 + delay.inMilliseconds), 1, curve: Curves.easeOutCubic),
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, this.value, this.valueWidget, this.valueColor, this.last = false});

  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color? valueColor;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.text2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  valueWidget ??
                  Text(
                    value ?? '',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor ?? c.text),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class StreamBadge extends StatelessWidget {
  const StreamBadge(this.text, {super.key, this.margin = const EdgeInsets.only(bottom: 10)});

  final String text;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: c.onAccentSoft),
      ),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 18,
    this.background,
    this.foreground,
    this.radius = AppRadius.sm,
  });

  final FaIconData icon;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? foreground;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background ?? c.primarySoft, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: FaIcon(icon, size: iconSize, color: foreground ?? c.primary),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});

  final FaIconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          IconTile(icon: icon, size: 80, iconSize: 32, radius: 40),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: c.text),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.55, color: c.text2),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 22),
            ConstrainedBox(constraints: const BoxConstraints(maxWidth: 240), child: action),
          ],
        ],
      ),
    );
  }
}

class GradeChip extends StatelessWidget {
  const GradeChip(this.grade, {super.key});

  final String grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 36),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: GradeColors.of(grade), borderRadius: BorderRadius.circular(6)),
      child: Text(
        grade,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: Colors.white),
      ),
    );
  }
}

/// Primary-coloured gradient card with the decorative accent circle.
class HeroGradientCard extends StatelessWidget {
  const HeroGradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(22, 26, 22, 26),
    this.circleSize = 180,
  });

  final Widget child;
  final EdgeInsets padding;
  final double circleSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primary, c.isDark ? c.primaryDark : Color.lerp(c.primaryDark, AppColors.heroEnd, 0.5)!],
        ),
        boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.28), blurRadius: 32, offset: const Offset(0, 12))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            Positioned(
              top: -circleSize * 0.28,
              right: -circleSize * 0.28,
              child: Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent.withValues(alpha: 0.22)),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.1, color: c.text),
            ),
          ),
          if (actionLabel != null)
            Pressable(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.primary),
              ),
            ),
        ],
      ),
    );
  }
}

class HelperText extends StatelessWidget {
  const HelperText({super.key, required this.text, this.linkText, this.onLink});

  final String text;
  final String? linkText;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: c.text3),
          ),
          if (linkText != null) ...[
            const SizedBox(width: 4),
            Pressable(
              onTap: onLink,
              child: Text(
                linkText!,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class Paragraph extends StatelessWidget {
  const Paragraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(text, style: TextStyle(fontSize: 13.5, height: 1.6, color: context.colors.text2)),
    );
  }
}
