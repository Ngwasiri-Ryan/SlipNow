import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../data/models/models.dart';

class ExternalActions {
  static String resultSummary(ExamResult r) =>
      '${r.name} — ${r.stream} ${r.year}\n'
      'Centre ${r.centre} · Candidate ${r.cand}';

  static Future<bool> openSupportWhatsApp() => _open(AppConstants.supportWhatsAppUrl);

  static Future<bool> shareResultOnWhatsApp(ExamResult r) =>
      _open('https://wa.me/?text=${Uri.encodeComponent('${resultSummary(r)}\n\nSlipNow')}');

  static Future<void> shareResult(ExamResult r) async {
    await SharePlus.instance.share(ShareParams(text: resultSummary(r), subject: 'GCE Slip · ${r.name}'));
  }

  /// Opens the phone dialer pre-filled with a USSD code such as `*126#`.
  static Future<bool> dial(String code) async {
    try {
      return await launchUrl(Uri(scheme: 'tel', path: code));
    } catch (_) {
      return false;
    }
  }

  static Future<void> shareResultsPdf(ResultsPdf pdf) async {
    final data = await rootBundle.load(pdf.source);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(data.buffer.asUint8List(), mimeType: 'application/pdf', name: pdf.fileName)],
        fileNameOverrides: [pdf.fileName],
        subject: '${pdf.session} ${pdf.titleEn} results',
      ),
    );
  }

  static Future<bool> callSupport() => dial(AppConstants.supportPhone);

  static Future<void> copy(String text) => Clipboard.setData(ClipboardData(text: text));

  static Future<bool> _open(String url) async {
    try {
      return await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
