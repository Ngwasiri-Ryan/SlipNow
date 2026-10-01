import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/common.dart';
import '../widgets/feedback.dart';

class SavedCandidatesScreen extends StatefulWidget {
  const SavedCandidatesScreen({super.key});

  @override
  State<SavedCandidatesScreen> createState() => _SavedCandidatesScreenState();
}

class _SavedCandidatesScreenState extends State<SavedCandidatesScreen> {
  final _name = TextEditingController();
  final _cand = TextEditingController();
  final _centre = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _cand.dispose();
    _centre.dispose();
    super.dispose();
  }

  void _add() {
    final name = _name.text.trim();
    final cand = _cand.text.trim();
    final centre = _centre.text.trim();
    if (name.isEmpty || cand.isEmpty || centre.isEmpty) {
      Toast.show(context.tr('Fill all fields', 'Remplissez tous les champs'), ToastType.warn);
      return;
    }
    context.read<AppState>().addSavedCandidate(SavedCandidate(name: name, cand: cand, centre: centre));
    _name.clear();
    _cand.clear();
    _centre.clear();
    FocusScope.of(context).unfocus();
    Toast.show(context.tr('Candidate saved', 'Candidat enregistré'), ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final saved = context.watch<AppState>().savedCandidates;

    return SubScreen(
      title: context.tr('Saved candidates', 'Candidats enregistrés'),
      children: [
        Paragraph(
          context.tr(
            'Add a candidate number once and re-use it every exam season.',
            'Ajoutez un numéro de candidat une fois et réutilisez-le à chaque session.',
          ),
        ),
        if (saved.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              context.tr('No saved candidates yet.', 'Aucun candidat enregistré.'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: c.text3),
            ),
          )
        else
          for (var i = 0; i < saved.length; i++)
            InfoCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          saved[i].name,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${context.tr('Candidate', 'Candidat')} ${saved[i].cand} · Centre ${saved[i].centre}',
                          style: TextStyle(fontSize: 12, color: c.text2),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('Remove candidate', 'Supprimer le candidat'),
                    onPressed: () {
                      context.read<AppState>().removeSavedCandidate(i);
                      Toast.show(context.tr('Candidate removed', 'Candidat supprimé'), ToastType.success);
                    },
                    icon: FaIcon(FontAwesomeIcons.trash, size: 15, color: c.danger),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _name,
          label: context.tr('Add a candidate', 'Ajouter un candidat'),
          icon: FontAwesomeIcons.user,
          hint: context.tr('Candidate name', 'Nom du candidat'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
        AppTextField(
          controller: _cand,
          icon: FontAwesomeIcons.hashtag,
          hint: context.tr('Candidate number', 'Numéro de candidat'),
          numeric: true,
          textInputAction: TextInputAction.next,
        ),
        AppTextField(
          controller: _centre,
          icon: FontAwesomeIcons.school,
          hint: context.tr('Centre number', 'Numéro de centre'),
          numeric: true,
          onSubmitted: (_) => _add(),
        ),
        AppButton(
          label: context.tr('Add candidate', 'Ajouter le candidat'),
          icon: FontAwesomeIcons.plus,
          onPressed: _add,
        ),
      ],
    );
  }
}
