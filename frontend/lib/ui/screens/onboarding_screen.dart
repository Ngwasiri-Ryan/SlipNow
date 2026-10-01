import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/feedback.dart';
import '../widgets/mascot.dart';
import '../widgets/pressable.dart';
import 'main_shell.dart';
import 'splash_screen.dart';

class _Step {
  const _Step(this.eyebrow, this.title, this.desc, this.bubble, this.emotion);
  final (String, String) eyebrow;
  final (String, String) title;
  final (String, String) desc;
  final (String, String) bubble;
  final MascotEmotion emotion;
}

const _steps = [
  _Step(
    ('Step 1 of 3', 'Étape 1 sur 3'),
    ('Find your name', 'Trouvez votre nom'),
    (
      'Search by name or candidate number to locate your GCE result slip.',
      'Recherchez par nom ou numéro de candidat pour trouver votre relevé GCE.',
    ),
    ('Ready to find your slip?', 'Prêt à trouver votre relevé ?'),
    MascotEmotion.smart,
  ),
  _Step(
    ('Step 2 of 3', 'Étape 2 sur 3'),
    ('Pay with Mobile Money', 'Payez avec Mobile Money'),
    (
      'Pay 1,000 FCFA via MTN MoMo or Orange Money. Dial a USSD code, done in seconds.',
      "Payez 1 000 FCFA via MTN MoMo ou Orange Money. Un code USSD, c'est fait.",
    ),
    ('Pay in seconds with MoMo or Orange', 'Payez en secondes avec MoMo ou Orange'),
    MascotEmotion.wink,
  ),
  _Step(
    ('Step 3 of 3', 'Étape 3 sur 3'),
    ('Download your slip', 'Téléchargez votre relevé'),
    (
      'Get your slip as a PDF. Share it, print it, use it for admissions and scholarships.',
      'Obtenez votre relevé en PDF. Partagez, imprimez, utilisez-le pour admissions et bourses.',
    ),
    ('Your official slip, in your pocket', 'Votre relevé officiel, dans votre poche'),
    MascotEmotion.inspired,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _random = math.Random();
  late final AnimationController _blobs = AnimationController(vsync: this, duration: const Duration(seconds: 9))
    ..repeat(reverse: true);

  int _step = 0;
  bool _forward = true;
  MascotEmotion _emotion = MascotEmotion.smart;
  int _bounceTick = 0;
  String? _bubbleOverride;
  bool _bubbleDim = false;
  bool _finishing = false;
  Timer? _moodTimer;
  Timer? _pokeTimer;

  _Step get _current => _steps[_step];
  bool get _isLast => _step == _steps.length - 1;

  @override
  void initState() {
    super.initState();
    _scheduleMood();
  }

  @override
  void dispose() {
    _moodTimer?.cancel();
    _pokeTimer?.cancel();
    _blobs.dispose();
    super.dispose();
  }

  void _scheduleMood() {
    _moodTimer = Timer(Duration(milliseconds: 6000 + _random.nextInt(3000)), () {
      if (!mounted) return;
      if (_random.nextBool()) {
        setState(() => _emotion = MascotEmotion.values[_random.nextInt(4)]);
        _moodTimer = Timer(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          setState(() => _emotion = _current.emotion);
          _scheduleMood();
        });
      } else {
        _scheduleMood();
      }
    });
  }

  Future<void> _swapBubble(VoidCallback change) async {
    setState(() => _bubbleDim = true);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() {
      change();
      _bubbleDim = false;
    });
  }

  void _goTo(int step) {
    HapticFeedback.lightImpact();
    _pokeTimer?.cancel();
    setState(() {
      _forward = step > _step;
      _step = step;
      _emotion = _steps[step].emotion;
      _bounceTick++;
    });
    _swapBubble(() => _bubbleOverride = null);
  }

  void _next() {
    if (_isLast) {
      _finish(celebrate: true);
    } else {
      _goTo(_step + 1);
    }
  }

  void _poke() {
    HapticFeedback.mediumImpact();
    _pokeTimer?.cancel();
    setState(() {
      _bounceTick++;
      _emotion = MascotEmotion.inspired;
    });
    _swapBubble(() => _bubbleOverride = context.tr('Hey! Ready to go', 'Hé ! On y va'));
    _pokeTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      _swapBubble(() {
        _bubbleOverride = null;
        _emotion = _current.emotion;
      });
    });
  }

  Future<void> _finish({required bool celebrate}) async {
    if (_finishing) return;
    _finishing = true;
    final state = context.read<AppState>();
    state.completeOnboarding();
    if (celebrate) {
      Confetti.fire();
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }
    if (!mounted) return;
    context.replaceAll(state.user != null ? const MainShell() : const SplashScreen());
  }

  String _t((String, String) pair) => context.tr(pair.$1, pair.$2);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final language = context.select<AppState, AppLanguage>((s) => s.language);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _header(c, language),
            Expanded(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  _blobsLayer(),
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (d) {
                      final v = d.primaryVelocity ?? 0;
                      if (v < -250 && !_isLast) _goTo(_step + 1);
                      if (v > 250 && _step > 0) _goTo(_step - 1);
                    },
                    child: LayoutBuilder(
                      builder: (context, box) => Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(width: math.min(box.maxWidth, 380), child: _mainColumn(c)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _footer(c),
          ],
        ),
      ),
    );
  }

  Widget _header(AppColors c, AppLanguage language) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
      child: Row(
        children: [
          const BrandMark(),
          const Spacer(),
          Pressable(
            onTap: () {
              context.read<AppState>().toggleLanguage();
              _swapBubble(() {});
            },
            semanticLabel: 'Toggle language',
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(FontAwesomeIcons.globe, size: 10, color: c.primary),
                  const SizedBox(width: 6),
                  Text(
                    language.code,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: c.text2),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _isLast
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: CircleIconButton(
                      icon: FontAwesomeIcons.xmark,
                      size: 36,
                      iconSize: 14,
                      semanticLabel: context.tr('Skip onboarding', "Passer l'introduction"),
                      onPressed: () => _finish(celebrate: false),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _blobsLayer() {
    return AnimatedBuilder(
      animation: _blobs,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_blobs.value);
        return Stack(
          children: [
            Positioned(
              top: -100 - 24 * t,
              left: -100 + 24 * t,
              child: _blob(280, const Color(0xFF1B4D3E).withValues(alpha: 0.22), 1 + 0.1 * t),
            ),
            Positioned(
              bottom: 40 + 24 * (1 - t),
              right: -80 - 24 * (1 - t),
              child: _blob(220, const Color(0xFFF2A93B).withValues(alpha: 0.28), 1.1 - 0.1 * t),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color, double scale) => IgnorePointer(
    child: Transform.scale(
      scale: scale,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Opacity(
          opacity: 0.55,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    ),
  );

  List<Widget> _floatingBadges(AppColors c) {
    final (a, b) = switch (_step) {
      0 => (
        (FontAwesomeIcons.magnifyingGlass, 'Njuh B…', c.primary),
        (FontAwesomeIcons.idCard, '05210417', c.accentDark),
      ),
      1 => (
        (FontAwesomeIcons.mobileScreen, 'MoMo · Orange', const Color(0xFFFF7900)),
        (FontAwesomeIcons.coins, context.tr('1,000 FCFA', '1 000 FCFA'), c.accentDark),
      ),
      _ => (
        (FontAwesomeIcons.filePdf, 'PDF', c.danger),
        (FontAwesomeIcons.shareNodes, context.tr('Share', 'Partager'), c.success),
      ),
    };
    Widget badge((FaIconData, String, Color) spec, {required bool left}) => AnimatedBuilder(
      animation: _blobs,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_blobs.value);
        return Transform.translate(offset: Offset(0, (left ? t - 0.5 : 0.5 - t) * 14), child: child);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) => ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: _FloatBadge(key: ValueKey('$_step-$left'), icon: spec.$1, label: spec.$2, tint: spec.$3),
      ),
    );
    return [
      Positioned(left: -44, top: 34, child: IgnorePointer(child: badge(a, left: true))),
      Positioned(right: -44, bottom: 40, child: IgnorePointer(child: badge(b, left: false))),
    ];
  }

  Widget _mainColumn(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            opacity: _bubbleDim ? 0 : 1,
            duration: const Duration(milliseconds: 200),
            child: AnimatedScale(
              scale: _bubbleDim ? 0.92 : 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: SpeechBubble(text: _bubbleOverride ?? _t(_current.bubble)),
            ),
          ),
          const SizedBox(height: 4),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Mascot(emotion: _emotion, bounceTick: _bounceTick, onTap: _poke),
              ..._floatingBadges(c),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
            transitionBuilder: (child, anim) {
              final incoming = child.key == ValueKey('$_step-${context.isFr}');
              final dx = _forward ? 0.2 : -0.2;
              final slide = Tween(
                begin: Offset(incoming ? dx : -dx, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: Column(
              key: ValueKey('$_step-${context.isFr}'),
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
                  child: Text(
                    _t(_current.eyebrow).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: c.isDark ? const Color(0xFFF0D9A8) : c.accentDark,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _t(_current.title),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.2,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    _t(_current.desc),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.6, color: c.text2),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _steps.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _step ? 26 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _step ? c.primary : c.borderStrong,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      child: Row(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _step == 0
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Pressable(
                      onTap: () => _goTo(_step - 1),
                      semanticLabel: context.tr('Previous step', 'Étape précédente'),
                      child: Container(
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.surface,
                          border: Border.all(color: c.border, width: 1.5),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: FaIcon(FontAwesomeIcons.arrowLeft, size: 16, color: c.text),
                      ),
                    ),
                  ),
          ),
          Expanded(
            child: AppButton(
              label: _isLast ? context.tr('Get started', 'Commencer') : context.tr('Next', 'Suivant'),
              trailingIcon: FontAwesomeIcons.arrowRight,
              onPressed: _next,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatBadge extends StatelessWidget {
  const _FloatBadge({super.key, required this.icon, required this.label, required this.tint});

  final FaIconData icon;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.border),
        boxShadow: c.shadowMd,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: FaIcon(icon, size: 12, color: tint),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.text),
          ),
        ],
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c.primary, c.primaryDark],
            ),
            boxShadow: [
              BoxShadow(color: c.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent.withValues(alpha: 0.6)),
                  ),
                ),
                const Center(child: FaIcon(FontAwesomeIcons.bolt, size: 15, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('SlipNow', style: AppTheme.brand(color: c.primary)),
      ],
    );
  }
}

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 290),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.primary, width: 3),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: c.primary.withValues(alpha: 0.14), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTheme.brand(
              size: 14,
              color: c.text,
            ).copyWith(fontWeight: FontWeight.w800, height: 1.4, letterSpacing: -0.1),
          ),
        ),
        CustomPaint(size: const Size(24, 14), painter: _TailPainter(c.primary, c.surface)),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.border, this.fill);

  final Color border;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()
      ..moveTo(0, -1)
      ..lineTo(size.width, -1)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(outer, Paint()..color = border);
    final inner = Path()
      ..moveTo(size.width / 2 - 9, -4)
      ..lineTo(size.width / 2 + 9, -4)
      ..lineTo(size.width / 2, size.height - 6)
      ..close();
    canvas.drawPath(inner, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.border != border || old.fill != fill;
}
