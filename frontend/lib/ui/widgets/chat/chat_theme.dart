import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Colours for the chat room, derived from the active brand theme so the
/// conversation matches Forest, Navy, Teal or Plum in light and dark mode.
class ChatPalette {
  const ChatPalette({
    required this.wallpaper,
    required this.doodle,
    required this.outgoing,
    required this.incoming,
    required this.text,
    required this.meta,
    required this.quoteMine,
    required this.quoteTheirs,
    required this.chip,
    required this.chipText,
    required this.header,
  });

  final Color wallpaper;
  final Color doodle;
  final Color outgoing;
  final Color incoming;
  final Color text;
  final Color meta;
  final Color quoteMine;
  final Color quoteTheirs;
  final Color chip;
  final Color chipText;
  final Color header;

  static const readBlue = Color(0xFF53BDEB);
  static const online = Color(0xFF25D366);

  factory ChatPalette.of(AppColors c) => c.isDark
      ? ChatPalette(
          wallpaper: const Color(0xFF0B1411),
          doodle: Colors.white.withValues(alpha: 0.035),
          outgoing: Color.alphaBlend(c.primary.withValues(alpha: 0.42), const Color(0xFF14231E)),
          incoming: const Color(0xFF1C2B26),
          text: c.text,
          meta: Colors.white.withValues(alpha: 0.55),
          quoteMine: Colors.black.withValues(alpha: 0.22),
          quoteTheirs: Colors.black.withValues(alpha: 0.22),
          chip: const Color(0xFF1C2B26),
          chipText: c.text2,
          header: c.primaryDark,
        )
      : ChatPalette(
          wallpaper: Color.alphaBlend(c.primary.withValues(alpha: 0.05), const Color(0xFFEFEAE2)),
          doodle: Colors.black.withValues(alpha: 0.045),
          outgoing: Color.alphaBlend(c.primary.withValues(alpha: 0.15), const Color(0xFFF6FFF4)),
          incoming: Colors.white,
          text: c.text,
          meta: c.text3,
          quoteMine: c.primary.withValues(alpha: 0.08),
          quoteTheirs: Colors.black.withValues(alpha: 0.045),
          chip: Colors.white,
          chipText: c.text2,
          header: c.primary,
        );
}

/// WhatsApp-style doodle wallpaper built from school-themed outline icons.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, required this.color, required this.doodle});

  final Color color;
  final Color doodle;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ColoredBox(
      color: color,
      child: CustomPaint(painter: _DoodlePainter(doodle), size: Size.infinite),
    ),
  );
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter(this.color)
    : _glyphs = [
        for (final icon in _icons)
          TextPainter(
            text: TextSpan(
              text: String.fromCharCode(icon.codePoint),
              style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 22, color: color),
            ),
            textDirection: TextDirection.ltr,
          )..layout(),
      ];

  final Color color;
  final List<TextPainter> _glyphs;

  static const _icons = [
    Icons.school_outlined,
    Icons.menu_book_outlined,
    Icons.edit_outlined,
    Icons.star_border_rounded,
    Icons.lightbulb_outline_rounded,
    Icons.emoji_events_outlined,
    Icons.calculate_outlined,
    Icons.science_outlined,
    Icons.celebration_outlined,
    Icons.favorite_border_rounded,
    Icons.chat_bubble_outline_rounded,
    Icons.public_rounded,
    Icons.auto_stories_outlined,
    Icons.workspace_premium_outlined,
  ];

  static const _cell = 64.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    for (var y = -_cell / 2; y < size.height + _cell; y += _cell) {
      for (var x = -_cell / 2; x < size.width + _cell; x += _cell) {
        final glyph = _glyphs[rnd.nextInt(_glyphs.length)];
        final dx = x + rnd.nextDouble() * 22;
        final dy = y + rnd.nextDouble() * 22;
        final scale = 0.75 + rnd.nextDouble() * 0.45;
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate((rnd.nextDouble() - 0.5) * 0.9);
        canvas.scale(scale);
        glyph.paint(canvas, Offset(-glyph.width / 2, -glyph.height / 2));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => old.color != color;
}
