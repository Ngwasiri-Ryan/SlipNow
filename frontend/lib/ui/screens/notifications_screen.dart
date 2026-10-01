import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Timer? _markAllTimer;

  @override
  void initState() {
    super.initState();
    _markAllTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) context.read<AppState>().markAllNotificationsRead();
    });
  }

  @override
  void dispose() {
    _markAllTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.watch<AppState>();
    final items = s.notifications;

    return SubScreen(
      title: context.tr('Notifications', 'Notifications'),
      children: [
        if (items.isEmpty)
          EmptyState(
            icon: FontAwesomeIcons.bellSlash,
            title: context.tr('No notifications', 'Aucune notification'),
            message: context.tr('You are all caught up.', 'Vous êtes à jour.'),
          )
        else
          for (var i = 0; i < items.length; i++)
            FadeSlideIn(
              delay: Duration(milliseconds: 60 * i),
              child: _NotificationTile(n: items[i], onTap: () => s.markNotificationRead(i), colors: c),
            ),
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.n, required this.onTap, required this.colors});

  final AppNotification n;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final (icon, bg, fg) = switch (n.kind) {
      NotificationKind.accent => (FontAwesomeIcons.bullhorn, c.accentSoft, c.accentDark),
      NotificationKind.success => (FontAwesomeIcons.circleCheck, c.successSoft, c.success),
      NotificationKind.info => (FontAwesomeIcons.circleInfo, c.primarySoft, c.primary),
    };
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(duration: const Duration(milliseconds: 250), width: n.unread ? 4 : 0, color: c.accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTile(icon: icon, iconSize: 16, background: bg, foreground: fg),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr(n.title, n.titleFr),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, height: 1.3, color: c.text),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr(n.text, n.textFr),
                              style: TextStyle(fontSize: 12.5, height: 1.5, color: c.text2),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr(n.time, n.timeFr),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                color: c.text3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
