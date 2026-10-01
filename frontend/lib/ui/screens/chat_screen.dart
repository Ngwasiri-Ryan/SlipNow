import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/chat.dart';
import '../../data/models/models.dart';
import '../../services/external_actions.dart';
import '../../state/app_state.dart';
import '../../state/chat_controller.dart';
import '../widgets/chat/chat_composer.dart';
import '../widgets/chat/chat_theme.dart';
import '../widgets/chat/message_bubble.dart';
import '../widgets/chat/support_avatar.dart';
import '../widgets/feedback.dart';
import '../widgets/mission_card.dart';
import '../widgets/slip_document.dart';
import 'help_screen.dart';
import 'pdf_viewer_screen.dart';
import 'receipts_screen.dart';
import 'terms_screen.dart';

/// Live support chat, styled after modern messaging apps.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

enum _MenuAction { reply, copy, delete }

enum _HeaderAction { help, terms, whatsapp, clear }

enum _Attachment { slip, receipt, candidate, faq }

sealed class _Item {
  const _Item(this.key);
  final String key;
}

class _NoticeItem extends _Item {
  const _NoticeItem() : super('notice');
}

class _DayItem extends _Item {
  _DayItem(this.day) : super('day-${day.toIso8601String()}');
  final DateTime day;
}

class _MsgItem extends _Item {
  _MsgItem(this.message, {required this.tail}) : super(message.id);
  final ChatMessage message;
  final bool tail;
}

