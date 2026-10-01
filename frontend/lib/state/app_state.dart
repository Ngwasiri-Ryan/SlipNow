import 'package:flutter/foundation.dart';

import '../core/l10n.dart';
import '../core/theme/app_colors.dart';
import '../data/local/local_store.dart';
import '../data/mock/mock_data.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';
import 'chat_controller.dart';

enum AppTab { home, search, history, profile }

class AppState extends ChangeNotifier {
  AppState({
    required this.store,
    required this.auth,
    required this.results,
    required this.payments,
    required SupportChatRepository support,
  }) : chat = ChatController(repo: support, store: store);

  final LocalStore store;
  final AuthRepository auth;
  final ResultsRepository results;
  final PaymentRepository payments;
  final ChatController chat;

  ResultsRelease? _release;
  List<ResultsPdf>? _resultPdfs;
  bool _releaseAlerts = false;

  AppUser? _user;
  List<Purchase> _purchases = [];
  List<SavedCandidate> _savedCandidates = [];
  List<AppNotification> _notifications = [];
  AppLanguage _language = AppLanguage.en;
  bool _darkMode = false;
  BrandTheme _brand = BrandTheme.forest;
  bool _onboardingSeen = false;
  AppTab _tab = AppTab.home;
  String _selectedStream = 'GCE A/L';

  AppUser? get user => _user;
  List<Purchase> get purchases => List.unmodifiable(_purchases);
  List<SavedCandidate> get savedCandidates => List.unmodifiable(_savedCandidates);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  AppLanguage get language => _language;
  bool get darkMode => _darkMode;
  BrandTheme get brand => _brand;
  bool get onboardingSeen => _onboardingSeen;
  AppTab get tab => _tab;
  String get selectedStream => _selectedStream;
  int get unreadCount => _notifications.where((n) => n.unread).length;

  /// Null until the first release-status fetch completes.
  ResultsRelease? get release => _release;

  /// Null until the first fetch of the admin-uploaded results PDFs completes.
  List<ResultsPdf>? get resultPdfs => _resultPdfs;
  bool get releaseAlerts => _releaseAlerts;

  void load() {
    _loadSnapshot();
    refreshRelease();
    refreshResultPdfs();
  }

  void _loadSnapshot() {
    final data = store.read();
    if (data == null) {
      _savedCandidates = List.of(defaultSavedCandidates);
      _notifications = List.of(defaultNotifications);
      final locale = PlatformDispatcher.instance.locale;
      if (locale.languageCode.toLowerCase() == 'fr') _language = AppLanguage.fr;
      return;
    }
    final userJson = data['user'] as Map<String, dynamic>?;
    _user = userJson == null ? null : AppUser.fromJson(userJson);
    _purchases = _list(data['purchased'], Purchase.fromJson);
    _savedCandidates = _list(data['savedCandidates'], SavedCandidate.fromJson);
    _notifications = _list(data['notifications'], AppNotification.fromJson);
    if (_notifications.isEmpty) _notifications = List.of(defaultNotifications);
    _language = AppLanguage.values.firstWhere((l) => l.code == data['language'], orElse: () => AppLanguage.en);
    _darkMode = data['darkMode'] as bool? ?? false;
    final themeIndex = (data['theme'] as int? ?? 1) - 1;
    _brand = BrandTheme.values[themeIndex.clamp(0, BrandTheme.values.length - 1)];
    _onboardingSeen = data['onbSeen'] as bool? ?? false;
    _releaseAlerts = data['releaseAlerts'] as bool? ?? false;
  }

