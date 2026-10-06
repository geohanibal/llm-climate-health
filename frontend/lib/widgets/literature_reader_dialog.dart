/// In-app academic reader dialog for viewing complete scientific literature digests,
/// methodology, epidemiological thresholds, and full citations directly on the platform.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization.dart';
import '../models/literature_item.dart';
import '../services/browser_download_service.dart';
import '../services/literature_pdf_service.dart';

class LiteratureReaderDialog extends StatefulWidget {
  final LiteratureItem item;

  const LiteratureReaderDialog({
    super.key,
    required this.item,
  });

  static Future<void> show(BuildContext context, LiteratureItem item) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LiteratureReaderDialog(item: item),
    );
  }

  @override
  State<LiteratureReaderDialog> createState() => _LiteratureReaderDialogState();
}

class _LiteratureReaderDialogState extends State<LiteratureReaderDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LiteraturePdfService _pdfService = const LiteraturePdfService();
  final BrowserDownloadService _downloadService = const BrowserDownloadService();
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleDownloadPdf(AppLanguage lang) async {
    setState(() => _isDownloadingPdf = true);
    try {
      await _pdfService.downloadLiteraturePdf(item: widget.item, lang: lang);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang == AppLanguage.ka
                  ? 'PDF დაიჯესტი გადმოწერილია!'
                  : lang == AppLanguage.de
                      ? 'PDF-Zusammenfassung heruntergeladen!'
                      : 'PDF digest downloaded successfully!',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = I18n.currentLanguage;
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = size.width > 960 ? 920.0 : size.width * 0.96;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: size.height * 0.92,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(context, colorScheme, lang),
            const Divider(height: 1),

            // Tab bar
            TabBar(
              controller: _tabController,
              isScrollable: size.width < 600,
              tabs: [
                Tab(
                  icon: const Icon(Icons.description_outlined, size: 18),
                  text: I18n.t('abstractTab'),
                ),
                Tab(
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  text: I18n.t('methodologyTab'),
                ),
                Tab(
                  icon: const Icon(Icons.biotech_outlined, size: 18),
                  text: I18n.t('keyFindingsTab'),
                ),
                Tab(
                  icon: const Icon(Icons.format_quote_outlined, size: 18),
                  text: I18n.t('citationTab'),
                ),
              ],
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAbstractTab(context, colorScheme, lang),
                  _buildMethodologyTab(context, colorScheme, lang),
                  _buildKeyFindingsTab(context, colorScheme, lang),
                  _buildCitationTab(context, colorScheme, lang),
                ],
              ),
            ),

            // Footer
            const Divider(height: 1),
            _buildFooter(context, colorScheme, lang),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, AppLanguage lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.item.icon, color: colorScheme.onPrimaryContainer, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.item.tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    if (widget.item.isCustom) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          I18n.t('customBadge'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.item.authors} • ${widget.item.journal} (${widget.item.year})',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: I18n.t('close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildAbstractTab(BuildContext context, ColorScheme colorScheme, AppLanguage lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            title: lang == AppLanguage.ka
                ? 'სამეცნიერო რეზიუმე (Abstract)'
                : lang == AppLanguage.de
                    ? 'Wissenschaftliches Abstract'
                    : 'Scientific Abstract',
            icon: Icons.article_outlined,
            colorScheme: colorScheme,
            content: widget.item.getAbstract(lang),
          ),
          const SizedBox(height: 18),
          _buildInfoSection(
            title: lang == AppLanguage.ka
                ? 'კვლევის ძირითადი ფოკუსი'
                : lang == AppLanguage.de
                    ? 'Hauptfokus der Studie'
                    : 'Primary Research Focus',
            icon: Icons.track_changes_outlined,
            colorScheme: colorScheme,
            content: widget.item.getFocus(lang),
          ),
          const SizedBox(height: 18),
          _buildInfoSection(
            title: lang == AppLanguage.ka
                ? 'როლი ანალიზში და გამორჩეული ნიშნები'
                : lang == AppLanguage.de
                    ? 'Rolle bei der Analyse & Besonderheiten'
                    : 'Role in Integration & Distinct Features',
            icon: Icons.lightbulb_outline,
            colorScheme: colorScheme,
            content: widget.item.getDifferences(lang),
          ),
          if (widget.item.fullContent != null && widget.item.fullContent!.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildInfoSection(
              title: lang == AppLanguage.ka
                  ? 'ატვირთული შინაარსი / დამატებითი ტექსტი'
                  : lang == AppLanguage.de
                      ? 'Angefügter Inhalt / Volltext'
                      : 'Attached Content / Full Notes',
              icon: Icons.attachment_outlined,
              colorScheme: colorScheme,
              content: widget.item.fullContent!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMethodologyTab(BuildContext context, ColorScheme colorScheme, AppLanguage lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            title: lang == AppLanguage.ka
                ? 'კვლევის მეთოდოლოგია და მონაცემთა წყაროები'
                : lang == AppLanguage.de
                    ? 'Methodik und Datenquellen'
                    : 'Methodology & Data Sources',
            icon: Icons.psychology_outlined,
            colorScheme: colorScheme,
            content: widget.item.getMethodology(lang),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.hub_outlined, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      lang == AppLanguage.ka
                          ? 'როგორ იყენებს ამას Climate-Health პლატფორმა?'
                          : lang == AppLanguage.de
                              ? 'Wie die Plattform diese Methodik nutzt'
                              : 'How the Platform Applies this Methodology',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lang == AppLanguage.ka
                      ? 'პლატფორმის ETL მილსადენი და სტატისტიკური ანალიზი ამ მეთოდოლოგიის საფუძველზე აკავშირებს ERA5 კლიმატურ რეანალიზსა და ეპიდემიოლოგიურ შემთხვევებს, ხოლო AI Copilot პასუხების გენერირებისას იყენებს ამავე სტანდარტებს.'
                      : lang == AppLanguage.de
                          ? 'Die ETL-Pipeline und statistische Analyse verknüpfen ERA5-Klimadaten und Falldaten nach diesen Methoden. Der KI-Copilot stützt seine Antworten auf diese Standards.'
                          : 'The platform ETL pipeline and statistical engine link ERA5 climate variables with case records under these principles, while the AI Copilot aligns its interpretations with these benchmarks.',
                  style: const TextStyle(fontSize: 12.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyFindingsTab(BuildContext context, ColorScheme colorScheme, AppLanguage lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            title: lang == AppLanguage.ka
                ? 'ძირითადი მიგნებები და ეპიდემიოლოგიური ზღვრები'
                : lang == AppLanguage.de
                    ? 'Wichtigste Erkenntnisse & Schwellenwerte'
                    : 'Key Epidemiological Findings & Thresholds',
            icon: Icons.insights_outlined,
            colorScheme: colorScheme,
            content: widget.item.getKeyFindings(lang),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.timer_outlined, size: 22, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == AppLanguage.ka
                            ? 'დროითი დაყოვნება (Lagged Cross-Correlation)'
                            : lang == AppLanguage.de
                                ? 'Zeitverzögerte Korrelation (Lags 1-3 Monate)'
                                : 'Biological Transmission Lags (1–3 Months)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lang == AppLanguage.ka
                            ? 'ლიტერატურა ერთსულოვნად ადასტურებს: ტემპერატურისა და ნალექის ცვლილება მყისიერად არ იწვევს დაავადების პიკს. საჭიროა 1-3 თვიანი ბიოლოგიური დაყოვნება ლარვის განვითარებისა და ექსტრისული ინკუბაციისთვის.'
                            : lang == AppLanguage.de
                                ? 'Die Literatur bestätigt einstimmig: Temperatur- und Niederschlagsänderungen führen nicht sofort zu Spitzen. Es bedarf 1-3 Monate biologischer Verzögerung.'
                                : 'Peer-reviewed evidence validates that meteorological anomalies do not cause instant caseload spikes; 1–3 months of biological delay are required for larval breeding and extrinsic incubation.',
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCitationTab(BuildContext context, ColorScheme colorScheme, AppLanguage lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'APA Citation',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _copyToClipboard(
                  widget.item.citation,
                  I18n.t('citationCopied'),
                ),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: Text(I18n.t('copyCitation')),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: SelectableText(
              widget.item.citation,
              style: const TextStyle(fontSize: 13, height: 1.5, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BibTeX Entry',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _copyToClipboard(
                  widget.item.getBibTeX(),
                  I18n.t('citationCopied'),
                ),
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: Text(I18n.t('copyCitation')),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: SelectableText(
              widget.item.getBibTeX(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.45,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required ColorScheme colorScheme,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            content,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme colorScheme, AppLanguage lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: _isDownloadingPdf ? null : () => _handleDownloadPdf(lang),
                icon: _isDownloadingPdf
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: Text(I18n.t('downloadLiteraturePdf')),
                style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              if (widget.item.url != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _downloadService.openUrl(widget.item.url!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(I18n.t('officialSource')),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ],
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(I18n.t('close')),
          ),
        ],
      ),
    );
  }
}
