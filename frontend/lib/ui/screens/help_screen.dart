import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/external_actions.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/chat/support_avatar.dart';
import '../widgets/common.dart';
import '../widgets/mission_card.dart';
import 'chat_screen.dart';
import 'terms_screen.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final faqs = context.isFr
        ? const [
            (
              'Est-ce mon relevé original ?',
              'Non. SlipNow vous donne une copie de votre relevé pour voir vos notes et l’utiliser en urgence '
                  '(examens publics, bourses, admissions). Vous êtes toujours invité à retirer l’original dans votre établissement.',
            ),
            (
              'Quand les résultats sont-ils publiés ?',
              'Le GCE Board publie les résultats. L’écran d’accueil affiche le statut et nous vous prévenons dès leur sortie.',
            ),
            (
              'Je ne trouve pas mon nom',
              'Essayez avec votre nom et l’année. Sinon, écrivez-nous dans le chat avec votre numéro de candidat.',
            ),
            ('Comment payer ?', 'Choisissez MoMo ou Orange, entrez votre numéro, composez le code USSD et confirmez.'),
            ('Puis-je le télécharger à nouveau ?', 'Oui. Chaque relevé débloqué reste dans l’onglet Relevés.'),
            (
              'Et si mon paiement échoue ?',
              'Joignez votre reçu dans le chat ou envoyez l’ID de transaction. Nous réglons cela vite.',
            ),
          ]
        : const [
            (
              'Is this my original slip?',
              'No. SlipNow gives you a copy of your slip so you can see your grades and use it urgently for public exams, '
                  'scholarships and admissions. You are still urged to collect your original slip from your school.',
            ),
            (
              'When are results released?',
              'The GCE Board releases results. The Home screen shows the current status and we notify you the moment they are out.',
            ),
            (
              'I cannot find my name in search',
              'Try with just your name and year. Otherwise message us in live chat with your candidate number.',
            ),
            ('How do I pay?', 'Choose MoMo or Orange, enter your number, dial the USSD code, and confirm.'),
            ('Can I download it again later?', 'Yes. Every unlocked slip is saved in the Slips tab.'),
            (
              'What if my payment fails?',
              'Attach your receipt in live chat or send the transaction ID, and we will fix it quickly.',
            ),
          ];

    return SubScreen(
      title: context.tr('Help center', "Centre d'aide"),
      children: [
        const SizedBox(height: 4),
        const MissionCard(),
        _LiveChatCard(onTap: () => context.push(const ChatScreen())),
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: c.primarySoft, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: FaIcon(FontAwesomeIcons.store, size: 18, color: c.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Printing at a cyber cafe?', 'Impression dans un cybercafé ?'),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.55, color: c.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(
                        'Open your slip, tap Share or Download, send the PDF to the attendant and print it on A4.',
                        'Ouvrez votre relevé, touchez Partager ou Télécharger, envoyez le PDF à l’agent et imprimez en A4.',
                      ),
                      style: TextStyle(fontSize: 13, height: 1.55, color: c.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  context.tr('Frequently asked questions', 'Questions fréquentes'),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text),
                ),
              ),
              for (var i = 0; i < faqs.length; i++)
                _FaqItem(
                  key: ValueKey(faqs[i].$1),
                  question: faqs[i].$1,
                  answer: faqs[i].$2,
                  last: i == faqs.length - 1,
                ),
            ],
          ),
        ),
        AppButton(
          label: context.tr('Prefer WhatsApp? Message us', 'Préférez WhatsApp ? Écrivez-nous'),
          icon: FontAwesomeIcons.whatsapp,
          variant: ButtonVariant.ghost,
          onPressed: ExternalActions.openSupportWhatsApp,
        ),
        HelperText(
          text: context.tr(
            'Support hours: 8am to 8pm, Monday to Saturday.',
            'Horaires : 8h à 20h, du lundi au samedi.',
          ),
          linkText: context.tr('Terms & conditions', 'Conditions d’utilisation'),
          onLink: () => context.push(const TermsScreen()),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _LiveChatCard extends StatelessWidget {
  const _LiveChatCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final chat = context.read<AppState>().chat;
    return InfoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SupportAvatar(initial: chat.agent.initial, size: 50, online: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Live chat with support', 'Chat en direct avec le support'),
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: c.text),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(
                    '${chat.agent.name} is online · replies in minutes',
                    '${chat.agent.name} est en ligne · répond en quelques minutes',
                  ),
                  style: TextStyle(fontSize: 12.5, color: c.text2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
            child: const FaIcon(FontAwesomeIcons.solidCommentDots, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  const _FaqItem({super.key, required this.question, required this.answer, required this.last});

  final String question;
  final String answer;
  final bool last;

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      expanded: _open,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: widget.last ? null : Border(bottom: BorderSide(color: c.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.4, color: c.text),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: FaIcon(FontAwesomeIcons.chevronDown, size: 12, color: c.text3),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(widget.answer, style: TextStyle(fontSize: 13, height: 1.6, color: c.text2)),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
