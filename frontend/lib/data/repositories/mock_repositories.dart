import '../mock/mock_data.dart';
import '../models/models.dart';
import 'repositories.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<AppUser> signUp({required String name, required String phone, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return AppUser(name: name, phone: phone);
  }

  @override
  Future<AppUser> logIn({required String phone, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return AppUser(name: 'Njuh Berns Ntam', phone: phone);
  }

  @override
  Future<AppUser> updateProfile({
    required AppUser current,
    required String name,
    required String phone,
    String? newPassword,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return current.copyWith(name: name, phone: phone);
  }

  @override
  Future<void> logOut() async {}
}

class MockResultsRepository implements ResultsRepository {
  @override
  Future<List<ExamResult>> search(ResultQuery q) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    final name = q.name.trim().toLowerCase();
    return mockResults.where((r) {
      if (r.stream != q.stream) return false;
      if (r.year != q.year) return false;
      if (name.isNotEmpty && !r.name.toLowerCase().contains(name)) return false;
      if (q.cand.isNotEmpty && r.cand != q.cand) return false;
      if (q.centre.isNotEmpty && r.centre != q.centre) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<ExamResult>> suggest({required String stream, required String year, required String name}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final q = name.trim().toLowerCase();
    if (q.length < 2) return const [];
    return mockResults
        .where((r) => r.stream == stream && r.year == year && r.name.toLowerCase().contains(q))
        .take(5)
        .toList();
  }

  @override
  Future<ResultsRelease> releaseStatus() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return mockRelease;
  }

  @override
  Future<List<ResultsPdf>> resultPdfs() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return mockResultPdfs;
  }
}

class MockPaymentRepository implements PaymentRepository {
  @override
  Future<String> confirmPayment({
    required ExamResult result,
    required PaymentMethod method,
    required String phone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 2200));
    final stamp = DateTime.now().millisecondsSinceEpoch.toString();
    return method.txnPrefix + stamp.substring(stamp.length - 8);
  }
}
