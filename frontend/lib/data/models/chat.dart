import 'models.dart';

enum ChatSender { me, agent }

enum MessageStatus { sending, sent, delivered, read }

enum MessageKind { text, voice, slip, receipt }

class SupportAgent {
  const SupportAgent({required this.name, required this.roleEn, required this.roleFr});

  final String name;
  final String roleEn;
  final String roleFr;

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.time,
    this.kind = MessageKind.text,
    this.text = '',
    this.status = MessageStatus.sending,
    this.replyToId,
    this.myReaction,
    this.theirReaction,
    this.voiceSeconds = 0,
    this.slip,
    this.receipt,
  });

  final String id;
  final ChatSender sender;
  final DateTime time;
  final MessageKind kind;
  final String text;
  final MessageStatus status;
  final String? replyToId;
  final String? myReaction;
  final String? theirReaction;
  final int voiceSeconds;
  final ExamResult? slip;
  final Purchase? receipt;

  bool get fromMe => sender == ChatSender.me;

  /// One-line summary used in reply previews.
  String preview({required bool fr}) => switch (kind) {
    MessageKind.text => text,
    MessageKind.voice => '${fr ? 'Message vocal' : 'Voice message'} (0:${voiceSeconds.toString().padLeft(2, '0')})',
    MessageKind.slip => slip?.pdfFileName ?? 'PDF',
    MessageKind.receipt => '${fr ? 'Reçu' : 'Receipt'} ${receipt?.txnId ?? ''}',
  };

  ChatMessage copyWith({MessageStatus? status, String? Function()? myReaction, String? Function()? theirReaction}) =>
      ChatMessage(
        id: id,
        sender: sender,
        time: time,
        kind: kind,
        text: text,
        status: status ?? this.status,
        replyToId: replyToId,
        myReaction: myReaction != null ? myReaction() : this.myReaction,
        theirReaction: theirReaction != null ? theirReaction() : this.theirReaction,
        voiceSeconds: voiceSeconds,
        slip: slip,
        receipt: receipt,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender.name,
    'time': time.toIso8601String(),
    'kind': kind.name,
    'text': text,
    'status': status.name,
    'reply_to': replyToId,
    'my_reaction': myReaction,
    'their_reaction': theirReaction,
    'voice': voiceSeconds,
    'slip': slip?.toJson(),
    'receipt': receipt?.toJson(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    final status = MessageStatus.values.byName(j['status'] as String);
    return ChatMessage(
      id: j['id'] as String,
      sender: ChatSender.values.byName(j['sender'] as String),
      time: DateTime.parse(j['time'] as String),
      kind: MessageKind.values.byName(j['kind'] as String),
      text: j['text'] as String? ?? '',
      // A message still "sending" when the app closed never reached support.
      status: status == MessageStatus.sending ? MessageStatus.sent : status,
      replyToId: j['reply_to'] as String?,
      myReaction: j['my_reaction'] as String?,
      theirReaction: j['their_reaction'] as String?,
      voiceSeconds: j['voice'] as int? ?? 0,
      slip: j['slip'] == null ? null : ExamResult.fromJson(j['slip'] as Map<String, dynamic>),
      receipt: j['receipt'] == null ? null : Purchase.fromJson(j['receipt'] as Map<String, dynamic>),
    );
  }
}

/// Real-time events pushed by the support backend.
sealed class SupportEvent {
  const SupportEvent();
}

class AgentTyping extends SupportEvent {
  const AgentTyping(this.typing);
  final bool typing;
}

class AgentMessage extends SupportEvent {
  const AgentMessage(this.message);
  final ChatMessage message;
}

class StatusChanged extends SupportEvent {
  const StatusChanged(this.id, this.status);
  final String id;
  final MessageStatus status;
}

class AgentReacted extends SupportEvent {
  const AgentReacted(this.id, this.emoji);
  final String id;
  final String emoji;
}
