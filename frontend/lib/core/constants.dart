import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AppConstants {
  static const appVersion = '7.0';
  static const slipPriceFcfa = 1000;
  static const slipPriceLabel = '1,000 FCFA';
  static const slipPriceLabelFr = '1 000 FCFA';
  static const supportWhatsAppUrl = "https://wa.me/650982351?text=Hey%20this%20is%20support%0AWhat's%20up";
  static const supportPhone = '+237650982351';
  static const examYears = ['2026', '2025', '2024'];
}

class ExamStream {
  const ExamStream({required this.id, required this.icon, required this.infoEn, required this.infoFr});

  final String id;
  final FaIconData icon;
  final String infoEn;
  final String infoFr;

  static const all = [
    ExamStream(
      id: 'GCE O/L',
      icon: FontAwesomeIcons.bookOpen,
      infoEn: 'General Ordinary Level — end of Form 5.',
      infoFr: 'Niveau Ordinaire Général — fin de la 5e.',
    ),
    ExamStream(
      id: 'GCE A/L',
      icon: FontAwesomeIcons.graduationCap,
      infoEn: 'General Advanced Level — end of Upper Sixth.',
      infoFr: 'Niveau Avancé Général — fin Terminale.',
    ),
    ExamStream(
      id: 'TVE IL',
      icon: FontAwesomeIcons.screwdriverWrench,
      infoEn: 'Technical and Vocational Intermediate (ITC).',
      infoFr: 'Intermédiaire Technique et Professionnel (ITC).',
    ),
    ExamStream(
      id: 'TVE AL',
      icon: FontAwesomeIcons.gears,
      infoEn: 'Technical and Vocational Advanced (ATC).',
      infoFr: 'Avancé Technique et Professionnel (ATC).',
    ),
    ExamStream(
      id: 'PCE',
      icon: FontAwesomeIcons.certificate,
      infoEn: 'Professional Certificate Examination.',
      infoFr: 'Examen de Certificat Professionnel.',
    ),
  ];

  static ExamStream byId(String id) => all.firstWhere((s) => s.id == id, orElse: () => all[1]);
}
