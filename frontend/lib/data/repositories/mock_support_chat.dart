import 'dart:async';

import '../../core/constants.dart';
import '../models/chat.dart';
import 'repositories.dart';

/// Simulated support desk: acknowledges messages with delivery/read receipts,
/// shows a typing indicator and answers common questions by keyword.
class MockSupportChatRepository implements SupportChatRepository {
  final _events = StreamController<SupportEvent>.broadcast();
  final _timers = <Timer>[];
  var _seq = 0;

  @override
  final agent = const SupportAgent(name: 'Brenda', roleEn: 'SlipNow Support', roleFr: 'Support SlipNow');

  @override
  Stream<SupportEvent> get events => _events.stream;

  void _after(int ms, SupportEvent Function() event) {
    late final Timer timer;
    timer = Timer(Duration(milliseconds: ms), () {
      _timers.remove(timer);
      if (!_events.isClosed) _events.add(event());
    });
    _timers.add(timer);
  }

  @override
  Future<void> send(ChatMessage m, {required bool fr}) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _after(700, () => StatusChanged(m.id, MessageStatus.delivered));
    _after(1500, () => StatusChanged(m.id, MessageStatus.read));

    final (replies, reaction) = _replyFor(m, fr);
    if (reaction != null) _after(1900, () => AgentReacted(m.id, reaction));
    var at = 2200;
    for (final reply in replies) {
      _after(at, () => const AgentTyping(true));
      at += (reply.length * 18).clamp(1200, 3200);
      _after(at, () => const AgentTyping(false));
      _after(
        at,
        () => AgentMessage(
          ChatMessage(
            id: 'a${DateTime.now().microsecondsSinceEpoch}_${_seq++}',
            sender: ChatSender.agent,
            time: DateTime.now(),
            text: reply,
            status: MessageStatus.read,
          ),
        ),
      );
      at += 700;
    }
  }

  (List<String>, String?) _replyFor(ChatMessage m, bool fr) {
    String t(String en, String frText) => fr ? frText : en;
    bool has(List<String> words) => words.any(m.text.toLowerCase().contains);

    switch (m.kind) {
      case MessageKind.voice:
        return (
          [
            t(
              'Thanks for the voice note, I have listened to it. Could you also type your candidate number so I can check your record?',
              "Merci pour le message vocal, je l'ai écouté. Pouvez-vous aussi écrire votre numéro de candidat pour que je vérifie ?",
            ),
          ],
          null,
        );
      case MessageKind.slip:
        final s = m.slip!;
        return (
          [
            t(
              'Thanks, I can see the slip for ${s.name} (${s.stream} ${s.year}). What would you like help with?',
              'Merci, je vois le relevé de ${s.name} (${s.stream} ${s.year}). Comment puis-je vous aider ?',
            ),
          ],
          null,
        );
      case MessageKind.receipt:
        return (
          [
            t(
              'Thanks! Checking transaction ${m.receipt!.txnId} now…',
              'Merci ! Je vérifie la transaction ${m.receipt!.txnId}…',
            ),
            t(
              'All good: your payment of ${AppConstants.slipPriceLabel} is confirmed and the slip is unlocked. You can open it any time from the Slips tab.',
              'Tout est en ordre : votre paiement de ${AppConstants.slipPriceLabelFr} est confirmé et le relevé est débloqué. Ouvrez-le depuis l’onglet Relevés.',
            ),
          ],
          '👍',
        );
      case MessageKind.text:
        break;
    }

    if (m.text.startsWith('Candidate:') || m.text.startsWith('Candidat :')) {
      return (
        [
          t(
            'Thanks, I have the details. Checking the GCE Board record now…',
            'Merci, j’ai les informations. Je vérifie le registre du GCE Board…',
          ),
          t(
            'I found the record. Search the name in the Search tab, preview the slip and unlock it there. I am here if anything goes wrong.',
            'J’ai trouvé le dossier. Recherchez le nom dans l’onglet Recherche, prévisualisez le relevé et débloquez-le. Je reste disponible.',
          ),
        ],
        null,
      );
    }
    if (has(['thank', 'merci'])) {
      return (
        [t('You are welcome! Anything else I can help with?', 'Avec plaisir ! Puis-je vous aider pour autre chose ?')],
        '❤️',
      );
    }
    if (has(['pay', 'momo', 'orange', 'money', 'debit', 'fail', 'paie', 'paiement', 'échou', 'debité'])) {
      return (
        [
          t(
            'Sorry about that. If you were debited but the slip did not unlock, send me the transaction ID from Profile → Payment receipts, or attach the receipt with the paperclip. We fix it within minutes.',
            'Désolée. Si vous avez été débité sans déblocage, envoyez l’ID de transaction (Profil → Reçus de paiement) ou joignez le reçu avec le trombone. Nous réglons cela en quelques minutes.',
          ),
        ],
        null,
      );
    }
    if (has(['find', 'name', 'search', 'trouve', 'nom', 'cherch'])) {
      return (
        [
          t(
            'Let us sort that out. Please send the full name as registered, candidate number, centre number and exam (for example GCE A/L 2026).',
            'Réglons cela. Envoyez le nom complet tel qu’inscrit, le numéro de candidat, le numéro de centre et l’examen (par exemple GCE A/L 2026).',
          ),
        ],
        null,
      );
    }
    if (has(['original', 'copy', 'copie', 'school', 'école', 'ecole', 'collect'])) {
      return (
        [
          t(
            'SlipNow gives you a copy of your slip so you can see your grades right away and use it for urgent needs like public exams, scholarships and admissions. You are still urged to collect your original slip from your school.',
            'SlipNow vous donne une copie de votre relevé pour voir vos notes tout de suite et l’utiliser en urgence (examens publics, bourses, admissions). Vous êtes toujours invité à retirer l’original dans votre établissement.',
          ),
        ],
        null,
      );
    }
    if (has(['release', 'out yet', 'when', 'publish', 'publi', 'quand', 'sortie', 'date'])) {
      return (
        [
          t(
            'Results are released by the GCE Board. The Home screen always shows the current status, and we notify you the moment they are out.',
            'Les résultats sont publiés par le GCE Board. L’écran d’accueil affiche toujours le statut actuel et nous vous prévenons dès leur publication.',
          ),
        ],
        null,
      );
    }
    if (has(['scholarship', 'admission', 'abroad', 'universit', 'bourse', 'étranger', 'etranger'])) {
      return (
        [
          t(
            'Your SlipNow slip is a PDF you can share straight away with schools and scholarship boards, at home or abroad. Some institutions will later ask for the original, so do collect it from your school.',
            'Votre relevé SlipNow est un PDF à partager immédiatement avec écoles et organismes de bourses, au pays ou à l’étranger. Certains demanderont l’original plus tard : pensez à le retirer.',
          ),
        ],
        null,
      );
    }
    if (RegExp(
      r'\b(hi|hello|hey|good (morning|afternoon|evening)|bonjour|salut|bonsoir)\b',
    ).hasMatch(m.text.toLowerCase())) {
      return (
        [
          t(
            'Hello! I am Brenda from SlipNow. How can I help you today?',
            'Bonjour ! Je suis Brenda de SlipNow. Comment puis-je vous aider ?',
          ),
        ],
        null,
      );
    }
    return (
      [
        t(
          'Thanks for your message. I am looking into it and will get back to you shortly.',
          'Merci pour votre message. Je m’en occupe et je reviens vers vous rapidement.',
        ),
      ],
      null,
    );
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _events.close();
  }
}
