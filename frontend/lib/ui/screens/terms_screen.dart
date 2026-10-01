import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/l10n.dart';
import '../../core/mission.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/mission_card.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  static const _lastUpdated = ('Last updated: 29 September 2026', 'Dernière mise à jour : 29 septembre 2026');

  static const _sections = [
    (('About SlipNow and its purpose', 'À propos de SlipNow et de sa mission'), MissionCopy.summary),
    (
      ('Not a replacement for your original slip', 'Ne remplace pas votre relevé original'),
      (
        'The slip you view and download on SlipNow is a copy of the result published by the GCE Board, provided '
            'for convenience and urgent use. It does not replace the original result slip. Candidates are still '
            'urged to go to their schools to collect their original copies. Where an institution requires the '
            'original, you must present it.',
        'Le relevé consulté et téléchargé sur SlipNow est une copie du résultat publié par le GCE Board, fournie '
            'pour votre commodité et un usage urgent. Il ne remplace pas le relevé original. Les candidats sont '
            'toujours invités à se rendre dans leur établissement pour retirer leur exemplaire original. Lorsqu’une '
            'institution exige l’original, vous devez le présenter.',
      ),
    ),
    (
      ('Results release', 'Publication des résultats'),
      (
        'Results are released by the GCE Board, not by SlipNow. The app shows whether the current session’s results '
            'have been released. Until they are, no slip can be searched or unlocked for that session.',
        'Les résultats sont publiés par le GCE Board et non par SlipNow. L’application indique si les résultats de la '
            'session en cours sont publiés. Tant qu’ils ne le sont pas, aucun relevé de cette session ne peut être '
            'recherché ni débloqué.',
      ),
    ),
    (
      ('Fees and payment', 'Frais et paiement'),
      (
        'Searching and previewing are free. Unlocking a slip costs ${AppConstants.slipPriceLabel}, paid once by MTN '
            'Mobile Money or Orange Money. Once unlocked, the slip stays in your account and can be downloaded again '
            'at no extra cost. A receipt is saved for every payment.',
        'La recherche et l’aperçu sont gratuits. Le déblocage d’un relevé coûte ${AppConstants.slipPriceLabelFr}, '
            'payés une seule fois par MTN Mobile Money ou Orange Money. Une fois débloqué, le relevé reste dans votre '
            'compte et peut être retéléchargé sans frais. Un reçu est enregistré pour chaque paiement.',
      ),
    ),
    (
      ('Refunds', 'Remboursements'),
      (
        'If you were debited but your slip did not unlock, contact support through live chat with your transaction ID. '
            'We will unlock the slip or refund you. Payments for slips that were successfully unlocked are not refundable.',
        'Si vous avez été débité sans que le relevé soit débloqué, contactez le support par chat avec votre ID de '
            'transaction. Nous débloquerons le relevé ou vous rembourserons. Les paiements de relevés débloqués ne sont '
            'pas remboursables.',
      ),
    ),
    (
      ('Accuracy of results', 'Exactitude des résultats'),
      (
        'SlipNow displays results exactly as published by the GCE Board. In case of any difference, the original slip '
            'issued through your school prevails. Report any concern to support or to the GCE Board.',
        'SlipNow affiche les résultats tels que publiés par le GCE Board. En cas de différence, le relevé original remis '
            'par votre établissement fait foi. Signalez toute anomalie au support ou au GCE Board.',
      ),
    ),
    (
      ('Acceptable use', 'Utilisation autorisée'),
      (
        'Only search for and unlock your own slip, or a slip you have the candidate’s permission to access (for example '
            'a child or sibling). Altering a slip or presenting it as an original is prohibited.',
        'Ne recherchez et ne débloquez que votre propre relevé, ou celui d’un candidat qui vous y autorise (par exemple '
            'un enfant ou un frère). Modifier un relevé ou le présenter comme un original est interdit.',
      ),
    ),
    (
      ('Your data', 'Vos données'),
      (
        'We use your name and phone number to create your account, process payments and keep your slips and receipts. '
            'Support chats are kept to help resolve your requests. We do not sell your data.',
        'Nous utilisons votre nom et votre numéro pour créer votre compte, traiter les paiements et conserver vos relevés '
            'et reçus. Les conversations avec le support sont conservées pour traiter vos demandes. Nous ne vendons pas '
            'vos données.',
      ),
    ),
    (
      ('Support', 'Assistance'),
      (
        'Live chat and WhatsApp support are available 8am to 8pm, Monday to Saturday.',
        'Le chat en direct et le support WhatsApp sont disponibles de 8h à 20h, du lundi au samedi.',
      ),
    ),
    (
      ('Changes to these terms', 'Modifications des conditions'),
      (
        'We may update these terms. Continuing to use SlipNow after an update means you accept the new terms.',
        'Nous pouvons modifier ces conditions. Continuer à utiliser SlipNow après une mise à jour vaut acceptation.',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String t((String, String) s) => context.tr(s.$1, s.$2);

    return SubScreen(
      title: context.tr('Terms & conditions', 'Conditions d’utilisation'),
      children: [
        const SizedBox(height: 4),
        const MissionCard(),
        InfoCard(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _sections.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: i == _sections.length - 1 ? null : Border(bottom: BorderSide(color: c.border)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: c.primary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t(_sections[i].$1),
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                                color: c.text,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(t(_sections[i].$2), style: TextStyle(fontSize: 13, height: 1.6, color: c.text2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 12),
          child: Text(
            t(_lastUpdated),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: c.text3),
          ),
        ),
      ],
    );
  }
}