class _TypingItem extends _Item {
  const _TypingItem() : super('typing');
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _chat = context.read<AppState>().chat;
  final _scroll = ScrollController();
  final _focus = FocusNode();
  final _keys = <String, GlobalKey>{};
  final _seen = <String>{};
  ChatMessage? _replyTo;
  String? _highlight;
  bool _showJump = false;
  int _missed = 0;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _seen.addAll(_chat.messages.map((m) => m.id));
    _lastCount = _chat.messages.length;
    _chat.addListener(_onChat);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _chat.setOpen(true, fr: context.isFr, firstName: context.read<AppState>().user?.firstName);
    });
  }

  @override
  void dispose() {
    _chat
      ..removeListener(_onChat)
      ..markClosed();
    _scroll.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChat() {
    final n = _chat.messages.length;
    if (n > _lastCount) {
      final last = _chat.messages.last;
      if (last.fromMe) {
        _jumpToBottom();
      } else if (_scroll.hasClients && _scroll.offset > 120) {
        setState(() => _missed += n - _lastCount);
      }
    }
    _lastCount = n;
  }

  void _onScroll() {
    final show = _scroll.offset > 300;
    if (show != _showJump || (_scroll.offset < 40 && _missed > 0)) {
      setState(() {
        _showJump = show;
        if (_scroll.offset < 40) _missed = 0;
      });
    }
  }

  void _jumpToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  List<_Item> _items(List<ChatMessage> msgs, bool typing) {
    final items = <_Item>[const _NoticeItem()];
    DateTime? lastDay;
    ChatMessage? prev;
    for (final m in msgs) {
      final day = DateUtils.dateOnly(m.time);
      if (day != lastDay) {
        items.add(_DayItem(day));
        lastDay = day;
        prev = null;
      }
      final startsGroup = prev == null || prev.sender != m.sender || m.time.difference(prev.time).inMinutes >= 5;
      items.add(_MsgItem(m, tail: startsGroup));
      prev = m;
    }
    if (typing) items.add(const _TypingItem());
    return items.reversed.toList();
  }

  void _sendText(String text) {
    _chat.sendText(text, replyToId: _replyTo?.id, fr: context.isFr);
    setState(() => _replyTo = null);
  }

  void _sendVoice(int seconds) {
    _chat.sendVoice(seconds, replyToId: _replyTo?.id, fr: context.isFr);
    setState(() => _replyTo = null);
  }

  void _reply(ChatMessage m) {
    HapticFeedback.selectionClick();
    setState(() => _replyTo = m);
    _focus.requestFocus();
  }

  Future<void> _scrollTo(String id) async {
    for (var i = 0; i < 40; i++) {
      final ctx = _keys[id]?.currentContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
        if (!mounted) return;
        setState(() => _highlight = id);
        Future.delayed(const Duration(milliseconds: 1300), () {
          if (mounted && _highlight == id) setState(() => _highlight = null);
        });
        return;
      }
      if (!_scroll.hasClients) return;
      final pos = _scroll.position;
      if (pos.pixels >= pos.maxScrollExtent) break;
      await _scroll.animateTo(
        math.min(pos.maxScrollExtent, pos.pixels + pos.viewportDimension * 0.8),
        duration: const Duration(milliseconds: 90),
        curve: Curves.linear,
      );
    }
    if (mounted) Toast.show(context.tr('Original message not found', 'Message d’origine introuvable'));
  }

  MessageBubble _bubble(
    ChatMessage m,
    ChatPalette p,
    double maxW,
    bool tail,
    AppUser? user, {
    bool interactive = true,
  }) {
    return MessageBubble(
      message: m,
      palette: p,
      maxWidth: maxW,
      tail: tail,
      agentName: _chat.agent.name,
      agentInitial: _chat.agent.initial,
      userInitial: user?.initial ?? 'S',
      quoted: _chat.byId(m.replyToId),
      highlight: _highlight == m.id,
      onQuoteTap: interactive && m.replyToId != null ? () => _scrollTo(m.replyToId!) : null,
      onOpenSlip: interactive && m.slip != null ? () => context.push(PdfViewerScreen(result: m.slip!)) : null,
      onOpenReceipt: interactive && m.receipt != null ? () => context.push(const ReceiptsScreen()) : null,
      onReactionTap: interactive && m.myReaction != null ? () => _chat.react(m.id, m.myReaction!) : null,
    );
  }

  Future<void> _showActions(ChatMessage m, GlobalKey key, ChatPalette p, double maxW, bool tail, AppUser? user) async {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    HapticFeedback.mediumImpact();
    _focus.unfocus();
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final result = await showGeneralDialog<Object>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) =>
          _MessageActions(rect: rect, message: m, bubble: _bubble(m, p, maxW, tail, user, interactive: false)),
      transitionBuilder: (_, a, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: child,
      ),
    );
    if (!mounted || result == null) return;
    switch (result) {
      case final String emoji:
        _chat.react(m.id, emoji);
      case _MenuAction.reply:
        _reply(m);
      case _MenuAction.copy:
        final copied = context.tr('Message copied', 'Message copié');
        await ExternalActions.copy(m.kind == MessageKind.text ? m.text : m.preview(fr: context.isFr));
        Toast.show(copied, ToastType.success);
      case _MenuAction.delete:
        if (_replyTo?.id == m.id) setState(() => _replyTo = null);
        _chat.delete(m.id);
        Toast.show(context.tr('Message deleted', 'Message supprimé'));
    }
  }

  void _showAgentInfo() {
    _focus.unfocus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AgentSheet(agent: _chat.agent),
    );
  }

  Future<void> _onHeaderAction(_HeaderAction a) async {
    switch (a) {
      case _HeaderAction.help:
        context.push(const HelpScreen());
      case _HeaderAction.terms:
        context.push(const TermsScreen());
      case _HeaderAction.whatsapp:
        ExternalActions.openSupportWhatsApp();
      case _HeaderAction.clear:
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.tr('Clear this chat?', 'Effacer cette discussion ?')),
            content: Text(
              context.tr(
                'Messages will be removed from this phone. Support keeps a copy to help with your requests.',
                'Les messages seront supprimés de ce téléphone. Le support conserve une copie pour traiter vos demandes.',
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Cancel', 'Annuler'))),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(context.tr('Clear chat', 'Effacer'), style: TextStyle(color: context.colors.danger)),
              ),
            ],
          ),
        );
        if (ok != true || !mounted) return;
        _chat.clear();
        _chat.setOpen(true, fr: context.isFr, firstName: context.read<AppState>().user?.firstName);
        setState(() => _replyTo = null);
    }
  }

  void _openAttach() {
    _focus.unfocus();
    showModalBottomSheet<_Attachment>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AttachSheet(),
    ).then((a) {
      if (a != null && mounted) _attach(a);
    });
  }

  Future<void> _attach(_Attachment a) async {
    final s = context.read<AppState>();
    final fr = context.isFr;
    switch (a) {
      case _Attachment.slip:
      case _Attachment.receipt:
        if (s.purchases.isEmpty) {
          Toast.show(
            context.tr(
              'Unlock a slip first, then you can share it here',
              'Débloquez d’abord un relevé pour le partager ici',
            ),
            ToastType.warn,
          );
          return;
        }
        final slip = a == _Attachment.slip;
        final picked = await _pick<Purchase>(
          title: slip
              ? context.tr('Share a slip', 'Partager un relevé')
              : context.tr('Share a receipt', 'Partager un reçu'),
          items: s.purchases,
          leading: (p) => SlipThumbnail(result: p.result, width: 34),
          titleOf: (p) => p.result.name,
          subtitleOf: (p) =>
              slip ? '${p.result.stream} ${p.result.year} · ${p.result.cand}' : '${p.txnId} · ${p.method.label}',
        );
        if (picked == null) return;
        slip ? _chat.sendSlip(picked.result, fr: fr) : _chat.sendReceipt(picked, fr: fr);
      case _Attachment.candidate:
        final seen = <String>{};
        final people = <(String, String, String)>[
          for (final p in s.purchases)
            if (seen.add(p.result.cand)) (p.result.name, p.result.cand, p.result.centre),
          for (final c in s.savedCandidates)
            if (seen.add(c.cand)) (c.name, c.cand, c.centre),
        ];
        if (people.isEmpty) {
          _focus.requestFocus();
          Toast.show(
            context.tr(
              'Type the full name, candidate and centre numbers',
              'Écrivez le nom, le n° de candidat et le n° de centre',
            ),
          );
          return;
        }
        final who = await _pick<(String, String, String)>(
          title: context.tr('Send candidate details', 'Envoyer les infos du candidat'),
          items: people,
          leading: (p) => CircleAvatar(
            backgroundColor: context.colors.primarySoft,
            child: Text(
              p.$1[0],
              style: TextStyle(fontWeight: FontWeight.w800, color: context.colors.primary),
            ),
          ),
          titleOf: (p) => p.$1,
          subtitleOf: (p) => '${context.tr('Cand.', 'Cand.')} ${p.$2} · ${context.tr('Centre', 'Centre')} ${p.$3}',
        );
        if (who == null) return;
        _chat.sendText(
          fr
              ? 'Candidat : ${who.$1}\nN° candidat : ${who.$2}\nN° centre : ${who.$3}'
              : 'Candidate: ${who.$1}\nCandidate No: ${who.$2}\nCentre No: ${who.$3}',
          fr: fr,
        );
      case _Attachment.faq:
        context.push(const HelpScreen());
    }
  }

  Future<T?> _pick<T>({
    required String title,
    required List<T> items,
    required Widget Function(T) leading,
    required String Function(T) titleOf,
    required String Function(T) subtitleOf,
  }) {
    final c = context.colors;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  title,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.text),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  children: [
                    for (final item in items)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                        leading: leading(item),
                        title: Text(
                          titleOf(item),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w700, color: c.text),
                        ),
                        subtitle: Text(subtitleOf(item), style: TextStyle(fontSize: 12.5, color: c.text2)),
                        trailing: FaIcon(FontAwesomeIcons.solidPaperPlane, size: 15, color: c.primaryLight),
                        onTap: () => Navigator.pop(ctx, item),
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = ChatPalette.of(c);
    final user = context.select<AppState, AppUser?>((s) => s.user);

    return Scaffold(
      backgroundColor: p.wallpaper,
      body: ListenableBuilder(
        listenable: _chat,
        builder: (context, _) {
          final items = _items(_chat.messages, _chat.agentTyping);
          return Column(
            children: [
              _ChatHeader(
                palette: p,
                agent: _chat.agent,
                typing: _chat.agentTyping,
                onInfo: _showAgentInfo,
                onAction: _onHeaderAction,
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ChatWallpaper(color: p.wallpaper, doodle: p.doodle),
                    ),
                    LayoutBuilder(
                      builder: (context, box) {
                        final maxW = math.min(420.0, (box.maxWidth - 16) * 0.82);
                        return ListView.builder(
                          controller: _scroll,
                          reverse: true,
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.only(top: 8, bottom: 10),
                          itemCount: items.length,
                          findChildIndexCallback: (key) {
                            if (key is! ValueKey<String>) return null;
                            final i = items.indexWhere((it) => it.key == key.value);
                            return i < 0 ? null : i;
                          },
                          itemBuilder: (context, i) => switch (items[i]) {
                            _NoticeItem() => _PrivacyNotice(key: const ValueKey('notice'), palette: p),
                            final _DayItem d => _DayChip(key: ValueKey(d.key), day: d.day, palette: p),
                            final _MsgItem m => _messageRow(m, p, maxW, user),
                            _TypingItem() => Padding(
                              key: const ValueKey('typing'),
                              padding: const EdgeInsets.only(top: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _Entrance(animate: true, fromMe: false, child: TypingBubble(palette: p)),
                              ),
                            ),
                          },
                        );
                      },
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _JumpButton(visible: _showJump, count: _missed, palette: p, onTap: _jumpToBottom),
                    ),
                  ],
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _chat.hasUserMessages
                    ? const SizedBox(width: double.infinity)
                    : _QuickReplies(palette: p, onPick: _sendText),
              ),
              ChatComposer(
                palette: p,
                focusNode: _focus,
                agentName: _chat.agent.name,
                replyTo: _replyTo,
                onCancelReply: () => setState(() => _replyTo = null),
                onSendText: _sendText,
                onSendVoice: _sendVoice,
                onAttach: _openAttach,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _messageRow(_MsgItem item, ChatPalette p, double maxW, AppUser? user) {
    final m = item.message;
    final key = _keys.putIfAbsent(m.id, GlobalKey.new);
    final animate = !_seen.contains(m.id);
    if (animate) WidgetsBinding.instance.addPostFrameCallback((_) => _seen.add(m.id));
    return Padding(
      key: ValueKey(m.id),
      padding: EdgeInsets.only(top: item.tail ? 8 : 2),
      child: _Entrance(
        animate: animate,
        fromMe: m.fromMe,
        child: SwipeToReply(
          onReply: () => _reply(m),
          child: Align(
            alignment: m.fromMe ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onLongPress: () => _showActions(m, key, p, maxW, item.tail, user),
              child: KeyedSubtree(key: key, child: _bubble(m, p, maxW, item.tail, user)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.palette,
    required this.agent,
    required this.typing,
    required this.onInfo,
    required this.onAction,
  });

  final ChatPalette palette;
  final SupportAgent agent;
  final bool typing;
  final VoidCallback onInfo;
  final ValueChanged<_HeaderAction> onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    PopupMenuItem<_HeaderAction> item(_HeaderAction a, FaIconData icon, String label, {Color? color}) => PopupMenuItem(
      value: a,
      child: Row(
        children: [
          SizedBox(width: 22, child: FaIcon(icon, size: 15, color: color ?? c.text2)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: color ?? c.text, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return Material(
      color: palette.header,
      elevation: 3,
      shadowColor: Colors.black38,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18, color: Colors.white),
              ),
              Expanded(
                child: InkWell(
                  onTap: onInfo,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    child: Row(
                      children: [
                        SupportAvatar(initial: agent.initial, size: 40, online: true, ring: palette.header),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      context.tr('SlipNow Support', 'Support SlipNow'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(Icons.verified_rounded, size: 16, color: ChatPalette.readBlue),
                                ],
                              ),
                              const SizedBox(height: 1),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, a) => FadeTransition(
                                  opacity: a,
                                  child: SlideTransition(
                                    position: Tween(begin: const Offset(0, 0.4), end: Offset.zero).animate(a),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  typing
                                      ? context.tr('${agent.name} is typing…', '${agent.name} écrit…')
                                      : context.tr('online · ${agent.name}', 'en ligne · ${agent.name}'),
                                  key: ValueKey(typing),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: typing ? FontWeight.w600 : FontWeight.w400,
                                    color: Colors.white.withValues(alpha: typing ? 0.95 : 0.78),
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
              ),
              IconButton(
                onPressed: ExternalActions.callSupport,
                tooltip: context.tr('Call support', 'Appeler le support'),
                icon: const FaIcon(FontAwesomeIcons.phone, size: 17, color: Colors.white),
              ),
              PopupMenuButton<_HeaderAction>(
                tooltip: context.tr('More options', 'Plus d’options'),
                icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 18, color: Colors.white),
                color: c.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
                position: PopupMenuPosition.under,
                onSelected: onAction,
                itemBuilder: (_) => [
                  item(_HeaderAction.help, FontAwesomeIcons.circleQuestion, context.tr('Help center', "Centre d'aide")),
                  item(
                    _HeaderAction.terms,
                    FontAwesomeIcons.fileContract,
                    context.tr('Terms & conditions', 'Conditions d’utilisation'),
                  ),
                  item(
                    _HeaderAction.whatsapp,
                    FontAwesomeIcons.whatsapp,
                    context.tr('Continue on WhatsApp', 'Continuer sur WhatsApp'),
                  ),
                  const PopupMenuDivider(),
                  item(
                    _HeaderAction.clear,
                    FontAwesomeIcons.trashCan,
                    context.tr('Clear chat', 'Effacer la discussion'),
                    color: c.danger,
                  ),
                ],
              ),
              const SizedBox(width: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({super.key, required this.palette});

  final ChatPalette palette;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bg = c.isDark ? const Color(0xFF2A2716) : const Color(0xFFFFF3C4);
    final fg = c.isDark ? const Color(0xFFFFD279) : const Color(0xFF6B5310);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FaIcon(FontAwesomeIcons.lock, size: 10, color: fg),
                  ),
                ),
                TextSpan(
                  text: context.tr(
                    'Messages are private between you and SlipNow Support. We reply Monday to Saturday, 8am to 8pm.',
                    'Les messages restent privés entre vous et le support SlipNow. Réponses du lundi au samedi, de 8h à 20h.',
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.45, color: fg),
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({super.key, required this.day, required this.palette});

  final DateTime day;
  final ChatPalette palette;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final label = switch (today.difference(day).inDays) {
      0 => context.tr('Today', 'Aujourd’hui'),
      1 => context.tr('Yesterday', 'Hier'),
      _ => context.shortDate(day),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: palette.chip,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: palette.chipText),
          ),
        ),
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  const _QuickReplies({required this.palette, required this.onPick});

  final ChatPalette palette;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final replies = context.isFr
        ? const [
            '🔎 Je ne trouve pas mes résultats',
            '💳 Mon paiement a échoué',
            '📄 Est-ce mon relevé original ?',
            '📅 Quand sortent les résultats ?',
            '🎓 Utiliser mon relevé pour une bourse',
          ]
        : const [
            '🔎 I can’t find my results',
            '💳 My payment failed',
            '📄 Is this my original slip?',
            '📅 When are results released?',
            '🎓 Using my slip for a scholarship',
          ];
    final fg = c.isDark ? c.primaryLight : c.primary;
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => Material(
          color: palette.incoming,
          shape: StadiumBorder(side: BorderSide(color: fg.withValues(alpha: 0.35))),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              onPick(replies[i].substring(replies[i].indexOf(' ') + 1));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: Text(
                  replies[i],
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JumpButton extends StatelessWidget {
  const _JumpButton({required this.visible, required this.count, required this.palette, required this.onTap});

  final bool visible;
  final int count;
  final ChatPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedScale(
        scale: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        curve: visible ? Curves.easeOutBack : Curves.easeIn,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: palette.chip,
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(
                  width: 42,
                  height: 42,
                  child: Center(child: FaIcon(FontAwesomeIcons.angleDown, size: 18, color: c.text2)),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: -6,
                left: -4,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: ChatPalette.online,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Grows and fades in newly arrived messages; existing ones render as is.
class _Entrance extends StatefulWidget {
  const _Entrance({required this.animate, required this.fromMe, required this.child});

  final bool animate;
  final bool fromMe;
  final Widget child;

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: widget.animate ? 0 : 1,
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curve,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _curve,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(_curve),
          alignment: widget.fromMe ? Alignment.bottomRight : Alignment.bottomLeft,
          child: widget.child,
        ),
      ),
    );
  }
}

class _MessageActions extends StatelessWidget {
  const _MessageActions({required this.rect, required this.message, required this.bubble});

  final Rect rect;
  final ChatMessage message;
  final Widget bubble;

  static const _reactions = ['👍', '❤️', '😂', '😮', '😢', '🙏'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mq = MediaQuery.of(context);
    final size = mq.size;
    const barH = 52.0;
    const gap = 10.0;
    final canCopy = message.kind == MessageKind.text;
    final menuH = (canCopy ? 3 : 2) * 50.0 + 12;
    final minTop = mq.padding.top + barH + gap + 12;
    final maxBottom = size.height - mq.padding.bottom - menuH - gap - 12;
    final h = math.max(60.0, math.min(rect.height, maxBottom - minTop));
    final top = rect.top.clamp(minTop, math.max(minTop, maxBottom - h)).toDouble();
    final mine = message.fromMe;
    final sideLeft = mine ? null : rect.left + 4;
    final sideRight = mine ? math.max(8.0, size.width - rect.right + 4) : null;

    Widget menuItem(_MenuAction a, FaIconData icon, String label, {Color? color}) => InkWell(
      onTap: () => Navigator.pop(context, a),
      child: SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color ?? c.text),
                ),
              ),
              FaIcon(icon, size: 16, color: color ?? c.text2),
            ],
          ),
        ),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: ColoredBox(color: Colors.black.withValues(alpha: c.isDark ? 0.45 : 0.28)),
            ),
          ),
        ),
        Positioned(
          left: rect.left,
          top: top,
          width: rect.width,
          height: h,
          child: IgnorePointer(
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: 0,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Material(type: MaterialType.transparency, child: bubble),
              ),
            ),
          ),
        ),
        Positioned(
          top: top - barH - gap,
          left: sideLeft,
          right: sideRight,
          child: Material(
            color: c.surface,
            elevation: 6,
            shadowColor: Colors.black45,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SizedBox(
                height: barH,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _reactions.length; i++)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: Duration(milliseconds: 220 + i * 45),
                        curve: Curves.easeOutBack,
                        builder: (_, s, child) => Transform.scale(scale: s, child: child),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(context, _reactions[i]);
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: message.myReaction == _reactions[i] ? c.text3.withValues(alpha: 0.25) : null,
                            ),
                            child: Text(_reactions[i], style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: top + h + gap,
          left: sideLeft,
          right: sideRight,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            builder: (_, s, child) =>
                Transform.scale(scale: s, alignment: mine ? Alignment.topRight : Alignment.topLeft, child: child),
            child: Material(
              color: c.surface,
              elevation: 6,
              shadowColor: Colors.black45,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: 220,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      menuItem(_MenuAction.reply, FontAwesomeIcons.reply, context.tr('Reply', 'Répondre')),
                      if (canCopy) menuItem(_MenuAction.copy, FontAwesomeIcons.copy, context.tr('Copy', 'Copier')),
                      menuItem(
                        _MenuAction.delete,
                        FontAwesomeIcons.trashCan,
                        context.tr('Delete for me', 'Supprimer pour moi'),
                        color: c.danger,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AttachSheet extends StatelessWidget {
  const _AttachSheet();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final options = [
      (_Attachment.slip, FontAwesomeIcons.filePdf, const Color(0xFF7F66FF), context.tr('Slip', 'Relevé')),
      (_Attachment.receipt, FontAwesomeIcons.receipt, const Color(0xFFFF7F29), context.tr('Receipt', 'Reçu')),
      (_Attachment.candidate, FontAwesomeIcons.idCard, const Color(0xFF009DE1), context.tr('Candidate', 'Candidat')),
      (_Attachment.faq, FontAwesomeIcons.circleQuestion, const Color(0xFF1FA855), context.tr('FAQ', 'FAQ')),
    ];
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 18),
        decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(24), boxShadow: c.shadowLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < options.length; i++)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 260 + i * 50),
                    curve: Curves.easeOutBack,
                    builder: (_, s, child) => Transform.scale(scale: s, child: child),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context, options[i].$1),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color.lerp(options[i].$3, Colors.white, 0.12)!, options[i].$3],
                                ),
                              ),
                              child: FaIcon(options[i].$2, size: 22, color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(options[i].$4, style: TextStyle(fontSize: 12.5, color: c.text2)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              context.tr(
                'Tip: hold the mic button to send a voice note.',
                'Astuce : maintenez le micro pour envoyer une note vocale.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: c.text3),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgentSheet extends StatelessWidget {
  const _AgentSheet({required this.agent});

  final SupportAgent agent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget action(FaIconData icon, String label, VoidCallback onTap) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              FaIcon(icon, size: 18, color: c.primaryLight),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.text),
              ),
            ],
          ),
        ),
      ),
    );

    Widget row(FaIconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 28, child: FaIcon(icon, size: 15, color: c.text3)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text),
                ),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(fontSize: 12.5, height: 1.45, color: c.text2)),
              ],
            ),
          ),
        ],
      ),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.paddingOf(context).bottom),
          children: [
            const _SheetHandle(),
            const SizedBox(height: 6),
            Center(
              child: SupportAvatar(initial: agent.initial, size: 88, online: true, ring: c.surface),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.tr('SlipNow Support', 'Support SlipNow'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.text),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.verified_rounded, size: 20, color: ChatPalette.readBlue),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${agent.name} · ${context.tr(agent.roleEn, agent.roleFr)}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: c.text2),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('Online · usually replies in minutes', 'En ligne · répond en quelques minutes'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: ChatPalette.online),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                action(FontAwesomeIcons.phone, context.tr('Call', 'Appeler'), ExternalActions.callSupport),
                const SizedBox(width: 10),
                action(FontAwesomeIcons.whatsapp, 'WhatsApp', ExternalActions.openSupportWhatsApp),
                const SizedBox(width: 10),
                action(FontAwesomeIcons.circleQuestion, context.tr('Help', 'Aide'), () {
                  Navigator.pop(context);
                  context.push(const HelpScreen());
                }),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: c.border),
            row(
              FontAwesomeIcons.clock,
              context.tr('Support hours', 'Horaires du support'),
              context.tr('Monday to Saturday, 8am to 8pm (WAT).', 'Du lundi au samedi, de 8h à 20h (WAT).'),
            ),
            row(
              FontAwesomeIcons.heartPulse,
              context.tr('What we help with', 'Nos domaines d’aide'),
              context.tr(
                'Finding your results, payments and refunds, and using your slip for public exams, scholarships and admissions at home or abroad.',
                'Trouver vos résultats, paiements et remboursements, et utiliser votre relevé pour les examens publics, bourses et admissions au pays ou à l’étranger.',
              ),
            ),
            row(
              FontAwesomeIcons.lock,
              context.tr('Private conversation', 'Conversation privée'),
              context.tr(
                'Only you and the SlipNow support team can read these messages.',
                'Seuls vous et l’équipe support SlipNow pouvez lire ces messages.',
              ),
            ),
            const SizedBox(height: 8),
            const OriginalSlipNotice(),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push(const TermsScreen());
              },
              child: Text(context.tr('Read our Terms & conditions', 'Lire nos conditions d’utilisation')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: context.colors.borderStrong, borderRadius: BorderRadius.circular(2)),
    ),
  );
}
