import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models/models.dart';

/// Builds the official slip and payment receipt PDFs on-device.
///
/// Text is kept to Latin-1 because the built-in Helvetica font cannot render
/// characters such as em dashes.
class PdfService {
  static const _primary = PdfColor.fromInt(0xFF1B4D3E);
  static const _ink = PdfColor.fromInt(0xFF0F1F1A);
  static const _muted = PdfColor.fromInt(0xFF787878);

  static String _passed(ExamResult r) => 'Passed in ${r.passed} subject${r.passed != 1 ? 's' : ''}';

  static String _date(DateTime d) => DateFormat.yMd().format(d);

  static Future<Uint8List> buildSlip(ExamResult r) {
    final doc = pw.Document(title: 'GCE Slip - ${r.name}', author: 'SlipNow');
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 50, 40, 40),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              'GENERAL CERTIFICATE OF EDUCATION',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _ink),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Republic of Cameroon · Ministry of Secondary Education',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 14),
            pw.Divider(color: _primary, thickness: 1.5),
            pw.SizedBox(height: 14),
            pw.Text(
              'OFFICIAL RESULT SLIP',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 22),
            _pair('Name: ${r.name}', 'Candidate No: ${r.cand}'),
            _pair('Centre No: ${r.centre}', 'Exam: ${r.stream}'),
            _pair('Year: ${r.year}', 'Result: ${_passed(r)}'),
            pw.SizedBox(height: 18),
            pw.Container(
              color: _primary,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'SUBJECT',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                    ),
                  ),
                  pw.Text(
                    'GRADE',
                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < r.grades.length; i++)
              pw.Container(
                color: i.isEven ? const PdfColor.fromInt(0xFFFAFCFB) : PdfColors.white,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: pw.Row(
                  children: [
                    pw.Expanded(child: pw.Text(r.grades[i].subject, style: const pw.TextStyle(fontSize: 11))),
                    pw.Text(r.grades[i].grade, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            pw.SizedBox(height: 30),
            pw.Divider(color: const PdfColor.fromInt(0xFFE4EBE8)),
            pw.SizedBox(height: 8),
            pw.Text(
              'Copy of the GCE Board result record · Issued: ${_date(DateTime.now())}',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Candidates should collect their original slip from their school.',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  static pw.Widget _pair(String left, String right) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8, left: 20),
    child: pw.Row(
      children: [
        pw.Expanded(child: pw.Text(left, style: const pw.TextStyle(fontSize: 11))),
        pw.Expanded(child: pw.Text(right, style: const pw.TextStyle(fontSize: 11))),
      ],
    ),
  );

  static Future<Uint8List> buildReceipt(Purchase p) {
    final r = p.result;
    final doc = pw.Document(title: 'SlipNow Receipt - ${r.cand}', author: 'SlipNow');
    pw.Widget line(String t) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(t, style: const pw.TextStyle(fontSize: 10)),
    );
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(36),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(
                'SLIPNOW - PAYMENT RECEIPT',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: _primary),
            pw.SizedBox(height: 12),
            line('Candidate: ${r.name}'),
            line('Exam: ${r.stream} · Year: ${r.year}'),
            line('Candidate No: ${r.cand}'),
            line('Centre No: ${r.centre}'),
            pw.SizedBox(height: 10),
            pw.Text('Payment details', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            line('Transaction ID: ${p.txnId}'),
            line('Method: ${p.method.label}'),
            line('Amount: 1,000 FCFA'),
            line('Date: ${_date(p.date)}'),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(
                'This receipt confirms payment for unlocking an official GCE result slip.',
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ),
          ],
        ),
      ),
    );
    return doc.save();
  }

  /// Opens the platform share/save sheet (downloads the file on web).
  static Future<void> saveSlip(ExamResult r) async {
    await Printing.sharePdf(bytes: await buildSlip(r), filename: r.pdfFileName);
  }

  /// Shares the PDF file itself (e.g. straight into a WhatsApp chat).
  static Future<void> shareSlip(ExamResult r) async {
    final bytes = await buildSlip(r);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: r.pdfFileName)],
        fileNameOverrides: [r.pdfFileName],
        subject: 'GCE Result Slip · ${r.name}',
      ),
    );
  }

  static Future<void> printSlip(ExamResult r) async {
    await Printing.layoutPdf(name: r.pdfFileName, onLayout: (_) => buildSlip(r));
  }

  static String receiptFileName(Purchase p) => 'SlipNow_Receipt_${p.txnId}.pdf';

  static Future<void> saveReceipt(Purchase p) async {
    await Printing.sharePdf(bytes: await buildReceipt(p), filename: receiptFileName(p));
  }

  static Future<void> shareReceipt(Purchase p) async {
    final bytes = await buildReceipt(p);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: receiptFileName(p))],
        fileNameOverrides: [receiptFileName(p)],
        subject: 'SlipNow receipt · ${p.txnId}',
      ),
    );
  }
}
