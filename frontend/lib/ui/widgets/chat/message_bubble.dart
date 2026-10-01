import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants.dart';
import '../../../core/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/chat.dart';
import '../slip_document.dart';
import 'chat_theme.dart';
import 'support_avatar.dart';

/// True for short messages made only of emoji, which render large and
/// without a bubble.
bool isEmojiOnly(String s) {
  final t = s.trim();
  if (t.isEmpty || t.characters.length > 3) return false;
  for (final r in t.runes) {
    final emoji =
        r >= 0x1F000 ||
        (r >= 0x2190 && r <= 0x21FF) ||
        (r >= 0x2600 && r <= 0x27BF) ||
        (r >= 0x2B00 && r <= 0x2BFF) ||
        r == 0x200D ||
        r == 0xFE0F ||
        r == 0x20;
    if (!emoji) return false;
  }
  return true;
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.palette,
    required this.maxWidth,
    required this.tail,
    required this.agentName,
    required this.agentInitial,
    required this.userInitial,
    this.quoted,
    this.onQuoteTap,
    this.onOpenSlip,
    this.onOpenReceipt,
    this.onReactionTap,
    this.highlight = false,
  });

  final ChatMessage message;
  final ChatPalette palette;
  final double maxWidth;
  final bool tail;
  final String agentName;
  final String agentInitial;
  final String userInitial;
  final ChatMessage? quoted;
  final VoidCallback? onQuoteTap;
  final VoidCallback? onOpenSlip;
  final VoidCallback? onOpenReceipt;
  final VoidCallback? onReactionTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = message;
    final mine = m.fromMe;
    final emojiOnly = m.kind == MessageKind.text && quoted == null && isEmojiOnly(m.text);
    final reactions = <String>[?m.theirReaction, ?m.myReaction];
    final base = mine ? palette.outgoing : palette.incoming;
    final color = emojiOnly ? Colors.transparent : (highlight ? Color.lerp(base, c.accent, 0.28)! : base);

    final quote = quoted == null
        ? null
        : _QuoteBlock(quoted: quoted!, palette: palette, mine: mine, agentName: agentName, onTap: onQuoteTap);

    final Widget content = switch (m.kind) {
      MessageKind.text when emojiOnly => _EmojiContent(message: m, palette: palette),
      MessageKind.text => _TextContent(message: m, palette: palette, quote: quote),
      MessageKind.voice => _VoiceNote(
        message: m,
        palette: palette,
        quote: quote,
        avatar: mine
            ? _UserAvatar(initial: userInitial)
            : SupportAvatar(initial: agentInitial, size: 40, ring: palette.incoming),
      ),
      MessageKind.slip => _SlipAttachment(message: m, palette: palette, onTap: onOpenSlip),
      MessageKind.receipt => _ReceiptAttachment(message: m, palette: palette, onTap: onOpenReceipt),
    };

    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, reactions.isEmpty ? 0 : 18),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: CustomPaint(
              painter: BubblePainter(color: color, mine: mine, tail: tail && !emojiOnly, shadow: !emojiOnly),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: content,
              ),
            ),
          ),
          if (reactions.isNotEmpty)
            Positioned(
              bottom: -18,
              left: mine ? null : 10,
              right: mine ? 10 : null,
              child: _Reactions(emojis: reactions, palette: palette, onTap: onReactionTap),
            ),
        ],
      ),
    );
  }
}

/// Rounded bubble with WhatsApp's pointed tail on the first message of a
/// group. The tail is drawn into the 8px gutter outside the child.
class BubblePainter extends CustomPainter {
  BubblePainter({required this.color, required this.mine, required this.tail, this.shadow = true});

  final Color color;
  final bool mine;
  final bool tail;
  final bool shadow;

