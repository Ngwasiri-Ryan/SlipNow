import '../models/chat.dart';
import '../models/models.dart';

/// Contracts the UI depends on. The app currently ships with the mock
/// implementations in `mock_repositories.dart`; a backend-backed version only
/// needs to implement these interfaces and be wired up in `main.dart`.

abstract class AuthRepository {
  Future<AppUser> signUp({required String name, required String phone, required String password});

  Future<AppUser> logIn({required String phone, required String password});

  Future<AppUser> updateProfile({
    required AppUser current,
    required String name,
    required String phone,
    String? newPassword,
  });

  Future<void> logOut();
}

abstract class ResultsRepository {
  Future<List<ExamResult>> search(ResultQuery query);

  /// Lightweight type-ahead lookup of candidate names for the given stream
  /// and year. Should return quickly and at most a handful of entries.
  Future<List<ExamResult>> suggest({required String stream, required String year, required String name});

  /// Release status of the current session, as set by the admin dashboard.
  Future<ResultsRelease> releaseStatus();

  /// Official results PDFs uploaded by the admin, newest session first.
  Future<List<ResultsPdf>> resultPdfs();
}

/// Live chat with the support team.
abstract class SupportChatRepository {
  SupportAgent get agent;

  /// Typing indicators, agent replies, delivery/read receipts and reactions.
  Stream<SupportEvent> get events;

  /// Delivers [message] to support. [fr] tells support which language the
  /// candidate is using.
  Future<void> send(ChatMessage message, {required bool fr});

  void dispose();
}

abstract class PaymentRepository {
  /// Confirms a Mobile Money payment for [result] and returns the
  /// transaction ID.
  Future<String> confirmPayment({required ExamResult result, required PaymentMethod method, required String phone});
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
