import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_state.dart';
import '../widgets/pressable.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Bottom padding tab screens need so content clears the floating tab bar.
double tabBarClearance(BuildContext context) => 120 + MediaQuery.paddingOf(context).bottom;

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tab = context.select<AppState, AppTab>((s) => s.tab);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: tab == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.read<AppState>().setTab(AppTab.home);
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: tab.index,
              children: const [HomeScreen(), SearchScreen(), HistoryScreen(), ProfileScreen()],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 90 + bottomInset,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [c.bg, c.bg.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12 + bottomInset,
              child: _FloatingTabBar(current: tab),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({required this.current});

  final AppTab current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = [
      (AppTab.home, FontAwesomeIcons.house, context.tr('Home', 'Accueil')),
      (AppTab.search, FontAwesomeIcons.magnifyingGlass, context.tr('Search', 'Recherche')),
      (AppTab.history, FontAwesomeIcons.fileLines, context.tr('Slips', 'Relevés')),
      (AppTab.profile, FontAwesomeIcons.user, context.tr('Profile', 'Profil')),
    ];
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.5 : 0.14),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          for (final (tab, icon, label) in items)
            Expanded(
              child: Semantics(
                selected: tab == current,
                child: Pressable(
                  onTap: () => context.read<AppState>().setTab(tab),
                  scale: 0.94,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 14),
                    decoration: BoxDecoration(
                      color: tab == current ? c.primarySoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: tab == current ? 1.1 : 1,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              child: FaIcon(icon, size: 18, color: tab == current ? c.primary : c.text3),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: tab == current ? c.primary : c.text3,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          bottom: -8,
                          child: AnimatedOpacity(
                            opacity: tab == current ? 1 : 0,
                            duration: const Duration(milliseconds: 250),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
