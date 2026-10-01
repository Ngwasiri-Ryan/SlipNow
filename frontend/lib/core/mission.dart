import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// SlipNow's purpose, shared by the Terms, Help centre and support chat so the
/// wording stays identical everywhere. Each entry is (English, French).
class MissionCopy {
  static const headline = ('Why SlipNow exists', 'Pourquoi SlipNow existe');

  static const summary = (
    'SlipNow helps GCE candidates see their grades as soon as results are released. '
        'It eases results anxiety, removes the difficulty of getting hold of a slip, and meets the '
        'urgent need for one for public exams, pending scholarships and school admissions, at home '
        'and abroad, for a small fee.',
    'SlipNow aide les candidats du GCE à voir leurs notes dès la publication des résultats. '
        'Il apaise l’anxiété des résultats, lève la difficulté d’obtenir un relevé et répond au '
        'besoin urgent d’en avoir un pour les examens publics, les bourses en attente et les '
        'admissions scolaires, au pays comme à l’étranger, moyennant des frais modestes.',
  );

  static const original = (
    'SlipNow does not replace your original result slip. Candidates are still urged to go to their '
        'schools to collect their original copies.',
    'SlipNow ne remplace pas votre relevé original. Les candidats sont toujours invités à se rendre '
        'dans leur établissement pour retirer leur exemplaire original.',
  );

  static const pillars = [
    (
      FontAwesomeIcons.heartPulse,
      ('Less results anxiety', 'Moins d’anxiété'),
      ('See your grades the moment results are released.', 'Voyez vos notes dès la publication des résultats.'),
    ),
    (
      FontAwesomeIcons.mobileScreenButton,
      ('Easy access to your slip', 'Accès facile au relevé'),
      (
        'No trips or queues: your slip is on your phone.',
        'Sans déplacement ni file : votre relevé sur votre téléphone.',
      ),
    ),
    (
      FontAwesomeIcons.bolt,
      ('Ready when it is urgent', 'Prêt en cas d’urgence'),
      (
        'Public exams, pending scholarships and admissions at home and abroad.',
        'Examens publics, bourses en attente et admissions au pays et à l’étranger.',
      ),
    ),
  ];
}
