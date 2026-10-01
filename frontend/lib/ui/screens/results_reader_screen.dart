import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../core/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../services/external_actions.dart';
import '../widgets/feedback.dart';

/// Full-screen reader for an official results PDF, with in-document search
/// that highlights every match.
class ResultsReaderScreen extends StatefulWidget {
  const ResultsReaderScreen({super.key, required this.pdf, this.initialQuery});

  final ResultsPdf pdf;
  final String? initialQuery;

  /// Builds the search pattern for what the student typed. A single word is
  /// matched anywhere; several words match any line containing all of them in
  /// any order, so "Ryan Nkwetesing" finds "NKWETESING RYAN SIMOLEN".
  static Pattern? patternFor(String raw) {
    final text = raw.trim();
    if (text.length < 2) return null;
    final words = text.split(RegExp(r'\s+'));
    if (words.length == 1) return text;
    final lookaheads = words.map((w) => '(?=[^\\n]*\\b${RegExp.escape(w)})').join();
    return RegExp('^$lookaheads[^\\r\\n]+', multiLine: true, caseSensitive: false);
  }

  @override
  State<ResultsReaderScreen> createState() => _ResultsReaderScreenState();
}

class _ResultsReaderScreenState extends State<ResultsReaderScreen> {
  final _controller = PdfViewerController();
  final _query = TextEditingController();
  final _focus = FocusNode();
  PdfTextSearcher? _searcher;
  PdfViewerParams? _params;
  bool? _paramsDark;
  bool _searchOpen = false;
  int _page = 1;
  late int _pageCount = widget.pdf.pages;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery;
    if (q != null && q.trim().isNotEmpty) {
      _searchOpen = true;
      _query.text = q;
    }
  }

  @override
  void dispose() {
    _searcher
      ?..removeListener(_onSearchChanged)
      ..dispose();
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onViewerReady(PdfDocument document, PdfViewerController controller) {
    final searcher = PdfTextSearcher(controller)..addListener(_onSearchChanged);
    setState(() {
      _searcher = searcher;
      _pageCount = document.pages.length;
    });
    if (_query.text.trim().isNotEmpty) _runSearch(immediate: true);
  }

  void _onPageChanged(int? page) {
    if (page != null && page != _page) setState(() => _page = page);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  void _paintMatches(ui.Canvas canvas, Rect pageRect, PdfPage page) =>
      _searcher?.pageTextMatchPaintCallback(canvas, pageRect, page);

  List<Widget> _overlays(BuildContext context, Size size, PdfViewerHandleLinkTap handleLinkTap) => [
    PdfViewerScrollThumb(
      controller: _controller,
      orientation: ScrollbarOrientation.right,
      thumbSize: const Size(54, 30),
      margin: 4,
      thumbBuilder: (context, thumbSize, pageNumber, controller) => _PageThumb(page: pageNumber),
    ),
  ];

  PdfViewerParams _paramsFor(AppColors c) {
    if (_params != null && _paramsDark == c.isDark) return _params!;
    _paramsDark = c.isDark;
    return _params = PdfViewerParams(
      margin: 10,
      backgroundColor: c.isDark ? const Color(0xFF0E1714) : const Color(0xFFE6EBE9),
      pageDropShadow: BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 2)),
      matchTextColor: const Color(0x80FFE14D),
      activeMatchTextColor: const Color(0xA6FF8A00),
      pagePaintCallbacks: [_paintMatches],
      onViewerReady: _onViewerReady,
      onPageChanged: _onPageChanged,
      viewerOverlayBuilder: _overlays,
      loadingBannerBuilder: _loading,
      errorBannerBuilder: _error,
    );
  }

  Widget _loading(BuildContext context, int bytesDownloaded, int? totalBytes) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            value: totalBytes == null || totalBytes == 0 ? null : bytesDownloaded / totalBytes,
            color: context.colors.primaryLight,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          context.tr('Opening results…', 'Ouverture des résultats…'),
          style: TextStyle(fontSize: 13, color: context.colors.text2),
        ),
      ],
    ),
  );

  Widget _error(BuildContext context, Object error, StackTrace? stackTrace, PdfDocumentRef documentRef) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(FontAwesomeIcons.triangleExclamation, size: 28, color: context.colors.warn),
          const SizedBox(height: 12),
          Text(
            context.tr('This PDF could not be opened.', 'Impossible d’ouvrir ce PDF.'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.colors.text),
          ),
        ],
      ),
    ),
  );

  void _runSearch({bool immediate = false}) {
    final searcher = _searcher;
    if (searcher == null) return;
    final pattern = ResultsReaderScreen.patternFor(_query.text);
    if (pattern == null) {
      searcher.resetTextSearch();
      return;
    }
    searcher.startTextSearch(pattern, searchImmediately: immediate);
  }

  void _submit(String _) {
    final searcher = _searcher;
    if (searcher != null && searcher.hasMatches && searcher.pattern != null) {
      _next();
    } else {
      _runSearch(immediate: true);
    }
    _focus.requestFocus();
  }

  void _next() {
    final s = _searcher;
    if (s == null || s.matches.isEmpty) return;
    HapticFeedback.selectionClick();
    final i = s.currentIndex;
    s.goToMatchOfIndex(i == null || i + 1 >= s.matches.length ? 0 : i + 1);
  }

  void _prev() {
    final s = _searcher;
    if (s == null || s.matches.isEmpty) return;
    HapticFeedback.selectionClick();
    final i = s.currentIndex;
    s.goToMatchOfIndex(i == null || i == 0 ? s.matches.length - 1 : i - 1);
  }

  void _openSearch() {
    setState(() => _searchOpen = true);
    _focus.requestFocus();
  }

  void _closeSearch() {
    _searcher?.resetTextSearch();
    _query.clear();
    _focus.unfocus();
    setState(() => _searchOpen = false);
  }

  Future<void> _goToPage() async {
    final input = TextEditingController(text: '$_page');
    final page = await showDialog<int>(
      context: context,
      builder: (ctx) {
        void submit() => Navigator.pop(ctx, int.tryParse(input.text.trim()));
        return AlertDialog(
          title: Text(context.tr('Go to page', 'Aller à la page')),
          content: TextField(
            controller: input,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(hintText: '1 – $_pageCount'),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('Cancel', 'Annuler'))),
            TextButton(onPressed: submit, child: Text(context.tr('Go', 'Aller'))),
          ],
        );
      },
    );
    input.dispose();
    if (page == null || !mounted) return;
    if (page < 1 || page > _pageCount) {
      Toast.show(context.tr('Enter a page from 1 to $_pageCount', 'Entrez une page de 1 à $_pageCount'), ToastType.warn);
      return;
    }
    if (_controller.isReady) _controller.goToPage(pageNumber: page);
  }

  Future<void> _share() async {
    final failed = context.tr('Could not share this PDF', 'Partage impossible');
    try {
      await ExternalActions.shareResultsPdf(widget.pdf);
    } catch (_) {
      Toast.show(failed, ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pdf = widget.pdf;
    final params = _paramsFor(c);

    return PopScope(
      canPop: !_searchOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSearch();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: params.backgroundColor,
          body: Column(
            children: [
              _header(c),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: _searchOpen ? _searchStatus(c) : const SizedBox(width: double.infinity),
              ),
              Expanded(
                child: pdf.isNetwork
                    ? PdfViewer.uri(Uri.parse(pdf.source), controller: _controller, params: params)
                    : PdfViewer.asset(pdf.source, controller: _controller, params: params),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppColors c) {
    final green = c.isDark ? c.primaryDark : c.primary;
    return Material(
      color: green,
      elevation: 3,
      shadowColor: Colors.black38,
      child: Padding(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: SizedBox(
          height: 60,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _searchOpen ? _searchRow() : _titleRow(),
          ),
        ),
      ),
    );
  }

  Widget _titleRow() {
    final pdf = widget.pdf;
    return Row(
      key: const ValueKey('title'),
      children: [
        IconButton(
          onPressed: () => Navigator.maybePop(context),
          tooltip: context.tr('Close', 'Fermer'),
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18, color: Colors.white),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${pdf.session} ${context.tr(pdf.titleEn, pdf.titleFr)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr('Page $_page of $_pageCount', 'Page $_page sur $_pageCount'),
                style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.75)),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            if (_controller.isReady) {
              _controller.setZoom(_controller.centerPosition, _controller.currentZoom * 1.5);
            }
          },
          tooltip: context.tr('Zoom in', 'Zoomer'),
          icon: const FaIcon(FontAwesomeIcons.magnifyingGlassPlus, size: 18, color: Colors.white),
        ),
        IconButton(
          onPressed: () {
            if (_controller.isReady) {
              _controller.setZoom(_controller.centerPosition, _controller.currentZoom / 1.5);
            }
          },
          tooltip: context.tr('Zoom out', 'Dézoomer'),
          icon: const FaIcon(FontAwesomeIcons.magnifyingGlassMinus, size: 18, color: Colors.white),
        ),
        IconButton(
          onPressed: _openSearch,
          tooltip: context.tr('Search in PDF', 'Rechercher dans le PDF'),
          icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18, color: Colors.white),
        ),
        IconButton(
          onPressed: _share,
          tooltip: context.tr('Share PDF', 'Partager le PDF'),
          icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 18, color: Colors.white),
        ),
        PopupMenuButton<int>(
          tooltip: context.tr('More options', 'Plus d’options'),
          icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 18, color: Colors.white),
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          onSelected: (v) => v == 0 ? _goToPage() : null,
          itemBuilder: (_) => [
            _menuItem(0, FontAwesomeIcons.arrowRightToBracket, context.tr('Go to page', 'Aller à la page')),
          ],
        ),
        const SizedBox(width: 2),
      ],
    );
  }

  PopupMenuItem<int> _menuItem(int value, FaIconData icon, String label) {
    final c = context.colors;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          SizedBox(width: 22, child: FaIcon(icon, size: 15, color: c.text2)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: c.text)),
        ],
      ),
    );
  }

  Widget _searchRow() {
    return Row(
      key: const ValueKey('search'),
      children: [
        IconButton(
          onPressed: _closeSearch,
          tooltip: context.tr('Close search', 'Fermer la recherche'),
          icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18, color: Colors.white),
        ),
        Expanded(
          child: TextField(
            controller: _query,
            focusNode: _focus,
            autofocus: true,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.characters,
            cursorColor: Colors.white,
            style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isCollapsed: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: context.tr('Search your name…', 'Recherchez votre nom…'),
              hintStyle: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6)),
            ),
            onChanged: (_) {
              setState(() {});
              _runSearch();
            },
            onSubmitted: _submit,
          ),
        ),
        if (_query.text.isNotEmpty)
          IconButton(
            onPressed: () {
              _query.clear();
              _searcher?.resetTextSearch();
              _focus.requestFocus();
              setState(() {});
            },
            tooltip: context.tr('Clear', 'Effacer'),
            icon: const FaIcon(FontAwesomeIcons.xmark, size: 18, color: Colors.white),
          ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _searchStatus(AppColors c) {
    final s = _searcher;
    final hasQuery = ResultsReaderScreen.patternFor(_query.text) != null;
    final searching = s?.isSearching ?? false;
    final matches = s?.matches.length ?? 0;
    final index = s?.currentIndex;

    final FaIconData icon;
    final Color tone;
    final String text;
    if (!hasQuery) {
      icon = FontAwesomeIcons.lightbulb;
      tone = c.text2;
      text = context.tr(
        'Type your name as registered, e.g. surname and first name',
        'Tapez votre nom tel qu’inscrit, ex. nom et prénom',
      );
    } else if (s == null || (searching && matches == 0)) {
      final page = s?.searchingPageNumber ?? 1;
      icon = FontAwesomeIcons.magnifyingGlass;
      tone = c.text2;
      text = context.tr('Searching page $page of $_pageCount…', 'Recherche page $page sur $_pageCount…');
    } else if (matches == 0) {
      icon = FontAwesomeIcons.circleExclamation;
      tone = c.warn;
      text = context.tr(
        'No matches. Check the spelling or search only your surname.',
        'Aucun résultat. Vérifiez l’orthographe ou cherchez seulement votre nom.',
      );
    } else {
      final i = index ?? 0;
      final more = searching ? '+' : '';
      final page = s.matches[i].pageNumber;
      icon = FontAwesomeIcons.solidCircleCheck;
      tone = c.success;
      text = context.tr('${i + 1} of $matches$more · page $page', '${i + 1} sur $matches$more · page $page');
    }

    return Material(
      color: c.surface,
      elevation: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 2,
            child: searching
                ? LinearProgressIndicator(
                    value: s?.searchProgress,
                    color: c.primaryLight,
                    backgroundColor: c.primarySoft,
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
            child: Row(
              children: [
                FaIcon(icon, size: 14, color: tone),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text),
                  ),
                ),
                IconButton(
                  onPressed: matches > 0 ? _prev : null,
                  tooltip: context.tr('Previous match', 'Résultat précédent'),
                  icon: FaIcon(FontAwesomeIcons.chevronUp, size: 16, color: matches > 0 ? c.text : c.text3),
                ),
                IconButton(
                  onPressed: matches > 0 ? _next : null,
                  tooltip: context.tr('Next match', 'Résultat suivant'),
                  icon: FaIcon(FontAwesomeIcons.chevronDown, size: 16, color: matches > 0 ? c.text : c.text3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PageThumb extends StatelessWidget {
  const _PageThumb({required this.page});

  final int? page;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.border),
        boxShadow: c.shadowMd,
      ),
      child: Text(
        '${page ?? ''}',
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: c.text),
      ),
    );
  }
}
