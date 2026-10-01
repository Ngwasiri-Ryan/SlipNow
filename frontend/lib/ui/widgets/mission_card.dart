import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/l10n.dart';
import '../../core/mission.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'common.dart';

/// Brand card explaining what SlipNow is for, ending with the reminder to
/// collect the original slip from school.
class MissionCard extends StatelessWidget {
  const MissionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    String t((String, String) s) => context.tr(s.$1, s.$2);

    return FadeSlideIn(
      child: HeroGradientCard(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: const FaIcon(FontAwesomeIcons.graduationCap, size: 15, color: AppColors.onAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t(MissionCopy.headline),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              t(MissionCopy.summary),
              style: TextStyle(fontSize: 13.5, height: 1.6, color: Colors.white.withValues(alpha: 0.88)),
            ),
            const SizedBox(height: 16),
            for (final (icon, title, body) in MissionCopy.pillars)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: FaIcon(icon, size: 12, color: c.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(title),
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t(body),
                            style: TextStyle(fontSize: 12.5, height: 1.45, color: Colors.white.withValues(alpha: 0.75)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            OriginalSlipNotice(onDark: true),
          ],
        ),
      ),
    );
  }
}

/// Reminder that candidates must still collect their original slip.
class OriginalSlipNotice extends StatelessWidget {
  const OriginalSlipNotice({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = onDark ? Colors.white : (c.isDark ? const Color(0xFFF0D9A8) : const Color(0xFF7A5A14));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withValues(alpha: 0.1) : c.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: onDark ? Colors.white.withValues(alpha: 0.18) : c.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: FaIcon(FontAwesomeIcons.school, size: 15, color: onDark ? c.accent : c.accentDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Collect your original slip', 'Retirez votre relevé original'),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg),
                ),
                const SizedBox(height: 3),
                Text(
                  context.tr(MissionCopy.original.$1, MissionCopy.original.$2),
                  style: TextStyle(fontSize: 12.5, height: 1.5, color: fg.withValues(alpha: onDark ? 0.85 : 1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