  static Path pathFor(Size s, {required bool mine, required bool tail}) {
    const r = 10.0;
    const t = 7.0;
    final w = s.width;
    final h = s.height;
    final p = Path()..moveTo(r, 0);
    if (tail) {
      p
        ..lineTo(w + t - 1.5, 0)
        ..quadraticBezierTo(w + t + 0.6, 0.3, w + t - 0.9, 2.3)
        ..lineTo(w, t + 3);
    } else {
      p
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: const Radius.circular(r));
    }
    p
      ..lineTo(w, h - r)
      ..arcToPoint(Offset(w - r, h), radius: const Radius.circular(r))
      ..lineTo(r, h)
      ..arcToPoint(Offset(0, h - r), radius: const Radius.circular(r))
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..close();
    if (mine) return p;
    final mirror = Matrix4.identity()
      ..translateByDouble(w, 0, 0, 1)
      ..scaleByDouble(-1, 1, 1, 1);
    return p.transform(mirror.storage);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;
    final path = pathFor(size, mine: mine, tail: tail);
    if (shadow) canvas.drawShadow(path, Colors.black.withValues(alpha: 0.4), 0.7, true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(BubblePainter old) =>
      old.color != color || old.mine != mine || old.tail != tail || old.shadow != shadow;
}

/// Time plus delivery ticks: clock (sending), single grey tick (sent),
/// double grey (delivered), double blue (read).
class MessageMeta extends StatelessWidget {
  const MessageMeta({super.key, required this.message, required this.color});

  final ChatMessage message;
  final Color color;

  static double widthFor(ChatMessage m) => m.fromMe ? 54 : 36;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final (icon, tickColor, label) = switch (m.status) {
      MessageStatus.sending => (FontAwesomeIcons.clock, color, context.tr('Sending', 'Envoi')),
      MessageStatus.sent => (FontAwesomeIcons.check, color, context.tr('Sent', 'Envoyé')),
      MessageStatus.delivered => (FontAwesomeIcons.checkDouble, color, context.tr('Delivered', 'Distribué')),
      MessageStatus.read => (FontAwesomeIcons.checkDouble, ChatPalette.readBlue, context.tr('Read', 'Lu')),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.clock(m.time), style: TextStyle(fontSize: 11, height: 1, color: color)),
        if (m.fromMe) ...[
          const SizedBox(width: 4),
          Semantics(
            label: label,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: SizedBox(
                key: ValueKey(m.status),
                width: 15,
                child: FaIcon(icon, size: m.status == MessageStatus.sending ? 10 : 11.5, color: tickColor),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TextContent extends StatelessWidget {
  const _TextContent({required this.message, required this.palette, this.quote});

  final ChatMessage message;
  final ChatPalette palette;
  final Widget? quote;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final text = Stack(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: m.text),
              WidgetSpan(child: SizedBox(width: MessageMeta.widthFor(m) + 4, height: 12)),
            ],
          ),
          style: TextStyle(fontSize: 15, height: 1.35, color: palette.text),
        ),
        Positioned(
          right: 0,
          bottom: 1,
          child: MessageMeta(message: m, color: palette.meta),
        ),
      ],
    );
    final body = quote == null
        ? text
        : IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                quote!,
                const SizedBox(height: 4),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: text),
              ],
            ),
          );
    return Padding(
      padding: quote == null ? const EdgeInsets.fromLTRB(9, 6, 9, 6) : const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: body,
    );
  }
}

class _EmojiContent extends StatelessWidget {
  const _EmojiContent({required this.message, required this.palette});

  final ChatMessage message;
  final ChatPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: message.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message.text, style: const TextStyle(fontSize: 46, height: 1.15)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: palette.chip.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: MessageMeta(message: message, color: palette.meta),
        ),
      ],
    );
  }
}

class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({
    required this.quoted,
    required this.palette,
    required this.mine,
    required this.agentName,
    this.onTap,
  });

  final ChatMessage quoted;
  final ChatPalette palette;
  final bool mine;
  final String agentName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = quoted.fromMe ? c.primaryLight : c.accentDark;
    final icon = switch (quoted.kind) {
      MessageKind.voice => FontAwesomeIcons.microphone,
      MessageKind.slip => FontAwesomeIcons.filePdf,
      MessageKind.receipt => FontAwesomeIcons.receipt,
      MessageKind.text => null,
    };
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: mine ? palette.quoteMine : palette.quoteTheirs,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 10, 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          quoted.fromMe ? context.tr('You', 'Vous') : agentName,
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: accent),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              FaIcon(icon, size: 11, color: palette.meta),
                              const SizedBox(width: 5),
                            ],
                            Flexible(
                              child: Text(
                                quoted.preview(fr: context.isFr),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.3,
                                  color: palette.text.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
          child: Text(
            initial,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        Positioned(
          left: -3,
          bottom: -2,
          child: FaIcon(FontAwesomeIcons.microphone, size: 13, color: ChatPalette.readBlue),
        ),
      ],
    );
  }
}