  static List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) f) {
    if (raw is! List) return [];
    try {
      return raw.map((e) => f(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _save() => store.write({
    'user': _user?.toJson(),
    'purchased': _purchases.map((p) => p.toJson()).toList(),
    'savedCandidates': _savedCandidates.map((c) => c.toJson()).toList(),
    'notifications': _notifications.map((n) => n.toJson()).toList(),
    'language': _language.code,
    'darkMode': _darkMode,
    'theme': _brand.index + 1,
    'onbSeen': _onboardingSeen,
    'releaseAlerts': _releaseAlerts,
  });

  void _commit() {
    notifyListeners();
    _save();
  }

  // Preferences

  void completeOnboarding() {
    _onboardingSeen = true;
    _commit();
  }

  void toggleLanguage() {
    _language = _language == AppLanguage.en ? AppLanguage.fr : AppLanguage.en;
    _commit();
  }

  void toggleDarkMode() {
    _darkMode = !_darkMode;
    _commit();
  }

  void setBrand(BrandTheme brand) {
    _brand = brand;
    _commit();
  }

  void setTab(AppTab tab) {
    if (_tab == tab) return;
    _tab = tab;
    notifyListeners();
  }

  void selectStream(String id) {
    _selectedStream = id;
    notifyListeners();
  }

  Future<void> resetDemo() async {
    await store.clear();
    _user = null;
    _purchases = [];
    _savedCandidates = List.of(defaultSavedCandidates);
    _notifications = List.of(defaultNotifications);
    _language = AppLanguage.en;
    _darkMode = false;
    _brand = BrandTheme.forest;
    _onboardingSeen = false;
    _releaseAlerts = false;
    _tab = AppTab.home;
    chat.clear();
    notifyListeners();
  }

  // Results release

  Future<void> refreshRelease() async {
    try {
      _release = await results.releaseStatus();
      notifyListeners();
    } catch (_) {
      // Keep the last known status; the home card falls back gracefully.
    }
  }

  Future<void> refreshResultPdfs() async {
    try {
      _resultPdfs = await results.resultPdfs();
      notifyListeners();
    } catch (_) {
      _resultPdfs ??= const [];
      notifyListeners();
    }
  }

  void toggleReleaseAlerts() {
    _releaseAlerts = !_releaseAlerts;
    _commit();
  }

  /// Lets debug builds preview both release states without a backend.
  void debugOverrideRelease(ResultsRelease release) {
    _release = release;
    notifyListeners();
  }

  // Auth

  Future<void> signUp(String name, String phone, String password) async {
    _user = await auth.signUp(name: name, phone: phone, password: password);
    _tab = AppTab.home;
    _commit();
  }

  Future<void> logIn(String phone, String password) async {
    _user = await auth.logIn(phone: phone, password: password);
    _tab = AppTab.home;
    _commit();
  }

  Future<void> logOut() async {
    await auth.logOut();
    _user = null;
    _purchases = [];
    chat.clear();
    _commit();
  }

  Future<void> updateProfile(String name, String phone, String? password) async {
    final current = _user ?? AppUser(name: name, phone: phone);
    _user = await auth.updateProfile(current: current, name: name, phone: phone, newPassword: password);
    _commit();
  }

  // Candidates & notifications

  void addSavedCandidate(SavedCandidate c) {
    _savedCandidates = [..._savedCandidates, c];
    _commit();
  }

  void removeSavedCandidate(int index) {
    _savedCandidates = [..._savedCandidates]..removeAt(index);
    _commit();
  }

  void markNotificationRead(int index) {
    _notifications = [
      for (var i = 0; i < _notifications.length; i++) i == index ? _notifications[i].markRead() : _notifications[i],
    ];
    _commit();
  }

  void markAllNotificationsRead() {
    if (unreadCount == 0) return;
    _notifications = _notifications.map((n) => n.markRead()).toList();
    _commit();
  }

  // Results & payments

  bool isUnlocked(ExamResult r) => _purchases.any((p) => p.result.sameSlip(r));

  Future<String> pay(ExamResult r, PaymentMethod method, String phone) =>
      payments.confirmPayment(result: r, method: method, phone: phone);

  void recordPurchase(ExamResult r, PaymentMethod method, String txnId) {
    if (isUnlocked(r)) return;
    _purchases = [..._purchases, Purchase(result: r, txnId: txnId, method: method, date: DateTime.now())];
    _commit();
  }
}
