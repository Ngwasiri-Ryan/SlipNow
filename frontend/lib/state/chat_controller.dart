import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/local/local_store.dart';
import '../data/models/chat.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

/// Holds the support conversation, applies real-time events from
/// [SupportChatRepository] and persists the history on-device.
class ChatController extends ChangeNotifier {
  ChatController({required this.repo, required this.store}) {
    _messages = [for (final raw in store.readChat()) ?_tryParse(raw)];
    _sub = repo.events.listen(_onEvent);
  }

  final SupportChatRepository repo;
  final LocalStore store;

  late List<ChatMessage> _messages;
  late final StreamSubscription<SupportEvent> _sub;
  bool _agentTyping = false;
  bool _open = false;
  int _unread = 0;

  SupportAgent get agent => repo.agent;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get agentTyping => _agentTyping;
  int get unread => _unread;
  bool get hasUserMessages => _messages.any((m) => m.fromMe);

  ChatMessage? byId(String? id) {
    if (id == null) return null;
    for (final m in _messages) {
      if (m.id == id) return m;
    }
    return null;
  }

  static ChatMessage? _tryParse(Object? raw) {
    try {
      return ChatMessage.fromJson(raw! as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static String _newId() => 'm${DateTime.now().microsecondsSinceEpoch}';

  /// Call when the chat screen opens/closes so unread counts stay accurate.
  void setOpen(bool open, {bool fr = false, String? firstName}) {
    _open = open;
    if (open) {
      _unread = 0;
      if (_messages.isEmpty) _welcome(fr, firstName);
    }
    notifyListeners();
  }

  /// Like `setOpen(false)` but without notifying, so it is safe to call from
  /// a widget's `dispose`.
  void markClosed() => _open = false;

  void _welcome(bool fr, String? firstName) {
    final who = firstName == null ? '' : ' $firstName';
    _messages = [
      ChatMessage(
        id: _newId(),
        sender: ChatSender.agent,
        time: DateTime.now(),
        status: MessageStatus.read,
        text: fr
            ? 'Bonjour$who ! Je suis ${agent.name} du support SlipNow. Posez-moi vos questions sur la recherche de résultats, les paiements ou votre relevé.'
            : 'Hi$who! I am ${agent.name} from SlipNow Support. Ask me anything about finding your results, payments or your slip.',
      ),
    ];
    _save();
  }

  Future<void> sendText(String text, {String? replyToId, required bool fr}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();
    return _send(
      ChatMessage(id: _newId(), sender: ChatSender.me, time: DateTime.now(), text: trimmed, replyToId: replyToId),
      fr,
    );
  }

  Future<void> sendVoice(int seconds, {String? replyToId, required bool fr}) => _send(
    ChatMessage(
      id: _newId(),
      sender: ChatSender.me,
      time: DateTime.now(),
      kind: MessageKind.voice,
      voiceSeconds: seconds,
      replyToId: replyToId,
    ),
    fr,
  );

  Future<void> sendSlip(ExamResult slip, {required bool fr}) => _send(
    ChatMessage(id: _newId(), sender: ChatSender.me, time: DateTime.now(), kind: MessageKind.slip, slip: slip),
    fr,
  );

  Future<void> sendReceipt(Purchase receipt, {required bool fr}) => _send(
    ChatMessage(id: _newId(), sender: ChatSender.me, time: DateTime.now(), kind: MessageKind.receipt, receipt: receipt),
    fr,
  );

  Future<void> _send(ChatMessage m, bool fr) async {
    _messages = [..._messages, m];
    _commit();
    try {
      await repo.send(m, fr: fr);
      _update(m.id, (old) => old.status == MessageStatus.sending ? old.copyWith(status: MessageStatus.sent) : old);
    } catch (_) {
      // Stays in "sending"; a real backend would retry on reconnect.
    }
  }

  void react(String id, String emoji) =>
      _update(id, (m) => m.copyWith(myReaction: () => m.myReaction == emoji ? null : emoji));

  void delete(String id) {
    _messages = _messages.where((m) => m.id != id).toList();
    _commit();
  }

  void clear() {
    _messages = [];
    _agentTyping = false;
    _unread = 0;
    _commit();
  }

  void _onEvent(SupportEvent e) {
    switch (e) {
      case AgentTyping(:final typing):
        _agentTyping = typing;
        notifyListeners();
      case AgentMessage(:final message):
        _messages = [..._messages, message];
        if (!_open) _unread++;
        _commit();
      case StatusChanged(:final id, :final status):
        _update(id, (m) => status.index > m.status.index ? m.copyWith(status: status) : m);
      case AgentReacted(:final id, :final emoji):
        _update(id, (m) => m.copyWith(theirReaction: () => emoji));
    }
  }

  void _update(String id, ChatMessage Function(ChatMessage) f) {
    final i = _messages.indexWhere((m) => m.id == id);
    if (i < 0) return;
    final next = f(_messages[i]);
    if (identical(next, _messages[i])) return;
    _messages = [..._messages]..[i] = next;
    _commit();
  }

  void _commit() {
    notifyListeners();
    _save();
  }

  void _save() => store.writeChat(_messages.map((m) => m.toJson()).toList());

  @override
  void dispose() {
    _sub.cancel();
    repo.dispose();
    super.dispose();
  }
}
