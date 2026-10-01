import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import '../widgets/mission_card.dart';
import '../widgets/pay_logos.dart';
import '../widgets/pressable.dart';
import '../widgets/slip_document.dart';
import 'payment_sheet.dart';
import 'pdf_viewer_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result});

  final ExamResult result;

  Future<void> _unlock(BuildContext context) async {
    final paid = await showPaymentSheet(context, result);
    if (paid == true && context.mounted) {
      Toast.show(context.tr('Slip unlocked', 'Relevé débloqué'), ToastType.success);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (context.mounted) context.push(PdfViewerScreen(result: result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = result;
    final unlocked = context.select<AppState, bool>((s) => s.isUnlocked(r));

    return SubScreen(
      title: context.tr('Your result', 'Votre résultat'),
      bottomBar: unlocked ? null : _PayBar(onPay: () => _unlock(context)),
      children: [
        HeroGradientCard(
          circleSize: 200,
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
          child: Column(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                builder: (_, v, child) => Transform.scale(scale: v, child: child),
                child: Container(
                  width: 68,
                  height: 68,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: c.accent.withValues(alpha: 0.5), blurRadius: 32, offset: const Offset(0, 12)),
                    ],
                  ),
                  child: const FaIcon(FontAwesomeIcons.check, size: 30, color: AppColors.onAccent),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                unlocked
                    ? context.tr('Slip unlocked', 'Relevé débloqué')
                    : context.tr('Slip available', 'Relevé disponible'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 270),
                child: Text(
                  unlocked
                      ? context.tr(
                          'Your official slip is ready to view and download.',
                          'Votre relevé officiel est prêt.',
                        )
                      : context.tr(
                          'Unlock to open and download your official slip.',
                          'Débloquez pour ouvrir et télécharger votre relevé.',
                        ),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, height: 1.5, color: Colors.white.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
        ),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBadge(r.stream),
              InfoRow(label: context.tr('Name', 'Nom'), value: r.name),
              InfoRow(label: context.tr('Year', 'Année'), value: r.year),
              InfoRow(label: 'Centre', value: r.centre),
              InfoRow(
                label: context.tr('Candidate', 'Candidat'),
                valueWidget: _CopyPill(text: r.cand),
                last: true,
              ),
            ],
          ),
        ),
        _SlipPreview(
          result: r,
          unlocked: unlocked,
          onTap: unlocked ? () => context.push(PdfViewerScreen(result: r)) : () => _unlock(context),
        ),
        const _TrustBadges(),
        if (unlocked) ...[
          AppButton(
            label: context.tr('Open official slip (PDF)', 'Ouvrir le relevé officiel (PDF)'),
            icon: FontAwesomeIcons.filePdf,
            variant: ButtonVariant.success,
            onPressed: () => context.push(PdfViewerScreen(result: r)),
          ),
          const SizedBox(height: 10),
          AppButton(
            label: context.tr('Share slip on WhatsApp', 'Partager sur WhatsApp'),
            icon: FontAwesomeIcons.whatsapp,
            variant: ButtonVariant.whatsapp,
            onPressed: () {
              final msg = context.tr('Sharing not available', 'Partage indisponible');
              PdfService.shareSlip(r).catchError((_) => Toast.show(msg, ToastType.warn));
            },
          ),
        ] else
          HelperText(
            text: context.tr(
              'Your grades are printed on the slip. Unlock once, download anytime.',
              'Vos notes figurent sur le relevé. Débloquez une fois, téléchargez à tout moment.',
            ),
          ),
        const SizedBox(height: 18),
        const OriginalSlipNotice(),
      ],
    );
  }
}

class _PayBar extends StatelessWidget {
  const _PayBar({required this.onPay});

  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(AppConstants.slipPriceLabel, AppConstants.slipPriceLabelFr),
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: c.text),
              ),
              const SizedBox(height: 5),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PayLogo(PaymentMethod.momo, height: 18),
                  SizedBox(width: 6),
                  PayLogo(PaymentMethod.orange, height: 18),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AppButton(
              label: context.tr('Unlock slip', 'Débloquer'),
              icon: FontAwesomeIcons.unlock,
              variant: ButtonVariant.accent,
              onPressed: onPay,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadges extends StatelessWidget {
  const _TrustBadges();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = [
      (FontAwesomeIcons.shieldHalved, context.tr('GCE Board result', 'Résultat du GCE Board')),
      (FontAwesomeIcons.lock, context.tr('Secure payment', 'Paiement sécurisé')),
      (FontAwesomeIcons.bolt, context.tr('Instant download', 'Téléchargement instantané')),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (icon, label) in items)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(icon, size: 10, color: c.success),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c.text2),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CopyPill extends StatelessWidget {
  const _CopyPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      scale: 0.95,
      semanticLabel: context.tr('Copy candidate number', 'Copier le numéro de candidat'),
      onTap: () async {
        final msg = context.tr('Copied to clipboard', 'Copié');
        await ExternalActions.copy(text);
        Toast.show(msg, ToastType.success);
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.hashtag, size: 11, color: c.primary),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.primary),
            ),
            const SizedBox(width: 6),
            FaIcon(FontAwesomeIcons.copy, size: 11, color: c.primary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

/// A cropped look at the official slip. Blurred until paid; the grades are
/// only ever readable inside the slip itself.
class _SlipPreview extends StatelessWidget {
  const _SlipPreview({required this.result, required this.unlocked, required this.onTap});

  final ExamResult result;
  final bool unlocked;
  final VoidCallback onTap;

  static const _pageHeight = 320.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget page = Align(
      alignment: Alignment.topCenter,
      child: SlipDocument(result: result),
    );
    page = unlocked
        ? SlipHero(tag: PdfViewerScreen.defaultHeroTag(result), result: result, child: page)
        : ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6), child: page);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Pressable(
        onTap: onTap,
        scale: 0.98,
        semanticLabel: unlocked
            ? context.tr('Open official slip', 'Ouvrir le relevé officiel')
            : context.tr('Unlock official slip', 'Débloquer le relevé officiel'),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.filePdf, size: 16, color: c.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        result.pdfFileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(unlocked: unlocked),
                  ],
                ),
              ),
              SizedBox(
                height: _pageHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: c.isDark ? c.surface2 : const Color(0xFFEDF2EF)),
                    Positioned(
                      top: 18,
                      left: 18,
                      right: 18,
                      child: ExcludeSemantics(child: IgnorePointer(child: page)),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 110,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [c.surface.withValues(alpha: 0), c.surface],
                          ),
                        ),
                      ),
                    ),
                    if (!unlocked)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.surface,
                                shape: BoxShape.circle,
                                boxShadow: c.shadowMd,
                              ),
                              child: FaIcon(FontAwesomeIcons.lock, size: 24, color: c.primary),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                boxShadow: c.shadowMd,
                              ),
                              child: Text(
                                context.tr('Pay to unlock your slip', 'Payez pour débloquer votre relevé'),
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: c.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              boxShadow: c.shadowMd,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(FontAwesomeIcons.expand, size: 12, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('Tap to open', 'Touchez pour ouvrir'),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.unlocked});

  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = unlocked ? c.success : c.onAccentSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: unlocked ? c.successSoft : c.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(unlocked ? FontAwesomeIcons.lockOpen : FontAwesomeIcons.lock, size: 10, color: fg),
          const SizedBox(width: 5),
          Text(
            unlocked ? context.tr('Unlocked', 'Débloqué') : context.tr('Locked', 'Verrouillé'),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }
}
