import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../services/pdf_service.dart';
import '../widgets/feedback.dart';
import '../widgets/pressable.dart';
import '../widgets/slip_document.dart';

class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.result, this.heroTag});

  final ExamResult result;

  /// Matches the [Hero] on the thumbnail/preview the viewer was opened from.
  final Object? heroTag;

  static Object defaultHeroTag(ExamResult r) => 'slip-${r.slipId}';

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> with SingleTickerProviderStateMixin {
  static const _pageCount = 1;
  static const _zoomedScale = 2.5;

  final _transform = TransformationController();
  late final AnimationController _zoomAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  Animation<Matrix4>? _zoomTween;
  Offset _doubleTapAt = Offset.zero;
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _zoomAnim.addListener(() {
      if (_zoomTween != null) _transform.value = _zoomTween!.value;
    });
    _transform.addListener(() {
      final s = _transform.value.getMaxScaleOnAxis();
      if ((s - _scale).abs() > 0.01) setState(() => _scale = s);
    });
  }

  @override
  void dispose() {
    _zoomAnim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final Matrix4 end;
    if (_scale > 1.05) {
      end = Matrix4.identity();
    } else {
      final p = _doubleTapAt;
      end = Matrix4.identity()
        ..translateByDouble(-p.dx * (_zoomedScale - 1), -p.dy * (_zoomedScale - 1), 0, 1)
        ..scaleByDouble(_zoomedScale, _zoomedScale, 1, 1);
    }
    _zoomTween = Matrix4Tween(
      begin: _transform.value,
      end: end,
    ).animate(CurvedAnimation(parent: _zoomAnim, curve: Curves.easeOutCubic));
    _zoomAnim.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  Future<void> _run(Future<void> Function() action, String ok, String failed) async {
    try {
      await action();
      Toast.show(ok, ToastType.success);
    } catch (_) {
      Toast.show(failed, ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final pad = MediaQuery.paddingOf(context);
    final failed = context.tr('Something went wrong', 'Une erreur est survenue');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A2620),
        body: Column(
          children: [
            Container(
              color: const Color(0xFF0B1411),
              padding: EdgeInsets.fromLTRB(16, 12 + pad.top, 16, 12),
              child: Row(
                children: [
                  _RoundButton(
                    icon: FontAwesomeIcons.arrowLeft,
                    label: context.tr('Close PDF viewer', 'Fermer'),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          r.pdfFileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${r.name} · ${r.stream} ${r.year}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
                      onDoubleTap: _toggleZoom,
                      child: InteractiveViewer(
                        transformationController: _transform,
                        minScale: 1,
                        maxScale: 4,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 84),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: SlipDocument.pageWidth,
                                child: SlipHero(
                                  tag: widget.heroTag ?? PdfViewerScreen.defaultHeroTag(r),
                                  result: r,
                                  child: SlipDocument(result: r),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            _scale > 1.05
                                ? '${context.tr('Page', 'Page')} 1 / $_pageCount · ${(_scale * 100).round()}%'
                                : '${context.tr('Page', 'Page')} 1 / $_pageCount',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: AnimatedOpacity(
                      opacity: _scale > 1.05 ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        child: Text(
                          context.tr('Pinch or double-tap to zoom', 'Pincez ou touchez deux fois pour zoomer'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + pad.bottom),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1411),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  _ActionButton(
                    icon: FontAwesomeIcons.download,
                    label: context.tr('Download', 'Télécharger'),
                    onTap: () => _run(() => PdfService.saveSlip(r), context.tr('PDF ready', 'PDF prêt'), failed),
                  ),
                  _ActionButton(
                    icon: FontAwesomeIcons.shareNodes,
                    label: context.tr('Share', 'Partager'),
                    highlight: true,
                    onTap: () => _run(() => PdfService.shareSlip(r), context.tr('Shared', 'Partagé'), failed),
                  ),
                  _ActionButton(
                    icon: FontAwesomeIcons.print,
                    label: context.tr('Print', 'Imprimer'),
                    onTap: () {
                      final msg = context.tr('Printing not available', 'Impression indisponible');
                      PdfService.printSlip(r).catchError((_) => Toast.show(msg, ToastType.warn));
                    },
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap});

  final FaIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      scale: 0.9,
      semanticLabel: label,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: FaIcon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.highlight = false});

  final FaIconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF2A93B);
    return Expanded(
      child: Pressable(
        onTap: onTap,
        scale: 0.94,
        semanticLabel: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: highlight ? accent : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(icon, size: 17, color: highlight ? const Color(0xFF2A1D00) : Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
