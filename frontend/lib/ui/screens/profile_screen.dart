import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/l10n.dart';
import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/external_actions.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/chat/support_avatar.dart';
import '../widgets/collapsing_header.dart';
import '../widgets/common.dart';
import '../widgets/feedback.dart';
import '../widgets/pressable.dart';
import 'chat_screen.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import 'main_shell.dart';
import 'receipts_screen.dart';
import 'saved_candidates_screen.dart';
import 'splash_screen.dart';
import 'terms_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.watch<AppState>();
    final name = s.user?.name ?? 'Guest';

    return CollapsingPage(
      eyebrow: context.tr('Account', 'Compte'),
      title: context.tr('Profile', 'Profil'),
      bottomPadding: tabBarClearance(context),
      children: [
        const SizedBox(height: 6),
        _ProfileCard(
          name: name,
          phone: s.user?.phone ?? context.tr('Not signed in', 'Non connecté'),
          onEdit: () => context.push(const EditProfileScreen()),
        ),
        _GroupLabel(context.tr('Account', 'Compte')),
        _MenuGroup(
          children: [
            _MenuItem(
              icon: FontAwesomeIcons.users,
              tone: _Tone.accent,
              label: context.tr('Saved candidates', 'Candidats enregistrés'),
              subtitle: context.tr(
                'Add siblings and re-use candidate numbers',
                'Ajoutez frères et sœurs et réutilisez les numéros',
              ),
              onTap: () => context.push(const SavedCandidatesScreen()),
            ),
            _MenuItem(
              icon: FontAwesomeIcons.receipt,
              label: context.tr('Payment receipts', 'Reçus de paiement'),
              onTap: () => context.push(const ReceiptsScreen()),
            ),
          ],
        ),
        _GroupLabel(context.tr('Appearance', 'Apparence')),
        _MenuGroup(
          children: [
            _ThemeSwatches(current: s.brand, onPick: s.setBrand),
            _MenuItem(
              icon: FontAwesomeIcons.moon,
              label: context.tr('Dark mode', 'Mode sombre'),
              onTap: s.toggleDarkMode,
              trailing: _Toggle(on: s.darkMode),
            ),
            _MenuItem(
              icon: FontAwesomeIcons.globe,
              label: '${context.tr('Language', 'Langue')} · ${s.language.displayName}',
              onTap: () {
                s.toggleLanguage();
                Toast.show(s.language == AppLanguage.fr ? 'Langue : Français' : 'Language: English');
              },
            ),
          ],
        ),
        _GroupLabel(context.tr('Support', 'Assistance')),
        _MenuGroup(
          children: [
            ListenableBuilder(
              listenable: s.chat,
              builder: (context, _) => _MenuItem(
                icon: FontAwesomeIcons.solidCommentDots,
                tone: _Tone.accent,
                label: context.tr('Live chat', 'Chat en direct'),
                subtitle: context.tr(
                  '${s.chat.agent.name} is online · replies in minutes',
                  '${s.chat.agent.name} est en ligne · répond vite',
                ),
                onTap: () => context.push(const ChatScreen()),
                trailing: s.chat.unread > 0 ? UnreadBadge(count: s.chat.unread) : null,
              ),
            ),
            _MenuItem(
              icon: FontAwesomeIcons.whatsapp,
              label: context.tr('WhatsApp support', 'Support WhatsApp'),
              onTap: ExternalActions.openSupportWhatsApp,
            ),
            _MenuItem(
              icon: FontAwesomeIcons.circleQuestion,
              label: context.tr('Help center', "Centre d'aide"),
              subtitle: context.tr('Why SlipNow exists, FAQs', 'Pourquoi SlipNow, FAQ'),
              onTap: () => context.push(const HelpScreen()),
            ),
            _MenuItem(
              icon: FontAwesomeIcons.fileContract,
              label: context.tr('Terms & conditions', 'Conditions d’utilisation'),
              onTap: () => context.push(const TermsScreen()),
            ),
          ],
        ),
        _MenuGroup(
          children: [
            _MenuItem(
              icon: FontAwesomeIcons.rightFromBracket,
              tone: _Tone.danger,
              label: context.tr('Log out', 'Se déconnecter'),
              onTap: () => _confirmLogout(context),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 20),
          child: Text(
            'SlipNow · v${AppConstants.appVersion}\n'
            '${context.tr('Operated for GCE candidates in Cameroon', 'Au service des candidats GCE au Cameroun')}\n'
            '${context.tr('Always collect your original slip from your school.', 'Retirez toujours votre relevé original dans votre établissement.')}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: c.text3),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xFF0F1F1A).withValues(alpha: 0.6),
      builder: (dialogContext) => const _LogoutDialog(),
    );
    if (confirmed != true || !context.mounted) return;
    final msg = context.tr('Logged out', 'Déconnecté');
    final state = context.read<AppState>();
    await state.logOut();
    state.setTab(AppTab.home);
    Toast.show(msg, ToastType.success);
    if (context.mounted) context.replaceAll(const SplashScreen());
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.phone, required this.onEdit});

  final String name;
  final String phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FadeSlideIn(
      child: Container(
        margin: const EdgeInsets.only(bottom: 22),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.primary, c.isDark ? c.primaryDark : Color.lerp(c.primaryDark, AppColors.heroEnd, 0.5)!],
          ),
          boxShadow: [BoxShadow(color: c.primary.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 12))],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -30,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.accent.withValues(alpha: 0.2)),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [c.accent, Colors.white.withValues(alpha: 0.8)]),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c.primaryDark),
                      child: Text(
                        name.isEmpty ? '?' : name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            FaIcon(FontAwesomeIcons.phone, size: 11, color: Colors.white.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                phone,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Pressable(
                    onTap: onEdit,
                    scale: 0.92,
                    semanticLabel: context.tr('Edit profile', 'Modifier le profil'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.pen, size: 10, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            context.tr('Edit', 'Modifier'),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: context.colors.text3),
      ),
    );
  }
}

