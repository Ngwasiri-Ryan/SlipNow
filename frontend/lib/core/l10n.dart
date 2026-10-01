import 'package:flutter/widgets.dart';

enum AppLanguage {
  en('EN', 'English'),
  fr('FR', 'Français');

  const AppLanguage(this.code, this.displayName);
  final String code;
  final String displayName;
}

/// Exposes the current language to the widget tree so any widget calling
/// [LangContext.tr] rebuilds when the language changes.
class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.language, required super.child});

  final AppLanguage language;

  static AppLanguage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.language ?? AppLanguage.en;

  @override
  bool updateShouldNotify(LangScope oldWidget) => oldWidget.language != language;
}

extension LangContext on BuildContext {
  bool get isFr => LangScope.of(this) == AppLanguage.fr;

  String tr(String en, String fr) => isFr ? fr : en;

  static const _shortEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _shortFr = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  static const _longEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _longFr = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  /// e.g. "14 Jul 2026" / "14 juil. 2026".
  String shortDate(DateTime d) => '${d.day} ${(isFr ? _shortFr : _shortEn)[d.month - 1]} ${d.year}';

  /// e.g. "July 2026" / "juillet 2026".
  String monthYear(DateTime d) => '${(isFr ? _longFr : _longEn)[d.month - 1]} ${d.year}';

  /// 24-hour clock, e.g. "17:42".
  String clock(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
