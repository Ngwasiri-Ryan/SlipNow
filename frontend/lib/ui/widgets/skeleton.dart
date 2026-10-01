import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Sweeps a soft highlight across its [child]'s grey placeholder shapes.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = colors.isDark ? colors.surface2 : const Color(0xFFE9EFEC);
    final highlight = colors.isDark ? colors.borderStrong : const Color(0xFFF7FAF8);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final dx = rect.width * (_c.value * 2 - 0.5);
          return LinearGradient(
            colors: [base, highlight, base],
            stops: const [0.25, 0.5, 0.75],
            transform: _SlideGradient(dx),
          ).createShader(rect);
        },
        child: child,
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx - bounds.width / 2, 0, 0);
}

/// A rounded placeholder block, meant to sit inside a [Shimmer].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius)),
  );
}

/// Placeholder shaped like a search-result card.
class SkeletonResultCard extends StatelessWidget {
  const SkeletonResultCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: const Shimmer(
        child: Row(
          children: [
            SkeletonBox(width: 44, height: 57, radius: 8),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 64, height: 18, radius: 100),
                  SizedBox(height: 10),
                  SkeletonBox(width: 170, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 210, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