class _VoiceNote extends StatefulWidget {
  const _VoiceNote({required this.message, required this.palette, required this.avatar, this.quote});

  final ChatMessage message;
  final ChatPalette palette;
  final Widget avatar;
  final Widget? quote;

  @override
  State<_VoiceNote> createState() => _VoiceNoteState();
}

class _VoiceNoteState extends State<_VoiceNote> with SingleTickerProviderStateMixin {
  static const _speeds = [1.0, 1.5, 2.0];
  late final AnimationController _c;
  bool _playing = false;
  int _speed = 0;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _duration(1))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) {
          _c.value = 0;
          setState(() => _playing = false);
        }
      });
  }

  Duration _duration(double speed) =>
      Duration(milliseconds: (math.max(1, widget.message.voiceSeconds) * 1000 / speed).round());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _playing = !_playing);
    _playing ? _c.forward() : _c.stop();
  }

  void _cycleSpeed() {
    setState(() => _speed = (_speed + 1) % _speeds.length);
    _c.duration = _duration(_speeds[_speed]);
    if (_playing) _c.forward();
  }

  void _seek(double dx, double width) {
    _c.value = (dx / width).clamp(0.0, 1.0);
    if (_playing) _c.forward();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = widget.message;
    final mine = m.fromMe;
    final p = widget.palette;
    final started = _playing || _c.value > 0;

    final side = SizedBox(
      width: 44,
      height: 40,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: started
              ? GestureDetector(
                  key: const ValueKey('speed'),
                  onTap: _cycleSpeed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.text.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${_speeds[_speed].toString().replaceAll('.0', '')}×',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: p.text),
                    ),
                  ),
                )
              : KeyedSubtree(key: const ValueKey('avatar'), child: widget.avatar),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 9, 5),
      child: SizedBox(
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.quote != null) ...[widget.quote!, const SizedBox(height: 4)],
            Row(
              children: [
                if (!mine) side,
                IconButton(
                  onPressed: _toggle,
                  visualDensity: VisualDensity.compact,
                  tooltip: _playing ? context.tr('Pause', 'Pause') : context.tr('Play', 'Lire'),
                  icon: FaIcon(
                    _playing ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                    size: 20,
                    color: p.text.withValues(alpha: 0.7),
                  ),
                ),
                Expanded(
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      final elapsed = (_c.value * m.voiceSeconds).floor();
                      final shown = started ? elapsed : m.voiceSeconds;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 6),
                          LayoutBuilder(
                            builder: (context, box) => GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (d) => _seek(d.localPosition.dx, box.maxWidth),
                              onHorizontalDragUpdate: (d) => _seek(d.localPosition.dx, box.maxWidth),
                              child: CustomPaint(
                                size: Size(box.maxWidth, 26),
                                painter: _WaveformPainter(
                                  seed: m.id.hashCode,
                                  progress: _c.value,
                                  played: mine ? ChatPalette.readBlue : c.primaryLight,
                                  unplayed: p.text.withValues(alpha: 0.28),
                                  thumb: mine ? ChatPalette.readBlue : c.primaryLight,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '0:${shown.toString().padLeft(2, '0')}',
                                style: TextStyle(fontSize: 11, color: p.meta),
                              ),
                              const Spacer(),
                              MessageMeta(message: m, color: p.meta),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                if (mine) side,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.seed,
    required this.progress,
    required this.played,
    required this.unplayed,
    required this.thumb,
  });

  final int seed;
  final double progress;
  final Color played;
  final Color unplayed;
  final Color thumb;

  static const _bars = 32;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    final step = size.width / _bars;
    final bar = Paint()
      ..strokeWidth = math.max(2, step * 0.5)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < _bars; i++) {
      final h = size.height * (0.2 + 0.8 * math.pow(rnd.nextDouble(), 1.4));
      final x = step * i + step / 2;
      bar.color = (i + 0.5) / _bars <= progress ? played : unplayed;
      canvas.drawLine(Offset(x, (size.height - h) / 2), Offset(x, (size.height + h) / 2), bar);
    }
    canvas.drawCircle(Offset(size.width * progress.clamp(0.02, 0.98), size.height / 2), 6, Paint()..color = thumb);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.played != played || old.unplayed != unplayed;
}

