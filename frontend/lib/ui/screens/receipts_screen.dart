import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/l10n.dart';
import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../services/external_actions.dart';
import '../../services/pdf_service.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/common.dart';
import '../widgets/feedback.dart';
import '../widgets/pay_logos.dart';
import '../widgets/pressable.dart';
import '../widgets/slip_document.dart';
import 'chat_screen.dart';
import 'pdf_viewer_screen.dart';

String _fcfa(BuildContext context, int amount) {
  final n = NumberFormat.decimalPattern('en').format(amount);
  return '${context.isFr ? n.replaceAll(',', '\u202F') : n} FCFA';
}

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final purchases = context.watch<AppState>().purchases.reversed.toList();

    final groups = <String, List<Purchase>>{};
    for (final p in purchases) {
      groups.putIfAbsent(context.monthYear(p.date), () => []).add(p);
    }

    return SubScreen(
      title: context.tr('Payment receipts', 'Reçus de paiement'),
      children: [
        if (purchases.isEmpty)
          EmptyState(
            icon: FontAwesomeIcons.receipt,
            title: context.tr('No receipts yet', 'Aucun reçu'),
            message: context.tr(
              'Each time you unlock a slip, a receipt is saved here. You can download or share it anytime.',
              'Chaque déblocage enregistre un reçu ici. Téléchargez-le ou partagez-le à tout moment.',
            ),
            action: AppButton(
              label: context.tr('Find my results', 'Trouver mes résultats'),
              icon: FontAwesomeIcons.magnifyingGlass,
              compact: true,
              onPressed: () {
                context.read<AppState>().setTab(AppTab.search);
                Navigator.of(context).popUntil((r) => r.isFirst);
              },
            ),
          )
        else ...[
          const SizedBox(height: 4),
          _SummaryCard(purchases: purchases),
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 12),
              child: Row(
                children: [
                  Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: c.text3),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Divider(color: c.border, height: 1)),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('${entry.value.length} paid', '${entry.value.length} payé(s)'),
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.text3),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < entry.value.length; i++)
              FadeSlideIn(
                delay: Duration(milliseconds: 70 * i),
                child: _ReceiptTicket(purchase: entry.value[i]),
              ),
          ],
          _HelpFooter(onTap: () => context.push(const ChatScreen())),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.purchases});

  final List<Purchase> purchases;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final total = purchases.length * AppConstants.slipPriceFcfa;
    final byMethod = {for (final m in PaymentMethod.values) m: purchases.where((p) => p.method == m).length}
      ..removeWhere((_, n) => n == 0);

    return FadeSlideIn(
      child: HeroGradientCard(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('Total spent', 'Total dépensé'),
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
                          _fcfa(context, total),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  ),
                  child: FaIcon(FontAwesomeIcons.receipt, size: 20, color: c.accent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _GlassChip(
                  child: Text(
                    context.tr(
                      '${purchases.length} slip${purchases.length == 1 ? '' : 's'} unlocked',
                      '${purchases.length} relevé(s) débloqué(s)',
                    ),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                for (final MapEntry(key: method, value: n) in byMethod.entries)
                  _GlassChip(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PayMark(method, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '× $n',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
    ),
    child: child,
  );
}

/// A receipt drawn as a paper ticket: payment summary on top, a perforated
/// tear line with side notches, then the slip and transaction details.
class _ReceiptTicket extends StatefulWidget {
  const _ReceiptTicket({required this.purchase});

  final Purchase purchase;

  @override
  State<_ReceiptTicket> createState() => _ReceiptTicketState();
}

class _ReceiptTicketState extends State<_ReceiptTicket> {
  static const _tearGap = 26.0;
  double _headerHeight = 76;

  Future<void> _run(Future<void> Function() action, String ok) async {
    final failed = context.tr('Something went wrong', 'Une erreur est survenue');
    try {
      await action();
      Toast.show(ok, ToastType.success);
    } catch (_) {
      Toast.show(failed, ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = widget.purchase;
    final r = p.result;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: CustomPaint(
        painter: _TicketPainter(
          notchY: _headerHeight + _tearGap / 2,
          fill: c.surface,
          border: c.border,
          dash: c.borderStrong,
          shadow: Colors.black.withValues(alpha: c.isDark ? 0.5 : 0.12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MeasureSize(
              onChange: (size) {
                if ((size.height - _headerHeight).abs() > 0.5) setState(() => _headerHeight = size.height);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    PayMark(p.method, size: 46),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Slip unlock', 'Déblocage de relevé'),
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: c.text),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${context.shortDate(p.date)} · ${context.clock(p.date)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.text3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _fcfa(context, AppConstants.slipPriceFcfa),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: c.text,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: c.successSoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.check, size: 9, color: c.success),
                              const SizedBox(width: 4),
                              Text(
                                context.tr('PAID', 'PAYÉ'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: c.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: _tearGap),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SlipThumbnail(result: r, width: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${r.stream} · ${r.year} · ${context.tr('Cand.', 'Cand.')} ${r.cand}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: c.text2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.surface2,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          label: context.tr('Transaction ID', 'ID de transaction'),
                          child: Pressable(
                            onTap: () {
                              ExternalActions.copy(p.txnId);
                              Toast.show(context.tr('Transaction ID copied', 'ID copié'), ToastType.success);
                            },
                            semanticLabel: context.tr('Copy transaction ID', 'Copier l’ID'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    p.txnId,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.mono(size: 12.5, color: c.text).copyWith(letterSpacing: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FaIcon(FontAwesomeIcons.copy, size: 12, color: c.primary),
                              ],
                            ),
                          ),
                        ),
                        _DetailRow(
                          label: context.tr('Paid with', 'Payé avec'),
                          child: Text(
                            p.method.label,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text),
                          ),
                        ),
                        _DetailRow(
                          label: context.tr('Status', 'Statut'),
                          last: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                context.tr('Successful', 'Réussi'),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.success),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _TicketAction(
                          icon: FontAwesomeIcons.download,
                          label: 'PDF',
                          onTap: () => _run(() => PdfService.saveReceipt(p), context.tr('Receipt ready', 'Reçu prêt')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: _TicketAction(
                          icon: FontAwesomeIcons.shareNodes,
                          label: context.tr('Share', 'Partager'),
                          onTap: () => _run(() => PdfService.shareReceipt(p), context.tr('Shared', 'Partagé')),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 6,
                        child: _TicketAction(
                          icon: FontAwesomeIcons.filePdf,
                          label: context.tr('View slip', 'Voir le relevé'),
                          primary: true,
                          onTap: () => context.push(PdfViewerScreen(result: r)),
                        ),
                      ),
                    ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child, this.last = false});

  final String label;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.border)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: c.text2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
        ],
      ),
    );
  }
}

class _TicketAction extends StatelessWidget {
  const _TicketAction({required this.icon, required this.label, required this.onTap, this.primary = false});

  final FaIconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = primary ? Colors.white : c.text;
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: primary ? c.primary : c.surface,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: primary ? null : Border.all(color: c.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 13, color: primary ? Colors.white : c.primary),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpFooter extends StatelessWidget {
  const _HelpFooter({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Row(
          children: [
            FaIcon(FontAwesomeIcons.headset, size: 16, color: c.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr(
                  'Problem with a payment? Chat with support and attach the receipt.',
                  'Un souci de paiement ? Écrivez au support et joignez le reçu.',
                ),
                style: TextStyle(fontSize: 12.5, height: 1.45, fontWeight: FontWeight.w600, color: c.primary),
              ),
            ),
            const SizedBox(width: 8),
            FaIcon(FontAwesomeIcons.chevronRight, size: 12, color: c.primary),
          ],
        ),
      ),
    );
  }
}

class _TicketPainter extends CustomPainter {
  _TicketPainter({
    required this.notchY,
    required this.fill,
    required this.border,
    required this.dash,
    required this.shadow,
  });

  final double notchY;
  final Color fill;
  final Color border;
  final Color dash;
  final Color shadow;

  static const _radius = 20.0;
  static const _notch = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(_radius)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: _notch))
      ..addOval(Rect.fromCircle(center: Offset(size.width, notchY), radius: _notch));
    final ticket = Path.combine(PathOperation.difference, outer, holes);

    canvas.drawShadow(ticket, shadow, 3, false);
    canvas.drawPath(ticket, Paint()..color = fill);
    canvas.drawPath(
      ticket,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = border,
    );

    final dashPaint = Paint()
      ..color = dash
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final end = size.width - _notch - 8;
    for (var x = _notch + 8; x < end; x += 9) {
      canvas.drawLine(Offset(x, notchY), Offset(math.min(x + 4.5, end), notchY), dashPaint);
    }
  }

  @override
  bool shouldRepaint(_TicketPainter old) =>
      old.notchY != notchY || old.fill != fill || old.border != border || old.dash != dash || old.shadow != shadow;
}

/// Reports its child's laid-out size after each change.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, required super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(BuildContext context, _RenderMeasureSize renderObject) => renderObject.onChange = onChange;
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _last;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _last) return;
    _last = size;
    final reported = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChange(reported));
  }
}