class _ThemeSwatches extends StatelessWidget {
  const _ThemeSwatches({required this.current, required this.onPick});

  final BrandTheme current;
  final ValueChanged<BrandTheme> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String name(BrandTheme t) => switch (t) {
      BrandTheme.forest => context.tr('Forest', 'Forêt'),
      BrandTheme.navy => context.tr('Navy', 'Marine'),
      BrandTheme.teal => context.tr('Teal', 'Sarcelle'),
      BrandTheme.plum => context.tr('Plum', 'Prune'),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          IconTile(icon: FontAwesomeIcons.palette, size: 40, iconSize: 15),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Theme colour', 'Couleur du thème'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text),
                ),
                const SizedBox(height: 2),
                Text(
                  name(current),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.text3),
                ),
              ],
            ),
          ),
          for (final t in BrandTheme.values)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Pressable(
                onTap: () => onPick(t),
                scale: 0.85,
                semanticLabel: name(t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30,
                  height: 30,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: t == current ? t.primary : Colors.transparent, width: 2),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.isDark ? t.darkPrimary : t.primary),
                    child: AnimatedScale(
                      scale: t == current ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const FaIcon(FontAwesomeIcons.check, size: 10, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(
                icon: FontAwesomeIcons.rightFromBracket,
                size: 64,
                iconSize: 26,
                radius: 32,
                background: c.dangerSoft,
                foreground: c.danger,
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('Log out?', 'Se déconnecter ?'),
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: c.text),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr(
                  'Your saved slips will be here when you return.',
                  'Vos relevés vous attendront à votre retour.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.55, color: c.text2),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: context.tr('Cancel', 'Annuler'),
                      variant: ButtonVariant.ghost,
                      compact: true,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppButton(
                      label: context.tr('Log out', 'Se déconnecter'),
                      variant: ButtonVariant.danger,
                      compact: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) Divider(height: 1, thickness: 1, color: c.border),
          ],
        ],
      ),
    );
  }
}

enum _Tone { primary, accent, danger }

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.tone = _Tone.primary,
  });

  final FaIconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final (bg, fg) = switch (tone) {
      _Tone.primary => (c.primarySoft, c.primary),
      _Tone.accent => (c.accentSoft, c.accentDark),
      _Tone.danger => (c.dangerSoft, c.danger),
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: c.surface2,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              IconTile(icon: icon, size: 40, iconSize: 15, background: bg, foreground: fg),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tone == _Tone.danger ? c.danger : c.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: c.text3),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ?? FaIcon(FontAwesomeIcons.chevronRight, size: 13, color: c.text3),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 48,
      height: 28,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: on ? c.primary : c.borderStrong,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }
}
