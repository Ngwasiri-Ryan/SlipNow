import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../services/pdf_service.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/collapsing_header.dart';
import '../widgets/common.dart';
import '../widgets/feedback.dart';
import '../widgets/pressable.dart';
import '../widgets/slip_document.dart';
import 'main_shell.dart';
import 'pdf_viewer_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _year;
  bool _grid = true;

  static Object _heroTag(ExamResult r) => 'slips-${r.slipId}';

  void _open(ExamResult r) => context.push(PdfViewerScreen(result: r, heroTag: _heroTag(r)));

  void _share(ExamResult r) {
    final msg = context.tr('Sharing not available', 'Partage indisponible');
    PdfService.shareSlip(r).catchError((_) => Toast.show(msg, ToastType.warn));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.watch<AppState>();
    final years = {for (final p in s.purchases) p.result.year}.toList()..sort((a, b) => b.compareTo(a));
    final items = s.purchases.reversed.where((p) => _year == null || p.result.year == _year).toList();

    return CollapsingPage(
      eyebrow: context.tr('Your account', 'Votre compte'),
      title: context.tr('My slips', 'Mes relevés'),
      bottomPadding: tabBarClearance(context),
      trailing: s.purchases.isEmpty
          ? null
          : CircleIconButton(
              icon: _grid ? FontAwesomeIcons.list : FontAwesomeIcons.tableCellsLarge,
              size: 46,
              iconSize: 15,
              semanticLabel: _grid ? context.tr('List view', 'Vue liste') : context.tr('Grid view', 'Vue grille'),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _grid = !_grid);
              },
            ),
      beforeList: [
        if (years.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
                children: [
                  _FilterChip(
                    label: context.tr('All', 'Tous'),
                    count: s.purchases.length,
                    active: _year == null,
                    onTap: () => setState(() => _year = null),
                  ),
                  for (final y in years)
                    _FilterChip(
                      label: y,
                      count: s.purchases.where((p) => p.result.year == y).length,
                      active: _year == y,
                      onTap: () => setState(() => _year = y),
                    ),
                ],
              ),
            ),
          ),
      ],
      children: [
        if (s.purchases.isEmpty)
          EmptyState(
            icon: FontAwesomeIcons.fileCirclePlus,
            title: context.tr('No slips yet', 'Aucun relevé'),
            message: context.tr(
              'When you unlock a result, your official slip PDF will appear here.',
              'Débloquez un résultat pour le voir ici.',
            ),
            action: AppButton(
              label: context.tr('Search results', 'Rechercher'),
              icon: FontAwesomeIcons.magnifyingGlass,
              onPressed: () => s.setTab(AppTab.search),
            ),
          )
        else ...[
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _grid
                ? _Grid(key: const ValueKey('grid'), items: items, onOpen: _open, onShare: _share, heroTag: _heroTag)
                : _List(key: const ValueKey('list'), items: items, onOpen: _open, onShare: _share, heroTag: _heroTag),
          ),
          if (!_grid)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.tr(
                  'Tip: swipe a slip left to share it',
                  'Astuce : glissez un relevé vers la gauche pour le partager',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: c.text3),
              ),
            ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.count, required this.active, required this.onTap});

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        selected: active,
        child: Pressable(
          onTap: onTap,
          scale: 0.95,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? c.primary : c.surface,
              border: Border.all(color: active ? c.primary : c.border, width: 1.5),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : c.text2),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: active ? Colors.white.withValues(alpha: 0.2) : c.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: active ? Colors.white : c.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({super.key, required this.items, required this.onOpen, required this.onShare, required this.heroTag});

  final List<Purchase> items;
  final ValueChanged<ExamResult> onOpen;
  final ValueChanged<ExamResult> onShare;
  final Object Function(ExamResult) heroTag;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _GridCard(purchase: items[i], onOpen: onOpen, onShare: onShare, heroTag: heroTag),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: i + 1 < items.length
                    ? _GridCard(purchase: items[i + 1], onOpen: onOpen, onShare: onShare, heroTag: heroTag)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.purchase, required this.onOpen, required this.onShare, required this.heroTag});

  final Purchase purchase;
  final ValueChanged<ExamResult> onOpen;
  final ValueChanged<ExamResult> onShare;
  final Object Function(ExamResult) heroTag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = purchase.result;
    return FadeSlideIn(
      child: Pressable(
        onTap: () => onOpen(r),
        scale: 0.97,
        semanticLabel: '${context.tr('Open slip', 'Ouvrir le relevé')} ${r.name}',
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: c.border),
            boxShadow: c.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SlipThumbnail(result: r, width: null, aspectRatio: 1.15, heroTag: heroTag(r)),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Pressable(
                      onTap: () => onShare(r),
                      scale: 0.9,
                      semanticLabel: context.tr('Share slip', 'Partager le relevé'),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.whatsapp,
                          shape: BoxShape.circle,
                          boxShadow: c.shadowMd,
                        ),
                        child: const FaIcon(FontAwesomeIcons.shareNodes, size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                r.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: c.text),
              ),
              const SizedBox(height: 2),
              Text(
                '${r.stream} · ${r.year}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: c.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({super.key, required this.items, required this.onOpen, required this.onShare, required this.heroTag});

  final List<Purchase> items;
  final ValueChanged<ExamResult> onOpen;
  final ValueChanged<ExamResult> onShare;
  final Object Function(ExamResult) heroTag;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final date = DateFormat.yMd();
    return Column(
      children: [
        for (final p in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Dismissible(
                key: ValueKey(p.result.slipId),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  HapticFeedback.mediumImpact();
                  onShare(p.result);
                  return false;
                },
                background: Container(
                  color: AppColors.whatsapp,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.tr('Share', 'Partager'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      const FaIcon(FontAwesomeIcons.shareNodes, size: 18, color: Colors.white),
                    ],
                  ),
                ),
                child: InfoCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(14),
                  onTap: () => onOpen(p.result),
                  child: Row(
                    children: [
                      SlipThumbnail(result: p.result, width: 52, heroTag: heroTag(p.result)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            StreamBadge(p.result.stream, margin: const EdgeInsets.only(bottom: 6)),
                            Text(
                              p.result.name,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${p.result.year} · Centre ${p.result.centre} · ${date.format(p.date)}',
                              style: TextStyle(fontSize: 12, color: c.text2),
                            ),
                          ],
                        ),
                      ),
                      FaIcon(FontAwesomeIcons.chevronRight, size: 13, color: c.text3),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
