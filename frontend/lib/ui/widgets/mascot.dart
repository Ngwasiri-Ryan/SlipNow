import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum MascotEmotion { smart, focus, wink, inspired }

class _Face {
  const _Face(this.leftEye, this.rightEye, this.mouth, {this.mouthFilled = false});
  final String leftEye;
  final String rightEye;
  final String mouth;
  final bool mouthFilled;
}

const _faces = {
  MascotEmotion.smart: _Face('M124 82 Q136 68 148 82', 'M172 82 Q184 68 196 82', 'M152 95 Q160 101 168 95'),
  MascotEmotion.focus: _Face('M124 76 L148 76', 'M172 76 L196 76', 'M152 94 Q160 100 168 94'),
  MascotEmotion.wink: _Face('M124 78 L148 78', 'M172 82 Q184 68 196 82', 'M152 95 Q160 101 168 95'),
  MascotEmotion.inspired: _Face(
    'M124 74 L136 84 L148 74',
    'M172 74 L184 84 L196 74',
    'M150 92 Q160 106 170 92 Z',
    mouthFilled: true,
  ),
};

String _svg(MascotEmotion emotion, bool blink) {
  final f = _faces[emotion]!;
  String eye(String d, int cx) {
    final t = blink ? ' transform="translate($cx 78) scale(1 0.08) translate(-$cx -78)"' : '';
    return '<path d="$d" fill="none" stroke="#F2A93B" stroke-width="6" stroke-linecap="round"$t/>';
  }

  return '''
<svg viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg">
  <ellipse cx="160" cy="236" rx="38" ry="10" fill="#F2A93B" opacity="0.35"/>
  <rect x="136" y="226" width="48" height="10" rx="5" fill="#0F1F1A" stroke="#0a1410" stroke-width="3"/>
  <ellipse cx="160" cy="231" rx="18" ry="4" fill="#F2A93B"/>
  <path d="M100 150 C100 120 220 120 220 150 L225 210 C225 228 200 236 160 236 C120 236 95 228 95 210 L100 150 Z" fill="#1B4D3E" stroke="#123529" stroke-width="7" stroke-linejoin="round"/>
  <rect x="120" y="152" width="80" height="64" rx="14" fill="#FFFFFF" stroke="#E4EBE8" stroke-width="4"/>
  <rect x="126" y="158" width="68" height="52" rx="10" fill="#F7F9F8" stroke="#E6F0EC" stroke-width="2"/>
  <text x="156" y="188" font-family="Nunito, sans-serif" font-weight="900" font-size="17" fill="#1B4D3E" text-anchor="middle">SLIP</text>
  <text x="156" y="204" font-family="Nunito, sans-serif" font-weight="900" font-size="13" fill="#F2A93B" text-anchor="middle">NOW</text>
  <circle cx="182" cy="168" r="3.5" fill="#F2A93B"/>
  <line x1="132" y1="208" x2="188" y2="208" stroke="#F2A93B" stroke-width="2.5" stroke-linecap="round"/>
  <path d="M98 165 Q70 175 60 195" fill="none" stroke="#1B4D3E" stroke-width="12" stroke-linecap="round"/>
  <path d="M98 165 Q70 175 60 195" fill="none" stroke="#123529" stroke-width="5" stroke-linecap="round"/>
  <circle cx="58" cy="198" r="10" fill="#0F1F1A" stroke="#1B4D3E" stroke-width="3"/>
  <rect x="35" y="185" width="30" height="8" rx="3" fill="#5A6B65" stroke="#0F1F1A" stroke-width="2" transform="rotate(-30 35 185)"/>
  <polygon points="26,183 32,179 33,187" fill="#F2A93B"/>
  <path d="M222 165 Q250 175 260 195" fill="none" stroke="#1B4D3E" stroke-width="12" stroke-linecap="round"/>
  <path d="M222 165 Q250 175 260 195" fill="none" stroke="#123529" stroke-width="5" stroke-linecap="round"/>
  <g transform="translate(245, 175) rotate(12)">
    <rect x="0" y="0" width="32" height="42" rx="4" fill="#0F1F1A" stroke="#0a1410" stroke-width="3"/>
    <rect x="4" y="4" width="24" height="34" rx="2" fill="#FFFFFF"/>
    <text x="16" y="22" font-family="Nunito, sans-serif" font-weight="900" font-size="10" fill="#1B4D3E" text-anchor="middle">GCE</text>
    <line x1="8" y1="28" x2="24" y2="28" stroke="#F2A93B" stroke-width="2" stroke-linecap="round"/>
    <line x1="10" y1="33" x2="22" y2="33" stroke="#E4EBE8" stroke-width="1.5" stroke-linecap="round"/>
  </g>
  <path d="M110 148 L215 220" stroke="#0F1F1A" stroke-width="6" stroke-linecap="round"/>
  <rect x="200" y="198" width="28" height="24" rx="6" fill="#2A3833" stroke="#0F1F1A" stroke-width="3"/>
  <circle cx="214" cy="210" r="3" fill="#F2A93B"/>
  <rect x="142" y="122" width="36" height="14" rx="5" fill="#8A9A94" stroke="#5A6B65" stroke-width="3"/>
  <path d="M90 85 C90 35 230 35 230 85 C230 128 90 128 90 85 Z" fill="#1B4D3E" stroke="#123529" stroke-width="7" stroke-linejoin="round"/>
  <path d="M115 52 Q160 42 205 52" fill="none" stroke="#2E9E6B" stroke-width="5" stroke-linecap="round"/>
  <rect x="74" y="68" width="18" height="32" rx="8" fill="#0F1F1A" stroke="#1B4D3E" stroke-width="4"/>
  <rect x="228" y="68" width="18" height="32" rx="8" fill="#0F1F1A" stroke="#1B4D3E" stroke-width="4"/>
  <rect x="106" y="54" width="108" height="62" rx="20" fill="#0F1F1A" stroke="#1B4D3E" stroke-width="3.5"/>
  ${eye(f.leftEye, 136)}
  ${eye(f.rightEye, 184)}
  <path d="${f.mouth}" fill="${f.mouthFilled ? '#F2A93B' : 'none'}" stroke="#F2A93B" stroke-width="4" stroke-linecap="round"/>
  <circle cx="120" cy="94" r="4" fill="#F2A93B" opacity="0.4"/>
  <circle cx="200" cy="94" r="4" fill="#F2A93B" opacity="0.4"/>
  <line x1="160" y1="36" x2="160" y2="20" stroke="#8A9A94" stroke-width="5" stroke-linecap="round"/>
  <ellipse cx="160" cy="18" rx="28" ry="7" fill="none" stroke="#F2A93B" stroke-width="5"/>
</svg>''';
}

