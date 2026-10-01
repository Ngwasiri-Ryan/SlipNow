import '../models/models.dart';

List<SubjectGrade> _g(List<List<String>> rows) => rows.map((r) => SubjectGrade(subject: r[0], grade: r[1])).toList();

final mockResults = <ExamResult>[
  ExamResult(
    stream: 'GCE A/L',
    name: 'Njuh Berns Ntam',
    year: '2026',
    centre: '11045',
    cand: '05210417',
    passed: 5,
    grades: _g([
      ['Mathematics', 'A'],
      ['Physics', 'B'],
      ['Chemistry', 'B'],
      ['Biology', 'C'],
      ['English', 'A'],
    ]),
  ),
  ExamResult(
    stream: 'GCE A/L',
    name: 'Emmanuel Comfort',
    year: '2026',
    centre: '11045',
    cand: '05210418',
    passed: 4,
    grades: _g([
      ['Mathematics', 'C'],
      ['Physics', 'D'],
      ['Chemistry', 'B'],
      ['Biology', 'C'],
      ['English', 'B'],
    ]),
  ),
  ExamResult(
    stream: 'GCE O/L',
    name: 'Ngwa Alain Tabi',
    year: '2026',
    centre: '11050',
    cand: '06220104',
    passed: 6,
    grades: _g([
      ['Mathematics', 'B'],
      ['English', 'A'],
      ['Biology', 'B'],
      ['Chemistry', 'C'],
      ['Physics', 'C'],
      ['History', 'B'],
      ['Geography', 'C'],
    ]),
  ),
  ExamResult(
    stream: 'TVE IL',
    name: 'Tanyi Godlove Ngwa',
    year: '2026',
    centre: '12010',
    cand: '07230011',
    passed: 5,
    grades: _g([
      ['Technical Drawing', 'B'],
      ['Electrical Power Systems', 'A'],
      ['Mathematics', 'C'],
      ['Physics', 'C'],
      ['English', 'B'],
      ['Workshop Practice', 'A'],
    ]),
  ),
  ExamResult(
    stream: 'TVE AL',
    name: 'Mbah Claudette Nfor',
    year: '2026',
    centre: '12020',
    cand: '08240022',
    passed: 4,
    grades: _g([
      ['Electrical Power Systems', 'B'],
      ['Electronics', 'A'],
      ['Applied Mathematics', 'C'],
      ['Technical Drawing', 'B'],
      ['English', 'C'],
    ]),
  ),
  ExamResult(
    stream: 'TVE AL',
    name: 'Ekema Samuel Ndive',
    year: '2026',
    centre: '12020',
    cand: '08240023',
    passed: 5,
    grades: _g([
      ['Automobile Mechanics', 'A'],
      ['Applied Mathematics', 'B'],
      ['Technical Drawing', 'B'],
      ['Workshop Practice', 'A'],
      ['English', 'C'],
    ]),
  ),
  ExamResult(
    stream: 'PCE',
    name: 'Nkeng Blaise Fon',
    year: '2026',
    centre: '13005',
    cand: '09250033',
    passed: 3,
    grades: _g([
      ['Professional Practice', 'A'],
      ['Business Management', 'B'],
      ['Accounting Principles', 'B'],
      ['Communication Skills', 'C'],
    ]),
  ),
];

/// Flip `released` to preview the "results not out yet" state.
final mockRelease = ResultsRelease(
  session: '2026',
  released: true,
  releasedOn: DateTime(2026, 7, 14),
  expectedEn: 'late July 2026',
  expectedFr: 'fin juillet 2026',
  streams: const ['GCE O/L', 'GCE A/L', 'TVE IL', 'TVE AL', 'PCE'],
);

/// Stands in for the PDFs the admin uploads from the dashboard.
final mockResultPdfs = [
  ResultsPdf(
    id: 'gce-ol-2026',
    stream: 'GCE O/L',
    session: '2026',
    titleEn: 'GCE Ordinary Level',
    titleFr: 'GCE Niveau Ordinaire',
    source: 'assets/results/2026-GCE-OL-Results.pdf',
    pages: 420,
    sizeBytes: 1880425,
    publishedOn: DateTime(2026, 7, 14),
  ),
  ResultsPdf(
    id: 'gce-al-2026',
    stream: 'GCE A/L',
    session: '2026',
    titleEn: 'GCE Advanced Level',
    titleFr: 'GCE Niveau Avancé',
    source: 'assets/results/2026-GCE-AL-Results.pdf',
    pages: 270,
    sizeBytes: 1271501,
    publishedOn: DateTime(2026, 7, 14),
  ),
  ResultsPdf(
    id: 'tvee-il-2026',
    stream: 'TVE IL',
    session: '2026',
    titleEn: 'TVEE Intermediate Level',
    titleFr: 'TVEE Niveau Intermédiaire',
    source: 'assets/results/2026-TVEE-IL-Results.pdf',
    pages: 188,
    sizeBytes: 667637,
    publishedOn: DateTime(2026, 7, 14),
  ),
  ResultsPdf(
    id: 'tvee-al-2026',
    stream: 'TVE AL',
    session: '2026',
    titleEn: 'TVEE Advanced Level',
    titleFr: 'TVEE Niveau Avancé',
    source: 'assets/results/2026-TVEE-AL-Results.pdf',
    pages: 100,
    sizeBytes: 401162,
    publishedOn: DateTime(2026, 7, 14),
  ),
];

const defaultSavedCandidates = [SavedCandidate(name: 'Njuh Berns Ntam', cand: '05210417', centre: '11045')];

const defaultNotifications = [
  AppNotification(
    kind: NotificationKind.accent,
    title: '2026 GCE results are out',
    titleFr: 'Les résultats du GCE 2026 sont disponibles',
    text: 'Search your name to see your grades.',
    textFr: 'Recherchez votre nom pour voir vos notes.',
    time: '2 hours ago',
    timeFr: 'il y a 2 heures',
  ),
  AppNotification(
    kind: NotificationKind.success,
    title: 'Welcome to SlipNow',
    titleFr: 'Bienvenue sur SlipNow',
    text: 'Your account is ready.',
    textFr: 'Votre compte est prêt.',
    time: '1 day ago',
    timeFr: 'il y a 1 jour',
  ),
];
