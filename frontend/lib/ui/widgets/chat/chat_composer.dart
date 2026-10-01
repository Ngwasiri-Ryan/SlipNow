import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/chat.dart';
import '../feedback.dart';
import 'chat_theme.dart';

/// WhatsApp-style input bar: pill text field with emoji and attach buttons,
/// a reply preview, and a send button that turns into a hold-to-record mic.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.palette,
    required this.focusNode,
    required this.agentName,
    required this.onSendText,
    required this.onSendVoice,
    required this.onAttach,
    this.replyTo,
    this.onCancelReply,
  });

  final ChatPalette palette;
  final FocusNode focusNode;
  final String agentName;
  final ValueChanged<String> onSendText;
  final ValueChanged<int> onSendVoice;
  final VoidCallback onAttach;
  final ChatMessage? replyTo;
  final VoidCallback? onCancelReply;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> with SingleTickerProviderStateMixin {
  static const _cancelDistance = 110.0;

  final _text = TextEditingController();
  late final AnimationController _pulse;
  bool _emoji = false;
  bool _recording = false;
  double _dragDx = 0;
  final _stopwatch = Stopwatch();
  Timer? _ticker;

  bool get _hasText => _text.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _text.addListener(() => setState(() {}));
    widget.focusNode.addListener(() {
      if (widget.focusNode.hasFocus && _emoji) setState(() => _emoji = false);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    _text.dispose();
    super.dispose();
  }

  void _send() {
    if (!_hasText) return;
    HapticFeedback.selectionClick();
    widget.onSendText(_text.text);
    _text.clear();
  }

  void _toggleEmoji() {
    if (_emoji) {
      setState(() => _emoji = false);
      widget.focusNode.requestFocus();
    } else {
      widget.focusNode.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      setState(() => _emoji = true);
    }
  }

  void _insert(String s) {
    final v = _text.value;
    final sel = v.selection.isValid ? v.selection : TextSelection.collapsed(offset: v.text.length);
    final next = v.text.replaceRange(sel.start, sel.end, s);
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: sel.start + s.length),
    );
  }

  void _backspace() {
    final v = _text.value;
    if (v.text.isEmpty) return;
    final sel = v.selection.isValid ? v.selection : TextSelection.collapsed(offset: v.text.length);
    if (!sel.isCollapsed) {
      _text.value = TextEditingValue(
        text: v.text.replaceRange(sel.start, sel.end, ''),
        selection: TextSelection.collapsed(offset: sel.start),
      );
      return;
    }
    final before = v.text.substring(0, sel.start).characters;
    if (before.isEmpty) return;
    final kept = before.skipLast(1).toString();
    _text.value = TextEditingValue(
      text: kept + v.text.substring(sel.start),
      selection: TextSelection.collapsed(offset: kept.length),
    );
  }

  void _startRecording() {
    HapticFeedback.mediumImpact();
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => setState(() {}));
    _pulse.repeat(reverse: true);
    setState(() {
      _recording = true;
      _dragDx = 0;
    });
  }

  void _stopRecording({required bool send}) {
    if (!_recording) return;
    _ticker?.cancel();
    _stopwatch.stop();
    _pulse.stop();
    final ms = _stopwatch.elapsedMilliseconds;
    setState(() {
      _recording = false;
      _dragDx = 0;
    });
    if (!send) {
      HapticFeedback.heavyImpact();
      Toast.show(context.tr('Voice note cancelled', 'Note vocale annulée'), ToastType.warn);
      return;
    }
    if (ms < 800) {
      Toast.show(context.tr('Hold to record, release to send', 'Maintenez pour enregistrer, relâchez pour envoyer'));
      return;
    }
    HapticFeedback.selectionClick();
    widget.onSendVoice(math.max(1, (ms / 1000).round()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = widget.palette;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return PopScope(
      canPop: !_emoji,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _emoji = false);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(6, 4, 6, 6 + (_emoji ? 0 : bottom)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _recording ? _recordingPill(c, p) : _inputPill(c, p),
                  ),
                ),
                const SizedBox(width: 6),
                _actionButton(c),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: _emoji
                ? EmojiPanel(palette: p, onPick: _insert, onBackspace: _backspace, bottomPadding: bottom)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _inputPill(AppColors c, ChatPalette p) {
    final reply = widget.replyTo;
    return Container(
      key: const ValueKey('input'),
      decoration: BoxDecoration(
        color: p.incoming,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: reply == null
                ? const SizedBox(width: double.infinity)
                : _ReplyPreview(message: reply, palette: p, agentName: widget.agentName, onClose: widget.onCancelReply),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: _toggleEmoji,
                tooltip: _emoji ? context.tr('Keyboard', 'Clavier') : context.tr('Emoji', 'Émoji'),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, a) => RotationTransition(
                    turns: Tween(begin: 0.75, end: 1.0).animate(a),
                    child: FadeTransition(opacity: a, child: child),
                  ),
                  child: FaIcon(
                    _emoji ? FontAwesomeIcons.keyboard : FontAwesomeIcons.faceSmile,
                    key: ValueKey(_emoji),
                    size: 21,
                    color: c.text3,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: TextField(
                    controller: _text,
                    focusNode: widget.focusNode,
                    minLines: 1,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(fontSize: 16, color: p.text, height: 1.3),
                    cursorColor: c.primaryLight,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      hintText: context.tr('Message', 'Message'),
                      hintStyle: TextStyle(fontSize: 16, color: c.text3),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onAttach,
                tooltip: context.tr('Attach', 'Joindre'),
                icon: Transform.rotate(
                  angle: -math.pi / 4,
                  child: FaIcon(FontAwesomeIcons.paperclip, size: 20, color: c.text3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recordingPill(AppColors c, ChatPalette p) {
    final secs = _stopwatch.elapsed.inSeconds;
    final time = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    final progress = (-_dragDx / _cancelDistance).clamp(0.0, 1.0);
    return Container(
      key: const ValueKey('recording'),
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: p.incoming,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.25).animate(_pulse),
            child: FaIcon(FontAwesomeIcons.microphone, size: 18, color: c.danger),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: TextStyle(fontSize: 16, color: p.text, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const Spacer(),
          Opacity(
            opacity: 1 - progress,
            child: Transform.translate(
              offset: Offset(_dragDx * 0.6, 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FaIcon(FontAwesomeIcons.chevronLeft, size: 11, color: c.text3),
                  const SizedBox(width: 6),
                  Text(
                    context.tr('Slide to cancel', 'Glissez pour annuler'),
                    style: TextStyle(fontSize: 14, color: c.text3),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _actionButton(AppColors c) {
    final send = _hasText;
    return GestureDetector(
      onTap: send
          ? _send
          : () => Toast.show(
              context.tr('Hold to record, release to send', 'Maintenez pour enregistrer, relâchez pour envoyer'),
            ),
      onLongPressStart: send ? null : (_) => _startRecording(),
      onLongPressMoveUpdate: send
          ? null
          : (d) {
              setState(() => _dragDx = math.min(0, d.offsetFromOrigin.dx));
              if (_dragDx < -_cancelDistance) _stopRecording(send: false);
            },
      onLongPressEnd: send ? null : (_) => _stopRecording(send: true),
      onLongPressCancel: () => _stopRecording(send: false),
      child: Semantics(
        button: true,
        label: send ? context.tr('Send', 'Envoyer') : context.tr('Record voice note', 'Enregistrer une note vocale'),
        child: AnimatedScale(
          scale: _recording ? 1.35 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: Transform.translate(
            offset: Offset(_recording ? _dragDx * 0.35 : 0, 0),
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.primaryLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: c.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, a) => ScaleTransition(
                  scale: a,
                  child: RotationTransition(turns: Tween(begin: -0.2, end: 0.0).animate(a), child: child),
                ),
                child: FaIcon(
                  send ? FontAwesomeIcons.solidPaperPlane : FontAwesomeIcons.microphone,
                  key: ValueKey(send),
                  size: 19,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.message, required this.palette, required this.agentName, this.onClose});

  final ChatMessage message;
  final ChatPalette palette;
  final String agentName;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = message.fromMe ? c.primaryLight : c.accentDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: Colors.black.withValues(alpha: c.isDark ? 0.25 : 0.05),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          message.fromMe ? context.tr('You', 'Vous') : agentName,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: accent),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message.preview(fr: context.isFr),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: palette.text.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: IconButton(
                    onPressed: onClose,
                    visualDensity: VisualDensity.compact,
                    tooltip: context.tr('Cancel reply', 'Annuler la réponse'),
                    icon: FaIcon(FontAwesomeIcons.xmark, size: 14, color: c.text3),
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

/// Emoji keyboard shown in place of the system keyboard.
class EmojiPanel extends StatefulWidget {
  const EmojiPanel({
    super.key,
    required this.palette,
    required this.onPick,
    required this.onBackspace,
    this.bottomPadding = 0,
  });

  final ChatPalette palette;
  final ValueChanged<String> onPick;
  final VoidCallback onBackspace;
  final double bottomPadding;

  static const _categories = <(FaIconData, String)>[
    (
      FontAwesomeIcons.faceSmile,
      '😀 😃 😄 😁 😆 😅 😂 🤣 🙂 😉 😊 😇 🥰 😍 🤩 😘 😋 😜 🤗 🤭 🤔 🤐 😐 😏 😌 😔 😴 😷 🥺 😢 😭 😤 😡 😱 😳 🥳 😎 🤓 🧐 😬 🙄 😮 😯 😲 🥹 🫠 🫡 🤯',
    ),
    (
      FontAwesomeIcons.handsClapping,
      '👍 👎 👌 ✌️ 🤞 🤟 🤙 👋 🙌 👏 🙏 🤝 💪 ✍️ 👀 🫶 👆 👇 👉 👈 ☝️ ✋ 🤚 🖐️ 🫵 🤲 🙋 🙆 🙅 🤷 🙇 💁',
    ),
    (FontAwesomeIcons.heart, '❤️ 🧡 💛 💚 💙 💜 🖤 🤍 💯 💥 ✨ 🔥 ⭐ 🌟 🎉 🎊 🎈 🎁 🏆 🥇 🥈 🥉 🏅 🎖️ ✅ ❌ ❗ ❓ 💬 💭'),
    (
      FontAwesomeIcons.graduationCap,
      '🎓 📚 📖 📝 ✏️ 🖊️ 📄 📃 📑 📊 📈 🧮 🔬 🧪 💡 🏫 🌍 ✈️ 🛂 💼 📱 💻 📧 📅 ⏰ ⏳ 💳 💰 🇨🇲 🇬🇧 🇫🇷 🇺🇸 🇨🇦',
    ),
  ];

  @override
  State<EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<EmojiPanel> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final emojis = EmojiPanel._categories[_tab].$2.split(' ');
    return Container(
      height: 290 + widget.bottomPadding,
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 46,
            child: Row(
              children: [
                const SizedBox(width: 6),
                for (var i = 0; i < EmojiPanel._categories.length; i++)
                  _TabIcon(
                    icon: EmojiPanel._categories[i].$1,
                    selected: i == _tab,
                    onTap: () => setState(() => _tab = i),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: widget.onBackspace,
                  tooltip: context.tr('Backspace', 'Effacer'),
                  icon: FaIcon(FontAwesomeIcons.deleteLeft, size: 18, color: c.text2),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          Divider(height: 1, color: c.border),
          Expanded(
            child: GridView.builder(
              key: PageStorageKey(_tab),
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 48),
              itemCount: emojis.length,
              itemBuilder: (_, i) => InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onPick(emojis[i]);
                },
                child: Center(child: Text(emojis[i], style: const TextStyle(fontSize: 28))),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.selected, required this.onTap});

  final FaIconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: selected ? c.primaryLight : Colors.transparent, width: 2.5)),
        ),
        child: FaIcon(icon, size: 18, color: selected ? c.primaryLight : c.text3),
      ),
    );
  }
}
