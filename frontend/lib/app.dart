import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/l10n.dart';
import 'core/nav.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'state/app_state.dart';
import 'ui/screens/main_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/widgets/offline_banner.dart';

class SlipNowApp extends StatelessWidget {
  const SlipNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.select<AppState, bool>((s) => s.darkMode);
    final brand = context.select<AppState, BrandTheme>((s) => s.brand);
    final language = context.select<AppState, AppLanguage>((s) => s.language);

    return MaterialApp(
      title: 'SlipNow',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.build(dark: dark, brand: brand),
      builder: (context, child) => LangScope(
        language: language,
        child: _BrandStatusBar(child: Stack(children: [child!, const OfflineBanner()])),
      ),
      home: const _InitialScreen(),
    );
  }
}

/// Paints the brand green behind the system status bar. Android 15+ enforces
/// edge-to-edge and ignores `statusBarColor`, so the colour is drawn here.
class _BrandStatusBar extends StatelessWidget {
  const _BrandStatusBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final green = c.isDark ? c.primaryDark : c.primary;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: green,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Stack(
        children: [
          child,
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top,
            child: IgnorePointer(child: ColoredBox(color: green)),
          ),
        ],
      ),
    );
  }
}

/// Picks the first screen once at launch; later navigation is explicit.
class _InitialScreen extends StatelessWidget {
  const _InitialScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    if (!state.onboardingSeen) return const OnboardingScreen();
    if (state.user != null) return const MainShell();
    return const SplashScreen();
  }
}
