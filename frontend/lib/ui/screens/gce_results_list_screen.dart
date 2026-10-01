import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/l10n.dart';
import '../../core/nav.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'results_reader_screen.dart';

class GceResultsListScreen extends StatelessWidget {
  const GceResultsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final pdfs = context.watch<AppState>().resultPdfs ?? const [];

    return Scaffold(
      backgroundColor: c.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: c.surface,
            foregroundColor: c.text,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 54, bottom: 16),
              title: Text(
                context.tr('Official Results', 'Résultats Officiels'),
                style: TextStyle(
                  color: c.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: c.primary.withValues(alpha: 0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FaIcon(FontAwesomeIcons.circleInfo, size: 20, color: c.primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('How to check your results', 'Comment consulter vos résultats'),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: c.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr(
                              'Tap your exam category below to open the official list. Use the built-in search (magnifying glass) and type your name exactly as registered to jump straight to your results and see the number of papers passed.',
                              'Appuyez sur votre catégorie d\'examen ci-dessous pour ouvrir la liste officielle. Utilisez la recherche intégrée (loupe) et tapez votre nom tel qu\'il est inscrit pour accéder directement à vos résultats et voir le nombre de matières validées.',
                            ),
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.4,
                              color: c.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (pdfs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  context.tr('No results available yet.', 'Aucun résultat disponible pour le moment.'),
                  style: TextStyle(color: c.text3, fontSize: 16),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pdf = pdfs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PdfCard(pdf: pdf),
                    );
                  },
                  childCount: pdfs.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PdfCard extends StatelessWidget {
  const _PdfCard({required this.pdf});

  final ResultsPdf pdf;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      child: InkWell(
        onTap: () => context.push(ResultsReaderScreen(pdf: pdf)),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                color: c.accent,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: c.dangerSoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: FaIcon(
                          FontAwesomeIcons.solidFilePdf,
                          color: c.danger,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr(pdf.titleEn, pdf.titleFr),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: c.text,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                FaIcon(FontAwesomeIcons.calendar, size: 12, color: c.text3),
                                const SizedBox(width: 5),
                                Text(
                                  context.tr('${pdf.session} Session', 'Session ${pdf.session}'),
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.text2),
                                ),
                                const SizedBox(width: 14),
                                FaIcon(FontAwesomeIcons.fileLines, size: 12, color: c.text3),
                                const SizedBox(width: 5),
                                Text(
                                  context.tr('${pdf.pages} pages', '${pdf.pages} pages'),
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: c.text2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: c.bg,
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(FontAwesomeIcons.arrowRight, size: 14, color: c.text),
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
