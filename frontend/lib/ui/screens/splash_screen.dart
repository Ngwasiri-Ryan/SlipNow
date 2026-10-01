import 'dart:async';

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
import '../widgets/pressable.dart';
import 'auth_screens.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _logoTaps = 0;
  Timer? _tapTimer;

  @override
  void dispose() {
    _tapTimer?.cancel();
    super.dispose();
  }

  void _onLogoTap() {
    _logoTaps++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_logoTaps == 3) showThemePanel(context);
      _logoTaps = 0;
    });
    if (_logoTaps >= 5) {
      _tapTimer?.cancel();
      _logoTaps = 0;
      _resetDemo();
    }
  }

  Future<void> _resetDemo() async {
    Toast.show('Demo reset — restarting...', ToastType.warn);
    await context.read<AppState>().resetDemo();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) context.replaceAll(const OnboardingScreen());
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.4, -1),
              end: Alignment(0.4, 1),
              colors: [Color(0xFF1B4D3E), Color(0xFF0F2E25)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -100, right: -100, child: _circle(320, const Color(0xFFF2A93B).withValues(alpha: 0.18))),
              Positioned(bottom: -80, left: -80, child: _circle(260, Colors.white.withValues(alpha: 0.06))),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 40, 30, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Pressable(
                        onTap: _onLogoTap,
                        scale: 0.94,
                        haptic: false,
                        semanticLabel: 'SlipNow logo',
                        child: Container(
                          width: 72,
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2A93B),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF2A93B).withValues(alpha: 0.35),
                                blurRadius: 32,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const FaIcon(FontAwesomeIcons.bolt, size: 32, color: AppColors.onAccent),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        context.tr('Your GCE grades. Without the trip.', 'Vos notes GCE. Sans le déplacement.'),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          letterSpacing: -0.9,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 310),
                        child: Text(
                          context.tr(
                            'See your full subject grades and download your official result slip, right from your phone.',
                            'Consultez toutes vos notes et téléchargez votre relevé officiel, depuis votre téléphone.',
                          ),
                          style: TextStyle(fontSize: 15, height: 1.6, color: Colors.white.withValues(alpha: 0.82)),
                        ),
                      ),
                      const Spacer(),
                      AppButton(
                        label: context.tr('Create account', 'Créer un compte'),
                        variant: ButtonVariant.white,
                        onPressed: () => context.push(const SignupScreen()),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: context.tr('I already have one', "J'en ai déjà un"),
                        variant: ButtonVariant.outlineWhite,
                        onPressed: () => context.push(const LoginScreen()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

/// Hidden presentation-mode panel for switching the brand palette.
Future<void> showThemePanel(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xFF0F1F1A).withValues(alpha: 0.85),
    builder: (context) {
      final c = context.colors;
      final current = context.watch<AppState>().brand;
      return Dialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose a theme',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c.text),
                ),
                const SizedBox(height: 6),
                Text('Hidden debug panel · presentation mode', style: TextStyle(fontSize: 12.5, color: c.text2)),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final t in BrandTheme.values)
                      Pressable(
                        onTap: () {
                          context.read<AppState>().setBrand(t);
                          Toast.show('Theme ${t.index + 1} applied', ToastType.success);
                        },
                        semanticLabel: 'Theme ${t.index + 1}',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: t == current ? c.text : Colors.transparent, width: 3),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [t.primary, t.primaryDark],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                AppButton(label: 'Close', variant: ButtonVariant.ghost, onPressed: () => Navigator.of(context).pop()),
              ],
            ),
          ),
        ),
      );
    },
  );
}
