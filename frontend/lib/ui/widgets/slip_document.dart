import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';

/// The official slip rendered as a white paper page. Always uses the fixed
/// forest palette so it looks identical in dark mode and in the exported PDF.
class SlipDocument extends StatelessWidget {
  const SlipDocument({super.key, required this.result, this.elevated = true});

  final ExamResult result;
  final bool elevated;

  static const _primary = Color(0xFF1B4D3E);
  static const _ink = Color(0xFF0F1F1A);
  static const _muted = Color(0xFF5A6B65);
  static const _faint = Color(0xFF8A9A94);
  static const _rule = Color(0xFFE4EBE8);

  @override
  Widget build(BuildContext context) {
    final r = result;
    final issued = DateFormat.yMd().format(DateTime.now());
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: elevated
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 10))]
            : null,
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: _ink, fontSize: 10.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _primary, width: 3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                    child: const Text(
                      'GCE',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GENERAL CERTIFICATE OF EDUCATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _primary,
                            letterSpacing: 0.6,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Republic of Cameroon · Ministry of Secondary Education',
                          style: TextStyle(fontSize: 9, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${r.year}\n${r.stream}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 9, color: _muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Text(
              'OFFICIAL RESULT SLIP',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4),
            ),
            const SizedBox(height: 4),
            Text(
              'Examination Session: ${r.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: _muted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _field('Candidate Name', r.name)),
                const SizedBox(width: 14),
                Expanded(child: _field('Candidate Number', r.cand)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _field('Centre Number', r.centre)),
                const SizedBox(width: 14),
                Expanded(child: _field('Examination', r.stream)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              color: _primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Subject',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Text(
                    'Grade',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < r.grades.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: i.isOdd ? const Color(0xFFFAFCFB) : Colors.white,
                  border: const Border(bottom: BorderSide(color: _rule)),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(r.grades[i].subject)),
                    SizedBox(
                      width: 36,
                      child: Text(
                        r.grades[i].grade,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w800, color: GradeColors.of(r.grades[i].grade)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Text(
              'Result: Passed in ${r.passed} subject${r.passed != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _primary),
            ),
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _rule)),
              ),
              child: Text(
                'Copy of the GCE Board result record · Issued: $issued\n'
                'Candidates should collect their original slip from their school.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8.5, color: _faint, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const pageWidth = 340.0;

  Widget _field(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 8.5, color: _faint, fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

/// Hero wrapper for slip pages. The flight renders a scaled copy of the page
/// because the in-between rects are too small to lay the page out natively.
class SlipHero extends StatelessWidget {
  const SlipHero({super.key, required this.tag, required this.result, required this.child});

  final Object tag;
  final ExamResult result;
  final Widget child;

  @override
  Widget build(BuildContext context) => Hero(
    tag: tag,
    flightShuttleBuilder: (_, _, _, _, _) => ClipRect(
      child: FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: SlipDocument.pageWidth,
          child: SlipDocument(result: result, elevated: false),
        ),
      ),
    ),
    child: child,
  );
}

/// A miniature, top-aligned render of the slip's first page.
class SlipThumbnail extends StatelessWidget {
  const SlipThumbnail({super.key, required this.result, this.width = 56, this.aspectRatio = 1.3, this.heroTag});

  final ExamResult result;
  final double? width;
  final double aspectRatio;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget page = FittedBox(
      fit: BoxFit.fitWidth,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: SlipDocument.pageWidth,
        child: SlipDocument(result: result, elevated: false),
      ),
    );
    if (heroTag != null) {
      page = SlipHero(tag: heroTag!, result: result, child: page);
    }
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 1 / aspectRatio,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDAE3DF)),
          ),
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: OverflowBox(alignment: Alignment.topCenter, maxHeight: double.infinity, child: page),
            ),
          ),
        ),
      ),
    );
  }
}
