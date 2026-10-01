class AppUser {
  const AppUser({required this.name, required this.phone});

  final String name;
  final String phone;

  String get firstName => name.trim().split(RegExp(r'\s+')).first;
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  AppUser copyWith({String? name, String? phone}) => AppUser(name: name ?? this.name, phone: phone ?? this.phone);

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(name: j['name'] as String, phone: j['phone'] as String);
}

class SubjectGrade {
  const SubjectGrade({required this.subject, required this.grade});

  final String subject;
  final String grade;

  Map<String, dynamic> toJson() => {'subj': subject, 'grade': grade};

  factory SubjectGrade.fromJson(Map<String, dynamic> j) =>
      SubjectGrade(subject: j['subj'] as String, grade: j['grade'] as String);
}

class ExamResult {
  const ExamResult({
    required this.stream,
    required this.name,
    required this.year,
    required this.centre,
    required this.cand,
    required this.passed,
    required this.grades,
  });

  final String stream;
  final String name;
  final String year;
  final String centre;
  final String cand;
  final int passed;
  final List<SubjectGrade> grades;

  String get slipId => 'GCE-$cand-$year';
  String get pdfFileName => '${stream.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_${year}_$cand.pdf';

  bool sameSlip(ExamResult other) => other.cand == cand && other.year == year;

  Map<String, dynamic> toJson() => {
    'stream': stream,
    'name': name,
    'year': year,
    'centre': centre,
    'cand': cand,
    'passed': passed,
    'grades': grades.map((g) => g.toJson()).toList(),
  };

  factory ExamResult.fromJson(Map<String, dynamic> j) => ExamResult(
    stream: j['stream'] as String,
    name: j['name'] as String,
    year: j['year'] as String,
    centre: j['centre'] as String,
    cand: j['cand'] as String,
    passed: j['passed'] as int,
    grades: (j['grades'] as List).map((g) => SubjectGrade.fromJson(g as Map<String, dynamic>)).toList(),
  );
}

enum PaymentMethod {
  momo('MTN MoMo', '*126#', 'MOMO-'),
  orange('Orange Money', '#150*1#', 'OM-');

  const PaymentMethod(this.label, this.ussd, this.txnPrefix);
  final String label;
  final String ussd;
  final String txnPrefix;

  /// Guesses the operator from a Cameroonian mobile number, e.g. 67x/650-654
  /// for MTN and 69x/655-659 for Orange. Returns null while undetermined.
  static PaymentMethod? fromPhone(String phone) {
    var d = phone.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('237')) d = d.substring(3);
    if (d.length < 2) return null;
    if (d.startsWith('67')) return momo;
    if (d.startsWith('69')) return orange;
    if (d.length < 3) return null;
    final p = int.parse(d.substring(0, 3));
    if (p >= 650 && p <= 654) return momo;
    if (p >= 655 && p <= 659) return orange;
    if (p >= 680 && p <= 684) return momo;
    if (p >= 685 && p <= 689) return orange;
    return null;
  }
}

class Purchase {
  const Purchase({required this.result, required this.txnId, required this.method, required this.date});

  final ExamResult result;
  final String txnId;
  final PaymentMethod method;
  final DateTime date;

  Map<String, dynamic> toJson() => {
    'result': result.toJson(),
    'txnId': txnId,
    'method': method.name,
    'date': date.toIso8601String(),
  };

  factory Purchase.fromJson(Map<String, dynamic> j) => Purchase(
    result: ExamResult.fromJson(j['result'] as Map<String, dynamic>),
    txnId: j['txnId'] as String,
    method: PaymentMethod.values.byName(j['method'] as String),
    date: DateTime.parse(j['date'] as String),
  );
}

class SavedCandidate {
  const SavedCandidate({required this.name, required this.cand, required this.centre});

  final String name;
  final String cand;
  final String centre;

  Map<String, dynamic> toJson() => {'name': name, 'cand': cand, 'centre': centre};

  factory SavedCandidate.fromJson(Map<String, dynamic> j) =>
      SavedCandidate(name: j['name'] as String, cand: j['cand'] as String, centre: j['centre'] as String);
}

