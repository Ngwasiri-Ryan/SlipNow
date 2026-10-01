import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    final connectivity = Connectivity();
    connectivity.checkConnectivity().then(_update).catchError((_) {});
    _sub = connectivity.onConnectivityChanged.listen(_update, onError: (_) {});
  }

  void _update(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (mounted && offline != _offline) setState(() => _offline = offline);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 16,
      right: 16,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: _offline ? Offset.zero : const Offset(0, -2),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: _offline ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: c.shadowLg,
                ),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.wifi, size: 14, color: AppColors.onAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr(
                          'You are offline — your slips are still available',
                          'Hors ligne — vos relevés restent disponibles',
                        ),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.onAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