/// Floating robot mascot. Bumping [bounceTick] triggers a hop.
class Mascot extends StatefulWidget {
  const Mascot({super.key, required this.emotion, this.size = 230, this.bounceTick = 0, this.onTap});

  final MascotEmotion emotion;
  final double size;
  final int bounceTick;
  final VoidCallback? onTap;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(vsync: this, duration: const Duration(seconds: 2))
    ..repeat(reverse: true);

  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  final _random = math.Random();
  Timer? _blinkTimer;
  bool _blink = false;

  @override
  void initState() {
    super.initState();
    _scheduleBlink();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(Duration(milliseconds: 2200 + _random.nextInt(3000)), () {
      if (!mounted) return;
      setState(() => _blink = true);
      _blinkTimer = Timer(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        setState(() => _blink = false);
        _scheduleBlink();
      });
    });
  }

  @override
  void didUpdateWidget(Mascot old) {
    super.didUpdateWidget(old);
    if (old.bounceTick != widget.bounceTick) {
      _bounce.forward(from: 0).then((_) {
        if (mounted) _bounce.reverse();
      });
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _float.dispose();
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final floatAnim = CurvedAnimation(parent: _float, curve: Curves.easeInOut);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedBuilder(
              animation: Listenable.merge([floatAnim, _bounce]),
              builder: (_, child) {
                final f = floatAnim.value;
                final b = Curves.easeOut.transform(_bounce.value);
                return Transform.translate(
                  offset: Offset(0, -14 * f - 14 * b),
                  child: Transform.rotate(
                    angle: f * math.pi / 180,
                    child: Transform.scale(scale: 1 + 0.06 * b, child: child),
                  ),
                );
              },
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4D3E).withValues(alpha: 0.12),
                        blurRadius: 40,
                        spreadRadius: -20,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: SvgPicture.string(_svg(widget.emotion, _blink), semanticsLabel: 'SlipNow mascot'),
                ),
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: floatAnim,
          builder: (_, _) {
            final f = floatAnim.value;
            return Transform.translate(
              offset: const Offset(0, -10),
              child: Transform.scale(
                scale: 1 - 0.18 * f,
                child: Container(
                  width: widget.size * 0.65,
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF1B4D3E).withValues(alpha: 0.28 - 0.16 * f), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
