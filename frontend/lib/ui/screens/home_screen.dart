import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/chat/support_avatar.dart';
import '../widgets/common.dart';
import '../widgets/feedback.dart';
import '../widgets/pressable.dart';
import '../widgets/skeleton.dart';
import '../widgets/slip_document.dart';
import 'chat_screen.dart';
import 'gce_results_list_screen.dart';
import 'main_shell.dart';
import 'notifications_screen.dart';
import 'pdf_viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.watch<AppState>();
    final hasSlip = s.purchases.isNotEmpty;
    final recent = s.purchases.reversed.take(2).toList();
    final green = c.isDark ? c.primaryDark : c.primary;

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: s.refreshRelease,
        color: c.primary,
        edgeOffset: _HomeHeaderDelegate._max,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HomeHeaderDelegate(
                green: green,
                eyebrow: s.user != null
                    ? '${context.tr('Hi, ', 'Salut, ')}${s.user!.firstName}'
                    : context.tr('Welcome back', 'Bon retour'),
                title: context.tr('Find your results', 'Trouvez vos résultats'),
                bell: CircleIconButton(
                  icon: FontAwesomeIcons.bell,
                  size: 46,
                  iconSize: 17,
                  onDark: true,
                  semanticLabel: context.tr('Notifications', 'Notifications'),
                  onPressed: () => context.push(const NotificationsScreen()),
                  badge: s.unreadCount > 0 ? _Badge(count: s.unreadCount, ring: green) : null,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 76,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: green,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
                    child: _ReleaseCard(
                      release: s.release,
                      hasSlip: hasSlip,
                      alertsOn: s.releaseAlerts,
                      onSearch: () => s.setTab(AppTab.search),
                      onOpenSlips: () => s.setTab(AppTab.history),
                      onToggleAlerts: () {
                        s.toggleReleaseAlerts();
                        Toast.show(
                          s.releaseAlerts
                              ? context.tr(
                                  'We will notify you when results are out',
                                  'Nous vous préviendrons à la publication',
                                )
                              : context.tr('Release alerts turned off', 'Alertes de publication désactivées'),
                          s.releaseAlerts ? ToastType.success : ToastType.info,
                        );
                      },
                      onDebugToggle: kDebugMode && s.release != null
                          ? () => s.debugOverrideRelease(s.release!.copyWith(released: !s.release!.released))
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, tabBarClearance(context)),
              sliver: SliverList.list(
                children: [
                  SectionTitle(context.tr('Quick actions', 'Actions rapides')),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickCard(
                          icon: FontAwesomeIcons.fileLines,
                          label: context.tr('My slips', 'Mes relevés'),
                          caption: s.purchases.isEmpty
                              ? context.tr('None yet', 'Aucun')
                              : context.tr('${s.purchases.length} saved', '${s.purchases.length} enregistré(s)'),
                          onTap: () => s.setTab(AppTab.history),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ListenableBuilder(
                          listenable: s.chat,
                          builder: (context, _) => _QuickCard(
                            icon: FontAwesomeIcons.solidCommentDots,
                            label: context.tr('Live chat', 'Chat en direct'),
                            caption: context.tr('Support is online', 'Support en ligne'),
                            online: true,
                            badge: s.chat.unread,
                            onTap: () => context.push(const ChatScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SectionTitle(
                    context.tr('Recent', 'Récents'),
                    actionLabel: context.tr('View all', 'Tout voir'),
                    onAction: () => s.setTab(AppTab.history),
                  ),
                  if (recent.isEmpty)
                    CustomPaint(
                      foregroundPainter: _DashedBorderPainter(color: c.borderStrong, radius: AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Text(
                          context.tr('No slips yet. Search your name to get started.', 'Aucun relevé pour le moment.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13.5, height: 1.5, color: c.text3),
                        ),
                      ),
                    )
                  else
                    for (final p in recent)
                      InfoCard(
                        padding: const EdgeInsets.all(14),
                        onTap: () =>
                            context.push(PdfViewerScreen(result: p.result, heroTag: 'home-${p.result.slipId}')),
                        child: Row(
                          children: [
                            SlipThumbnail(result: p.result, width: 44, heroTag: 'home-${p.result.slipId}'),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.result.name,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${p.result.stream} · ${p.result.year} · Centre ${p.result.centre}',
                                    style: TextStyle(fontSize: 12, color: c.text2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            FaIcon(FontAwesomeIcons.chevronRight, size: 13, color: c.text3),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Green brand header that continues the status bar colour. It collapses to
/// a compact bar with rounded bottom corners once the page scrolls.
class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({required this.green, required this.eyebrow, required this.title, required this.bell});

  final Color green;
  final String eyebrow;
  final String title;
  final Widget bell;

  static const _max = 104.0;
  static const _min = 60.0;

  @override
  double get maxExtent => _max;

  @override
  double get minExtent => _min;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / (_max - _min)).clamp(0.0, 1.0);
    final largeOpacity = (1 - t * 1.6).clamp(0.0, 1.0);
    final compactOpacity = ((t - 0.55) / 0.45).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: green,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24 * t)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18 * compactOpacity),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 22,
            right: 84,
            bottom: 10,
            child: Opacity(
              opacity: largeOpacity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    eyebrow,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (compactOpacity > 0)
            Positioned(
              left: 22,
              top: 0,
              height: _min,
              child: IgnorePointer(
                child: Opacity(
                  opacity: compactOpacity,
                  child: Center(
                    child: Text('SlipNow', style: AppTheme.brand(size: 20, color: Colors.white)),
                  ),
                ),
              ),
            ),
          Positioned(right: 22, top: lerpDouble(22, 7, t), child: bell),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_HomeHeaderDelegate old) =>
      old.green != green || old.eyebrow != eyebrow || old.title != title || old.bell != bell;
}

/// White card overlapping the curved green header. Tells candidates whether
/// the GCE Board has released the current session's results (set by the
/// admin dashboard) and offers the matching next step.
class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({
    required this.release,
    required this.hasSlip,
    required this.alertsOn,
    required this.onSearch,
    required this.onOpenSlips,
    required this.onToggleAlerts,
    this.onDebugToggle,
  });

  final ResultsRelease? release;
  final bool hasSlip;
  final bool alertsOn;
  final VoidCallback onSearch;
  final VoidCallback onOpenSlips;
  final VoidCallback onToggleAlerts;
  final VoidCallback? onDebugToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = release;
    final tint = r == null ? c.border : (r.released ? c.success : c.warn);

    return GestureDetector(
      onLongPress: onDebugToggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: c.shadowLg,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 150,
                height: 150,
                decoration: BoxDecoration(shape: BoxShape.circle, color: tint.withValues(alpha: 0.12)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: r == null
                      ? const _ReleaseSkeleton()
                      : KeyedSubtree(
                          key: ValueKey(r.released),
                          child: r.released ? _released(context, r) : _pending(context, r),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _released(BuildContext context, ResultsRelease r) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusPill(
              label: context.tr('Released', 'Publiés'),
              color: c.success,
              background: c.successSoft,
              leading: _LiveDot(color: c.success),
            ),
            const SizedBox(width: 8),
            _SessionPill(session: r.session),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          context.tr(
            'The ${r.session} GCE results have been released',
            'Les résultats du GCE ${r.session} sont publiés',
          ),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.28, letterSpacing: -0.4, color: c.text),
        ),
        const SizedBox(height: 6),
        Text(
          hasSlip
              ? context.tr('Your slip is saved and ready anytime.', 'Votre relevé est enregistré et prêt.')
              : context.tr(
                  'Search your name, preview your slip, pay and download it.',
                  'Recherchez votre nom, prévisualisez, payez et téléchargez votre relevé.',
                ),
          style: TextStyle(fontSize: 13.5, height: 1.5, color: c.text2),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            if (r.releasedOn != null)
              _Meta(
                icon: FontAwesomeIcons.calendarCheck,
                text: context.tr(
                  'Released ${context.shortDate(r.releasedOn!)}',
                  'Publiés le ${context.shortDate(r.releasedOn!)}',
                ),
              ),
            if (r.streams.isNotEmpty)
              _Meta(
                icon: FontAwesomeIcons.layerGroup,
                text: context.tr('${r.streams.length} exams available', '${r.streams.length} examens disponibles'),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(
              label: hasSlip
                  ? context.tr('Open my slip', 'Ouvrir mon relevé')
                  : context.tr('Search my results', 'Rechercher mes résultats'),
              icon: hasSlip ? FontAwesomeIcons.filePdf : FontAwesomeIcons.magnifyingGlass,
              variant: ButtonVariant.accent,
              expand: false,
              compact: true,
              onPressed: hasSlip ? onOpenSlips : onSearch,
            ),
            AppButton(
              label: context.tr('View GCE Results', 'Voir les résultats GCE'),
              icon: FontAwesomeIcons.list,
              variant: ButtonVariant.ghost,
              expand: false,
              compact: true,
              onPressed: () => context.push(const GceResultsListScreen()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pending(BuildContext context, ResultsRelease r) {
    final c = context.colors;
    final expected = context.isFr ? r.expectedFr : r.expectedEn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _StatusPill(
              label: context.tr('Not released yet', 'Pas encore publiés'),
              color: c.warn,
              background: c.warnSoft,
              leading: FaIcon(FontAwesomeIcons.hourglassHalf, size: 10, color: c.warn),
            ),
            const SizedBox(width: 8),
            _SessionPill(session: r.session),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          context.tr(
            'The ${r.session} GCE results are not out yet',
            'Les résultats du GCE ${r.session} ne sont pas encore publiés',
          ),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.28, letterSpacing: -0.4, color: c.text),
        ),
        const SizedBox(height: 6),
        Text(
          context.tr(
            'The GCE Board has not published them yet. We will tell you the moment they are released.',
            'Le GCE Board ne les a pas encore publiés. Nous vous préviendrons dès leur publication.',
          ),
          style: TextStyle(fontSize: 13.5, height: 1.5, color: c.text2),
        ),
        if (expected != null) ...[
          const SizedBox(height: 14),
          _Meta(icon: FontAwesomeIcons.calendarDays, text: context.tr('Expected: $expected', 'Prévus : $expected')),
        ],
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(
              label: alertsOn
                  ? context.tr('You will be notified', 'Vous serez prévenu')
                  : context.tr('Notify me when released', 'Me prévenir à la publication'),
              icon: alertsOn ? FontAwesomeIcons.solidBell : FontAwesomeIcons.bell,
              variant: alertsOn ? ButtonVariant.ghost : ButtonVariant.primary,
              expand: false,
              compact: true,
              onPressed: onToggleAlerts,
            ),
            if (hasSlip)
              Pressable(
                onTap: onOpenSlips,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    context.tr('My previous slips', 'Mes relevés précédents'),
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.primary),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReleaseSkeleton extends StatelessWidget {
  const _ReleaseSkeleton();

  @override
  Widget build(BuildContext context) => const Shimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SkeletonBox(width: 92, height: 24, radius: 100),
            SizedBox(width: 8),
            SkeletonBox(width: 96, height: 24, radius: 100),
          ],
        ),
        SizedBox(height: 18),
        SkeletonBox(height: 20),
        SizedBox(height: 8),
        SkeletonBox(width: 200, height: 20),
        SizedBox(height: 14),
        SkeletonBox(width: 240, height: 12),
        SizedBox(height: 20),
        SkeletonBox(width: 180, height: 46, radius: 12),
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, required this.background, required this.leading});

  final String label;
  final Color color;
  final Color background;
  final Widget leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: color),
          ),
        ],
      ),
    );
  }
}

class _SessionPill extends StatelessWidget {
  const _SessionPill({required this.session});

  final String session;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        context.tr('$session session', 'Session $session'),
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: c.primary),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final FaIconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 11, color: c.text3),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.text2),
        ),
      ],
    );
  }
}

/// A dot with a ring that keeps rippling outwards, like a "live" indicator.
class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});

  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1 + _c.value * 1.4,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.45 * (1 - _c.value)),
                ),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.ring});

  final int count;
  final Color ring;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _Pulse(
      child: Container(
        constraints: const BoxConstraints(minWidth: 20),
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.danger,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: ring, width: 2),
        ),
        child: Text(
          '$count',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 1))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
    child: widget.child,
  );
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.caption,
    this.online = false,
    this.badge = 0,
  });

  final FaIconData icon;
  final String label;
  final String? caption;
  final VoidCallback onTap;
  final bool online;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 100),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconTile(icon: icon),
                    if (online)
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: c.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.surface, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                if (badge > 0) UnreadBadge(count: badge),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, height: 1.3, color: c.text),
            ),
            if (caption != null) ...[
              const SizedBox(height: 2),
              Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: online ? c.success : c.text3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