enum NotificationKind { accent, success, info }

class AppNotification {
  const AppNotification({
    required this.kind,
    required this.title,
    required this.titleFr,
    required this.text,
    required this.textFr,
    required this.time,
    required this.timeFr,
    this.unread = true,
  });

  final NotificationKind kind;
  final String title;
  final String titleFr;
  final String text;
  final String textFr;
  final String time;
  final String timeFr;
  final bool unread;

  AppNotification markRead() => AppNotification(
    kind: kind,
    title: title,
    titleFr: titleFr,
    text: text,
    textFr: textFr,
    time: time,
    timeFr: timeFr,
    unread: false,
  );

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'title': title,
    'title_fr': titleFr,
    'text': text,
    'text_fr': textFr,
    'time': time,
    'time_fr': timeFr,
    'unread': unread,
  };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    kind: NotificationKind.values.byName(j['kind'] as String),
    title: j['title'] as String,
    titleFr: j['title_fr'] as String,
    text: j['text'] as String,
    textFr: j['text_fr'] as String,
    time: j['time'] as String,
    timeFr: j['time_fr'] as String,
    unread: j['unread'] as bool? ?? false,
  );
}

/// Whether the GCE Board has published a session's results. Set by the admin
/// from the dashboard; the app only reads it.
class ResultsRelease {
  const ResultsRelease({
    required this.session,
    required this.released,
    this.releasedOn,
    this.expectedEn,
    this.expectedFr,
    this.streams = const [],
  });

  final String session;
  final bool released;
  final DateTime? releasedOn;

  /// Free-text estimate shown while results are pending, e.g. "late July 2026".
  final String? expectedEn;
  final String? expectedFr;

  /// Exam streams whose results are available.
  final List<String> streams;

  ResultsRelease copyWith({bool? released, DateTime? releasedOn}) => ResultsRelease(
    session: session,
    released: released ?? this.released,
    releasedOn: releasedOn ?? this.releasedOn,
    expectedEn: expectedEn,
    expectedFr: expectedFr,
    streams: streams,
  );

  factory ResultsRelease.fromJson(Map<String, dynamic> j) => ResultsRelease(
    session: j['session'] as String,
    released: j['released'] as bool,
    releasedOn: j['released_on'] == null ? null : DateTime.parse(j['released_on'] as String),
    expectedEn: j['expected_en'] as String?,
    expectedFr: j['expected_fr'] as String?,
    streams: (j['streams'] as List?)?.cast<String>() ?? const [],
  );
}

/// An official results PDF for one exam, uploaded by the admin from the
/// dashboard. Free for students to open and search in the app.
class ResultsPdf {
  const ResultsPdf({
    required this.id,
    required this.stream,
    required this.session,
    required this.titleEn,
    required this.titleFr,
    required this.source,
    required this.pages,
    required this.sizeBytes,
    required this.publishedOn,
  });

  final String id;

  /// Exam stream id, e.g. `GCE O/L`.
  final String stream;
  final String session;
  final String titleEn;
  final String titleFr;

  /// Bundled asset path for the demo, or an https URL served by the backend.
  final String source;
  final int pages;
  final int sizeBytes;
  final DateTime publishedOn;

  bool get isNetwork => source.startsWith('http');
  String get fileName => source.split('/').last;

  factory ResultsPdf.fromJson(Map<String, dynamic> j) => ResultsPdf(
    id: j['id'] as String,
    stream: j['stream'] as String,
    session: j['session'] as String,
    titleEn: j['title_en'] as String,
    titleFr: j['title_fr'] as String,
    source: j['url'] as String,
    pages: j['pages'] as int,
    sizeBytes: j['size_bytes'] as int,
    publishedOn: DateTime.parse(j['published_on'] as String),
  );
}

class ResultQuery {
  const ResultQuery({required this.stream, required this.year, this.name = '', this.cand = '', this.centre = ''});

  final String stream;
  final String year;
  final String name;
  final String cand;
  final String centre;
}
