import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/repositories.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/common.dart';
import '../widgets/feedback.dart';
import '../widgets/pressable.dart';
import 'main_shell.dart';
import 'terms_screen.dart';

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.2,
              color: c.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, height: 1.6, color: c.text2)),
        ],
      ),
    );
  }
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || phone.isEmpty || _pass.text.length < 6) {
      Toast.show(
        context.tr('Fill all fields (password 6+ characters)', 'Remplissez tous les champs (mot de passe 6+)'),
        ToastType.warn,
      );
      return;
    }
    setState(() => _loading = true);
    final msg = context.tr('Account created', 'Compte créé');
    try {
      await context.read<AppState>().signUp(name, phone, _pass.text);
      Toast.show(msg, ToastType.success);
      if (mounted) context.replaceAll(const MainShell());
    } on AuthException catch (e) {
      Toast.show(e.message, ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubScreen(
      title: context.tr('Create account', 'Créer un compte'),
      children: [
        _AuthHeader(
          title: context.tr('Let us get you set up', 'Configurons votre compte'),
          subtitle: context.tr(
            'Use your phone number. It is how you will pay and how we keep your slips safe.',
            'Utilisez votre numéro de téléphone. Il sert au paiement et à sécuriser vos relevés.',
          ),
        ),
        AutofillGroup(
          child: Column(
            children: [
              AppTextField(
                controller: _name,
                label: context.tr('Full name', 'Nom complet'),
                icon: FontAwesomeIcons.user,
                hint: 'e.g. Njuh Berns Ntam',
                autofillHints: const [AutofillHints.name],
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              AppTextField(
                controller: _phone,
                label: context.tr('Phone number', 'Numéro de téléphone'),
                icon: FontAwesomeIcons.phone,
                hint: '6XX XXX XXX',
                numeric: true,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.next,
              ),
              AppTextField(
                controller: _pass,
                label: context.tr('Password', 'Mot de passe'),
                icon: FontAwesomeIcons.lock,
                hint: context.tr('At least 6 characters', 'Au moins 6 caractères'),
                password: true,
                showStrength: true,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: context.tr('Create account', 'Créer un compte'),
          trailingIcon: FontAwesomeIcons.arrowRight,
          loading: _loading,
          onPressed: _submit,
        ),
        HelperText(
          text: context.tr('By creating an account you agree to our', 'En créant un compte, vous acceptez nos'),
          linkText: context.tr('Terms & conditions', 'Conditions d’utilisation'),
          onLink: () => context.push(const TermsScreen()),
        ),
        HelperText(
          text: context.tr('Already have an account?', 'Vous avez déjà un compte ?'),
          linkText: context.tr('Log in', 'Se connecter'),
          onLink: () => Navigator.of(context).pushReplacement(fadeRoute(const LoginScreen())),
        ),
      ],
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phone.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty || _pass.text.isEmpty) {
      Toast.show(context.tr('Enter phone and password', 'Entrez téléphone et mot de passe'), ToastType.warn);
      return;
    }
    setState(() => _loading = true);
    final msg = context.tr('Welcome back', 'Bon retour');
    try {
      await context.read<AppState>().logIn(phone, _pass.text);
      Toast.show(msg, ToastType.success);
      if (mounted) context.replaceAll(const MainShell());
    } on AuthException catch (e) {
      Toast.show(e.message, ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SubScreen(
      title: context.tr('Welcome back', 'Bon retour'),
      children: [
        _AuthHeader(
          title: context.tr('Log in', 'Connexion'),
          subtitle: context.tr('Your slips and receipts are waiting for you.', 'Vos relevés et reçus vous attendent.'),
        ),
        AutofillGroup(
          child: Column(
            children: [
              AppTextField(
                controller: _phone,
                label: context.tr('Phone number', 'Numéro de téléphone'),
                icon: FontAwesomeIcons.phone,
                hint: '6XX XXX XXX',
                numeric: true,
                autofillHints: const [AutofillHints.telephoneNumber],
                textInputAction: TextInputAction.next,
              ),
              AppTextField(
                controller: _pass,
                label: context.tr('Password', 'Mot de passe'),
                icon: FontAwesomeIcons.lock,
                hint: context.tr('Your password', 'Votre mot de passe'),
                password: true,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: context.tr('Log in', 'Se connecter'),
          trailingIcon: FontAwesomeIcons.arrowRight,
          loading: _loading,
          onPressed: _submit,
        ),
        const SizedBox(height: 24),
        Center(
          child: Pressable(
            onTap: () => Toast.show(
              context.tr('Biometric login not available in demo', 'Connexion biométrique indisponible en démo'),
            ),
            scale: 0.92,
            semanticLabel: context.tr('Log in with fingerprint', 'Connexion par empreinte'),
            child: Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surface,
                shape: BoxShape.circle,
                border: Border.all(color: c.border, width: 1.5),
              ),
              child: FaIcon(FontAwesomeIcons.fingerprint, size: 26, color: c.primary),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr('Log in with fingerprint', 'Connexion par empreinte'),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.text3),
        ),
        HelperText(
          text: context.tr('New here?', 'Nouveau ?'),
          linkText: context.tr('Create an account', 'Créer un compte'),
          onLink: () => Navigator.of(context).pushReplacement(fadeRoute(const SignupScreen())),
        ),
      ],
    );
  }
}
