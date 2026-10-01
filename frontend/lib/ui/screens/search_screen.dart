import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/l10n.dart';
import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../state/app_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/collapsing_header.dart';
import '../widgets/common.dart';
import '../widgets/pressable.dart';
import '../widgets/skeleton.dart';
import 'main_shell.dart';
import 'result_screen.dart';

/// Height of the floating tab bar, used to park the sticky Search button
/// just above it.
const _tabBarHeight = 74.0;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _name = TextEditingController();
  final _cand = TextEditingController();
  final _centre = TextEditingController();
  final _nameFocus = FocusNode();
  String _year = AppConstants.examYears.first;
  bool _loading = false;
  List<ExamResult>? _results;

  Timer? _debounce;
  String _lastQueried = '';
  List<ExamResult> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _name.addListener(_onNameChanged);
    _nameFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _cand.dispose();
    _centre.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final text = _name.text;
    if (text == _lastQueried) return;
    _lastQueried = text;
    _debounce?.cancel();
    if (text.trim().length < 2) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      final state = context.read<AppState>();
      final list = await state.results.suggest(stream: state.selectedStream, year: _year, name: text);
      if (!mounted || _name.text != text) return;
      setState(() => _suggestions = list);
    });
  }

  bool get _showSuggestions =>
      _nameFocus.hasFocus &&
      _suggestions.isNotEmpty &&
      !(_suggestions.length == 1 && _suggestions.first.name == _name.text);

  void _pickSuggestion(ExamResult r) {
    setState(() {
      _lastQueried = r.name;
      _name.text = r.name;
      _cand.text = r.cand;
      _centre.text = r.centre;
      _suggestions = const [];
      _results = [r];
    });
    FocusScope.of(context).unfocus();
    context.push(ResultScreen(result: r));
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final state = context.read<AppState>();
    setState(() {
      _loading = true;
      _suggestions = const [];
    });
    final results = await state.results.search(
      ResultQuery(
        stream: state.selectedStream,
        year: _year,
        name: _name.text,
        cand: _cand.text.trim(),
        centre: _centre.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = results;
    });
    if (results.length == 1) context.push(ResultScreen(result: results.first));
  }

  void _useSaved(SavedCandidate c) {
    setState(() {
      _lastQueried = c.name;
      _name.text = c.name;
      _cand.text = c.cand;
      _centre.text = c.centre;
      _suggestions = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final state = context.watch<AppState>();
    final stream = ExamStream.byId(state.selectedStream);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final stickyBottom = 12 + bottomInset + _tabBarHeight + 12;

    return Stack(
      children: [
        CollapsingPage(
          eyebrow: context.tr('Step 1 of 2', 'Étape 1 sur 2'),
          eyebrowWidget: const _StepIndicator(step: 1, total: 2),
          title: context.tr('Search your results', 'Recherchez vos résultats'),
          bottomPadding: tabBarClearance(context) + 72,
          beforeList: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
                  itemCount: ExamStream.all.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final s = ExamStream.all[i];
                    return _StreamChip(
                      stream: s,
                      active: s.id == state.selectedStream,
                      onTap: () => state.selectStream(s.id),
                    );
                  },
                ),
              ),
            ),
          ],
          children: [
            const SizedBox(height: 6),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(stream.id),
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: FaIcon(FontAwesomeIcons.circleInfo, size: 14, color: c.accentDark),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr(stream.infoEn, stream.infoFr),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: c.isDark ? const Color(0xFFF0D9A8) : const Color(0xFF7A5A14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.release case final r? when !r.released && r.session == _year)
              _NotReleasedBanner(session: r.session),
            if (state.savedCandidates.isNotEmpty) ...[
              Text(
                context.tr('Saved candidates', 'Candidats enregistrés'),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text2),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sc in state.savedCandidates)
                    Pressable(
                      onTap: () => _useSaved(sc),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: c.primarySoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(FontAwesomeIcons.user, size: 11, color: c.primary),
                            const SizedBox(width: 6),
                            Text(
                              sc.name,
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            AppSelectField<String>(
              label: context.tr('Exam year', "Année d'examen"),
              icon: FontAwesomeIcons.calendar,
              value: _year,
              items: [for (final y in AppConstants.examYears) (y, y)],
              onChanged: (v) => setState(() => _year = v),
            ),
            AppTextField(
              controller: _name,
              focusNode: _nameFocus,
              label: context.tr('Candidate name', 'Nom du candidat'),
              icon: FontAwesomeIcons.user,
              hint: context.tr('Start typing your name...', 'Commencez à taper votre nom...'),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              trailing: ValueListenableBuilder(
                valueListenable: _name,
                builder: (_, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : Pressable(
                        onTap: () => _name.clear(),
                        semanticLabel: context.tr('Clear name', 'Effacer le nom'),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: FaIcon(FontAwesomeIcons.circleXmark, size: 16, color: c.text3),
                        ),
                      ),
              ),
              below: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _showSuggestions
                    ? _SuggestionList(query: _name.text.trim(), items: _suggestions, onPick: _pickSuggestion)
                    : const SizedBox(width: double.infinity),
              ),
            ),
            AppTextField(
              controller: _cand,
              label: context.tr('Candidate number', 'Numéro de candidat'),
              optionalHint: context.tr('(optional)', '(facultatif)'),
              icon: FontAwesomeIcons.hashtag,
              hint: 'e.g. 05210417',
              numeric: true,
              textInputAction: TextInputAction.next,
            ),
            AppTextField(
              controller: _centre,
              label: context.tr('Centre number', 'Numéro de centre'),
              optionalHint: context.tr('(optional)', '(facultatif)'),
              icon: FontAwesomeIcons.school,
              hint: 'e.g. 11045',
              numeric: true,
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 6),
            _resultsSection(c),
          ],
        ),
        Positioned(
          left: 22,
          right: 22,
          bottom: stickyBottom,
          child: AppButton(
            label: _loading
                ? context.tr('Searching GCE records...', 'Recherche...')
                : context.tr('Search', 'Rechercher'),
            icon: FontAwesomeIcons.magnifyingGlass,
            loading: _loading,
            onPressed: _search,
          ),
        ),
      ],
    );
  }

  Widget _resultsSection(AppColors c) {
    if (_loading) {
      return const Column(children: [SkeletonResultCard(), SkeletonResultCard(), SkeletonResultCard()]);
    }
    final results = _results;
    if (results == null || results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Column(
          children: [
            FaIcon(
              results == null ? FontAwesomeIcons.magnifyingGlass : FontAwesomeIcons.userSlash,
              size: 32,
              color: c.text3.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 14),
            Text(
              results == null
                  ? context.tr(
                      'Search by name or candidate number to find your GCE result slip.',
                      'Recherchez par nom ou numéro de candidat pour trouver votre relevé GCE.',
                    )
                  : context.tr(
                      'No match found. Check spelling or try another track.',
                      "Aucun résultat. Vérifiez l'orthographe.",
                    ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.6, color: c.text3),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${results.length} ${context.tr('candidates match your search', 'candidats correspondent')}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.text2),
          ),
        ),
        for (var i = 0; i < results.length; i++)
          FadeSlideIn(
            delay: Duration(milliseconds: 60 * i),
            child: InfoCard(
              animate: false,
              padding: const EdgeInsets.all(16),
              onTap: () => context.push(ResultScreen(result: results[i])),
              child: Row(
                children: [
                  IconTile(icon: FontAwesomeIcons.fileLines, size: 44, iconSize: 17),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StreamBadge(results[i].stream, margin: const EdgeInsets.only(bottom: 6)),
                        Text(
                          results[i].name,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${results[i].year} · Centre ${results[i].centre} · ${context.tr('Candidate', 'Candidat')} ${results[i].cand}',
                          style: TextStyle(fontSize: 12, color: c.text2),
                        ),
                      ],
                    ),
                  ),
                  FaIcon(FontAwesomeIcons.chevronRight, size: 13, color: c.text3),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NotReleasedBanner extends StatelessWidget {
  const _NotReleasedBanner({required this.session});

  final String session;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.warnSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.warn.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: FaIcon(FontAwesomeIcons.hourglassHalf, size: 14, color: c.warn),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr(
                'The $session results have not been released by the GCE Board yet. You can still search earlier sessions.',
                'Les résultats $session ne sont pas encore publiés par le GCE Board. Vous pouvez chercher les sessions précédentes.',
              ),
              style: TextStyle(fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w600, color: c.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr('Step $step of $total', 'Étape $step sur $total'),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text2),
        ),
        const SizedBox(width: 10),
        for (var i = 1; i <= total; i++) ...[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: i == step ? 26 : 14,
            height: 6,
            decoration: BoxDecoration(
              color: i <= step ? c.primary : c.border,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          if (i < total) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.query, required this.items, required this.onPick});

  final String query;
  final List<ExamResult> items;
  final ValueChanged<ExamResult> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
        boxShadow: c.shadowMd,
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onPick(items[i]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      IconTile(icon: FontAwesomeIcons.user, size: 34, iconSize: 13, radius: 17),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Highlighted(text: items[i].name, query: query),
                            const SizedBox(height: 2),
                            Text(
                              'Centre ${items[i].centre} · ${items[i].cand}',
                              style: TextStyle(fontSize: 11.5, color: c.text3),
                            ),
                          ],
                        ),
                      ),
                      FaIcon(FontAwesomeIcons.arrowRight, size: 12, color: c.text3),
                    ],
                  ),
                ),
              ),
            ),
            if (i < items.length - 1) Divider(height: 1, thickness: 1, color: c.border),
          ],
        ],
      ),
    );
  }
}

class _Highlighted extends StatelessWidget {
  const _Highlighted({required this.text, required this.query});

  final String text;
  final String query;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.text);
    final start = text.toLowerCase().indexOf(query.toLowerCase());
    if (query.isEmpty || start < 0) return Text(text, style: base);
    final end = start + query.length;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: TextStyle(fontWeight: FontWeight.w800, color: c.primary, backgroundColor: c.primarySoft),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
      style: base,
    );
  }
}

class _StreamChip extends StatelessWidget {
  const _StreamChip({required this.stream, required this.active, required this.onTap});

  final ExamStream stream;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      selected: active,
      child: Pressable(
        onTap: onTap,
        scale: 0.95,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? c.primary : c.surface,
            border: Border.all(color: active ? c.primary : c.border, width: 1.5),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: active
                ? [BoxShadow(color: c.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(stream.icon, size: 11, color: active ? Colors.white : c.text2),
              const SizedBox(width: 6),
              Text(
                stream.id,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? Colors.white : c.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
