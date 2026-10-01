import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum ToastType { success, warn, error, info }

/// Pill-shaped toast shown above the tab bar. Only one is visible at a time.
class Toast {
  static OverlayEntry? _entry;
  static Timer? _timer;
  static final _visible = ValueNotifier(false);

  static void show(String message, [ToastType type = ToastType.info]) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _timer?.cancel();
    _entry?.remove();
    _visible.value = false;
    _entry = OverlayEntry(
      builder: (_) => _ToastView(message: message, type: type, visible: _visible),
    );
    overlay.insert(_entry!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _visible.value = true);
    _timer = Timer(const Duration(milliseconds: 2400), () {
      _visible.value = false;
      _timer = Timer(const Duration(milliseconds: 300), () {
        _entry?.remove();
        _entry = null;
      });
    });
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({required this.message, required this.type, required this.visible});

  final String message;
  final ToastType type;
  final ValueNotifier<bool> visible;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (icon, iconColor) = switch (type) {
      ToastType.success => (FontAwesomeIcons.circleCheck, const Color(0xFF4CB885)),
      ToastType.warn => (FontAwesomeIcons.triangleExclamation, const Color(0xFFF2A93B)),
      ToastType.error => (FontAwesomeIcons.circleXmark, const Color(0xFFE57570)),
      ToastType.info => (FontAwesomeIcons.circleInfo, c.isDark ? c.text : c.bg),
    };
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100 + MediaQuery.paddingOf(context).bottom,
      child: IgnorePointer(
        child: ValueListenableBuilder(
          valueListenable: visible,
          builder: (_, shown, child) => AnimatedSlide(
            offset: shown ? Offset.zero : const Offset(0, 0.4),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            child: AnimatedOpacity(opacity: shown ? 1 : 0, duration: const Duration(milliseconds: 200), child: child),
          ),
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.9),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: c.isDark ? c.surface : c.text,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: c.isDark ? Border.all(color: c.border) : null,
                  boxShadow: c.shadowLg,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(icon, size: 14, color: iconColor),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.isDark ? c.text : c.bg),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-screen confetti burst that removes itself when done.
class Confetti {
  static void fire() {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _ConfettiView(onDone: () => entry.remove()));
    overlay.insert(entry);
  }
}

class _Piece {
  _Piece(math.Random r)
    : x = r.nextDouble(),
      delay = r.nextDouble() * 0.5,
      rotation = r.nextDouble() * math.pi * 2,
      size = 6 + r.nextDouble() * 8,
      circle = r.nextBool(),
      color = _colors[r.nextInt(_colors.length)];

  static const _colors = [
    Color(0xFFF2A93B),
    Color(0xFF2E9E6B),
    Color(0xFF1B4D3E),
    Color(0xFFD68F1F),
    Color(0xFFE57570),
    Color(0xFF4CB885),
  ];

  final double x;
  final double delay;
  final double rotation;
  final double size;
  final bool circle;
  final Color color;
}

class _ConfettiView extends StatefulWidget {
  const _ConfettiView({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_ConfettiView> createState() => _ConfettiViewState();
}

class _ConfettiViewState extends State<_ConfettiView> with SingleTickerProviderStateMixin {
  static const _totalSeconds = 2.6;
  static const _fallSeconds = 2.0;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_totalSeconds * 1000).round()),
  )..forward().whenComplete(widget.onDone);

  final _pieces = List.generate(32, (_) => _Piece(math.Random()));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_pieces, _c.value * _totalSeconds, _fallSeconds),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.seconds, this.fall);

  final List<_Piece> pieces;
  final double seconds;
  final double fall;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final t = ((seconds - p.delay) / fall).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final eased = Curves.easeOut.transform(t);
      final paint = Paint()..color = p.color.withValues(alpha: 1 - eased);
      final s = p.size * (1 - 0.4 * eased);
      canvas.save();
      canvas.translate(p.x * size.width, size.height * 0.2 + 420 * eased);
      canvas.rotate(p.rotation + eased * math.pi * 4);
      final rect = Rect.fromCenter(center: Offset.zero, width: s, height: s);
      if (p.circle) {
        canvas.drawOval(rect, paint);
      } else {
        canvas.drawRect(rect, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.seconds != seconds;
}
