import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Tab-screen scaffold: an eyebrow + large title that collapses into a compact
/// pinned bar with a centred title as the page scrolls.
class CollapsingPage extends StatelessWidget {
  const CollapsingPage({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.children,
    required this.bottomPadding,
    this.trailing,
    this.eyebrowWidget,
    this.beforeList = const [],
    this.controller,
  });

  final String eyebrow;
  final String title;
  final Widget? trailing;

  /// Replaces the plain eyebrow text (e.g. with a step indicator).
  final Widget? eyebrowWidget;

  /// Full-bleed slivers placed between the header and the padded list.
  final List<Widget> beforeList;
  final List<Widget> children;
  final double bottomPadding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        controller: controller,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _LargeTitleDelegate(
              eyebrow: eyebrow,
              eyebrowWidget: eyebrowWidget,
              title: title,
              trailing: trailing,
            ),
          ),
          ...beforeList,
          SliverPadding(
            padding: EdgeInsets.fromLTRB(22, 0, 22, bottomPadding),
            sliver: SliverList.list(children: children),
          ),
        ],
      ),
    );
  }
}

class _LargeTitleDelegate extends SliverPersistentHeaderDelegate {
  _LargeTitleDelegate({required this.eyebrow, required this.title, this.eyebrowWidget, this.trailing});

  final String eyebrow;
  final Widget? eyebrowWidget;
  final String title;
  final Widget? trailing;

  static const _max = 100.0;
  static const _min = 58.0;

  @override
  double get maxExtent => _max;

  @override
  double get minExtent => _min;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final c = context.colors;
    final t = (shrinkOffset / (_max - _min)).clamp(0.0, 1.0);
    final largeOpacity = (1 - t * 1.6).clamp(0.0, 1.0);
    final compactOpacity = ((t - 0.55) / 0.45).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(
          bottom: BorderSide(color: c.border.withValues(alpha: compactOpacity)),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 22,
            right: trailing == null ? 22 : 80,
            bottom: 14,
            child: Opacity(
              opacity: largeOpacity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  eyebrowWidget ??
                      Text(
                        eyebrow,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text2),
                      ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.2,
                        color: c.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (compactOpacity > 0)
            Positioned(
              left: 72,
              right: 72,
              top: 0,
              height: _min,
              child: IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: compactOpacity,
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: c.text),
                    ),
                  ),
                ),
              ),
            ),
          if (trailing != null) Positioned(right: 22, top: lerpDouble(22, 5, t), child: trailing!),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_LargeTitleDelegate old) =>
      old.title != title || old.eyebrow != eyebrow || old.trailing != trailing || old.eyebrowWidget != eyebrowWidget;
}
