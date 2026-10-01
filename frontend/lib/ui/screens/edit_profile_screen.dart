import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/common.dart';
import '../widgets/feedback.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final AppState _state = context.read<AppState>();
  late final _name = TextEditingController(text: _state.user?.name ?? '');
  late final _phone = TextEditingController(text: _state.user?.phone ?? '');
  final _pass = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      Toast.show(context.tr('Name and phone required', 'Nom et téléphone requis'), ToastType.warn);
      return;
    }
    setState(() => _saving = true);
    final msg = context.tr('Profile updated', 'Profil mis à jour');
    await _state.updateProfile(name, phone, _pass.text.isEmpty ? null : _pass.text);
    Toast.show(msg, ToastType.success);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SubScreen(
      title: context.tr('Edit profile', 'Modifier le profil'),
      children: [
        AppTextField(
          controller: _name,
          label: context.tr('Full name', 'Nom complet'),
          icon: FontAwesomeIcons.user,
          hint: context.tr('Your name', 'Votre nom'),
          textCapitalization: TextCapitalization.words,
        ),
        AppTextField(
          controller: _phone,
          label: context.tr('Phone number', 'Numéro de téléphone'),
          icon: FontAwesomeIcons.phone,
          hint: '6XX XXX XXX',
          numeric: true,
        ),
        AppTextField(
          controller: _pass,
          label: context.tr('New password', 'Nouveau mot de passe'),
          optionalHint: context.tr('(leave blank to keep current)', '(laisser vide pour conserver)'),
          icon: FontAwesomeIcons.lock,
          hint: context.tr('Optional', 'Facultatif'),
          password: true,
        ),
        AppButton(
          label: context.tr('Save changes', 'Enregistrer'),
          icon: FontAwesomeIcons.check,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
