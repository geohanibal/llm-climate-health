/// Scientific Literature & Knowledge Base dialog for the Climate-Health Platform.
/// Displays the peer-reviewed scientific corpora used for grounding AI analysis,
/// explains In-Context Grounding vs. AI Training, allows switching the active corpus,
/// adding custom literature, viewing full in-app digests, downloading PDFs, and
/// comparing differences in the AI Copilot.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
library;

import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../models/literature_item.dart';
import '../services/browser_download_service.dart';
import '../services/literature_pdf_service.dart';
import 'add_literature_dialog.dart';
import 'literature_reader_dialog.dart';

class LiteratureKnowledgeDialog extends StatefulWidget {
  final ValueChanged<String>? onCompareInChat;

  const LiteratureKnowledgeDialog({
    super.key,
    this.onCompareInChat,
  });

  static Future<void> show(
    BuildContext context, {
    ValueChanged<String>? onCompareInChat,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LiteratureKnowledgeDialog(
        onCompareInChat: onCompareInChat,
      ),
    );
  }

  @override
  State<LiteratureKnowledgeDialog> createState() => _LiteratureKnowledgeDialogState();
}

class _LiteratureKnowledgeDialogState extends State<LiteratureKnowledgeDialog> {
  late LiteratureCorpus _selectedCorpus;
  final LiteraturePdfService _pdfService = const LiteraturePdfService();
  final BrowserDownloadService _downloadService = const BrowserDownloadService();
  final CustomLiteratureStore _customStore = CustomLiteratureStore.instance;