class _SlipAttachment extends StatelessWidget {
  const _SlipAttachment({required this.message, required this.palette, this.onTap});

  final ChatMessage message;
  final ChatPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final r = message.slip!;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: 244,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SlipThumbnail(result: r, width: 244, aspectRatio: 0.5),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: message.fromMe ? palette.quoteMine : palette.quoteTheirs,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 38,
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(color: c.danger, borderRadius: BorderRadius.circular(5)),
                      child: const Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.pdfFileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${context.tr('1 page', '1 page')} · PDF · ${r.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: palette.meta),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 4, 1),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: MessageMeta(message: message, color: palette.meta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptAttachment extends StatelessWidget {
  const _ReceiptAttachment({required this.message, required this.palette, this.onTap});

  final ChatMessage message;
  final ChatPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = message.receipt!;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          width: 244,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message.fromMe ? palette.quoteMine : palette.quoteTheirs,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(AppRadius.sm)),
                      child: const FaIcon(FontAwesomeIcons.receipt, size: 16, color: AppColors.onAccent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Payment receipt', 'Reçu de paiement'),
                            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: palette.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p.txnId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.mono(size: 11.5, color: palette.text).copyWith(letterSpacing: 0.3),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${context.tr(AppConstants.slipPriceLabel, AppConstants.slipPriceLabelFr)} · ${p.method.label}',
                            style: TextStyle(fontSize: 11.5, color: palette.meta),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 4, 1),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: MessageMeta(message: message, color: palette.meta),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Reactions extends StatelessWidget {
  const _Reactions({required this.emojis, required this.palette, this.onTap});

  final List<String> emojis;
  final ChatPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final unique = emojis.toSet().toList();
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (_, s, child) => Transform.scale(scale: s, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: palette.chip,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: palette.wallpaper, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in unique) Text(e, style: const TextStyle(fontSize: 14)),
              if (emojis.length > unique.length || unique.length > 1) ...[
                const SizedBox(width: 3),
                Text(
                  '${emojis.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.meta),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Drag a message to the right to quote it in a reply.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({super.key, required this.child, required this.onReply});

  final Widget child;
  final VoidCallback onReply;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply> with SingleTickerProviderStateMixin {
  static const _trigger = 56.0;
  static const _max = 84.0;
  late final AnimationController _back;
  double _dx = 0;
  double _from = 0;
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _back = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
      ..addListener(() => setState(() => _dx = _from * (1 - Curves.easeOutCubic.transform(_back.value))));
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = (_dx / _trigger).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _back.stop(),
      onHorizontalDragUpdate: (d) {
        setState(() => _dx = (_dx + d.delta.dx * (_dx > _trigger ? 0.35 : 1)).clamp(0.0, _max));
        if (!_armed && _dx >= _trigger) {
          _armed = true;
          HapticFeedback.lightImpact();
        } else if (_armed && _dx < _trigger) {
          _armed = false;
        }
      },
      onHorizontalDragEnd: (_) {
        if (_armed) widget.onReply();
        _armed = false;
        _from = _dx;
        _back.forward(from: 0);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (_dx > 0)
            Positioned(
              left: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Opacity(
                  opacity: t,
                  child: Transform.scale(
                    scale: 0.6 + 0.4 * t,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: c.isDark ? 0.35 : 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(FontAwesomeIcons.reply, size: 13, color: c.isDark ? Colors.white : c.text2),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),
        ],
      ),
    );
  }
}

/// Agent-side bubble with three bouncing dots.
class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key, required this.palette});

  final ChatPalette palette;

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CustomPaint(
        painter: BubblePainter(color: p.incoming, mine: false, tail: true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 5),
                  Transform.translate(
                    offset: Offset(0, -4 * math.max(0, math.sin((_c.value - i * 0.15) * 2 * math.pi))),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: p.meta.withValues(
                          alpha: 0.5 + 0.5 * math.max(0, math.sin((_c.value - i * 0.15) * 2 * math.pi)),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