  @override
  void initState() {
    super.initState();
    _selectedCorpus = activeLiterature.value;
    _customStore.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _customStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  void _applyCorpus(LiteratureCorpus corpus, {String? customTitle, String? customSummary}) {
    setState(() => _selectedCorpus = corpus);
    activeLiterature.setCorpus(corpus, customTitle: customTitle, customSummary: customSummary);
  }

  void _applyItem(LiteratureItem item) {
    if (item.isCustom) {
      _applyCorpus(
        LiteratureCorpus.custom,
        customTitle: item.title,
        customSummary: item.focusEn.isNotEmpty ? item.focusEn : item.focusKa,
      );
    } else {
      _applyCorpus(item.corpus);
    }
  }

  Future<void> _openAddLiterature() async {
    final newItem = await AddLiteratureDialog.show(context);
    if (newItem != null && mounted) {
      _applyItem(newItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(I18n.t('literatureAddedSuccess')),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _downloadItemPdf(LiteratureItem item, AppLanguage lang) async {
    try {
      await _pdfService.downloadLiteraturePdf(item: item, lang: lang);
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
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _confirmDeleteCustomItem(LiteratureItem item) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(I18n.t('deleteLiterature')),
        content: Text('${item.title} - ${I18n.t('deleteLiterature')}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(I18n.t('close')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(I18n.t('deleteLiterature')),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        _customStore.removeCustomItem(item.id);
        if (_selectedCorpus == LiteratureCorpus.custom) {
          _applyCorpus(LiteratureCorpus.all);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = I18n.currentLanguage;
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = size.width > 920 ? 880.0 : size.width * 0.95;

    final allItems = [...kScientificCorpora, ..._customStore.customItems];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: size.height * 0.90,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(context, colorScheme),
            const Divider(height: 1),

            // Content scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Callout: Is this AI Training?
                    _buildTrainingExplanationCard(context, colorScheme),
                    const SizedBox(height: 20),

                    // Active corpus selection banner
                    _buildCorpusSelector(context, colorScheme, lang),
                    const SizedBox(height: 24),

                    // Section: Literature Corpora Cards Header with Add Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.library_books_outlined, size: 20, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  I18n.t('literatureKnowledge'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _openAddLiterature,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(I18n.t('addLiterature')),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    ...allItems.map((item) => _buildCorpusCard(context, item, lang)),

                    const SizedBox(height: 20),
                    // Section: Differences explanation
                    _buildDifferencesSection(context, colorScheme),
                  ],
                ),
              ),
            ),

            // Footer actions
            const Divider(height: 1),
            _buildFooter(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.menu_book_rounded, color: colorScheme.onPrimaryContainer, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  I18n.t('literatureKnowledge'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  I18n.t('literatureDialogSubtitle'),
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

  Widget _buildTrainingExplanationCard(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.school_rounded, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  I18n.t('literatureIsTrainingTitle'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  I18n.t('literatureIsTrainingAnswer'),
                  style: const TextStyle(fontSize: 13, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorpusSelector(BuildContext context, ColorScheme colorScheme, AppLanguage lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 18, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                I18n.t('literatureActiveCorpus'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LiteratureCorpus.values.map((corpus) {
              final isSelected = _selectedCorpus == corpus;
              return ChoiceChip(
                label: Text(corpus.getLocalizedLabel(lang)),
                selected: isSelected,
                selectedColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colorScheme.onPrimaryContainer : Colors.white70,
                ),
                onSelected: (_) => _applyCorpus(corpus),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCorpusCard(BuildContext context, LiteratureItem item, AppLanguage lang) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = (_selectedCorpus == item.corpus) ||
        (item.isCustom && _selectedCorpus == LiteratureCorpus.custom);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primaryContainer.withOpacity(0.12)
            : colorScheme.surfaceContainerHighest.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? colorScheme.primary : Colors.white10,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(item.icon, size: 22, color: isSelected ? colorScheme.primary : Colors.grey[400]),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        if (item.isCustom) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              I18n.t('customBadge'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check, size: 12, color: Colors.black),
                                const SizedBox(width: 4),
                                Text(
                                  I18n.currentLanguage == AppLanguage.ka
                                      ? 'აქტიური'
                                      : I18n.currentLanguage == AppLanguage.de
                                          ? 'Aktiv'
                                          : 'Active',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (item.isCustom)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                            tooltip: I18n.t('deleteLiterature'),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _confirmDeleteCustomItem(item),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${item.authors} • ${item.journal} (${item.year})',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎯 ${item.getFocus(lang)}',
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
                const SizedBox(height: 4),
                Text(
                  '💡 ${item.getDifferences(lang)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[300], height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.citation,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Actions Toolbar
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Read Full Text / Details button
              OutlinedButton.icon(
                onPressed: () => LiteratureReaderDialog.show(context, item),
                icon: const Icon(Icons.menu_book_rounded, size: 14),
                label: Text(I18n.t('readFullLiterature')),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              // Download PDF Digest button
              OutlinedButton.icon(
                onPressed: () => _downloadItemPdf(item, lang),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                label: Text(I18n.t('downloadLiteraturePdf')),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              // External Official Publication link if available
              if (item.url != null)
                TextButton.icon(
                  onPressed: () => _downloadService.openUrl(item.url!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: Text(I18n.t('officialSource')),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                ),
              // Select button
              FilledButton.tonal(
                onPressed: () => _applyItem(item),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: Text(
                  isSelected
                      ? (lang == AppLanguage.ka ? 'არჩეულია' : lang == AppLanguage.de ? 'Ausgewählt' : 'Selected')
                      : (lang == AppLanguage.ka ? 'არჩევა' : lang == AppLanguage.de ? 'Wählen' : 'Select'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifferencesSection(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                I18n.t('literatureDifferencesTitle'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            I18n.t('literatureDifferencesText'),
            style: const TextStyle(fontSize: 12.5, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ColorScheme colorScheme) {
    final lang = I18n.currentLanguage;
    final comparePrompt = lang == AppLanguage.ka
        ? "შედარება გამიკეთე: რა განსხვავებებია WHO-ს, Lancet-სა და IPCC-ს ლიტერატურას შორის კლიმატისა და დაავადებების ანალიზში?"
        : lang == AppLanguage.de
            ? "Vergleiche die Unterschiede zwischen WHO-, Lancet- und IPCC-Literatur bei der Klima- und Gesundheitsanalyse."
            : "Compare the differences between WHO, Lancet, and IPCC literature in climate and health epidemiology analysis.";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              if (widget.onCompareInChat != null) {
                widget.onCompareInChat!(comparePrompt);
              }
            },
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: Text(I18n.t('compareLiteratureInChat')),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: Text(I18n.t('close')),
          ),
        ],
      ),
    );
  }
}
