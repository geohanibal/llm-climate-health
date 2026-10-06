/// Scientific Literature & Knowledge Base dialog for the Climate-Health Platform.
/// Displays the peer-reviewed scientific corpora used for grounding AI analysis,
/// explains In-Context Grounding vs. AI Training, allows switching the active corpus,
/// and provides comparison shortcuts for the AI Copilot.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
library;

import 'package:flutter/material.dart';

import '../core/localization.dart';

class LiteratureItem {
  final LiteratureCorpus corpus;
  final String tag;
  final String title;
  final String authors;
  final String year;
  final String journal;
  final String citation;
  final String focusKa;
  final String focusEn;
  final String focusDe;
  final String differencesKa;
  final String differencesEn;
  final String differencesDe;
  final IconData icon;

  const LiteratureItem({
    required this.corpus,
    required this.tag,
    required this.title,
    required this.authors,
    required this.year,
    required this.journal,
    required this.citation,
    required this.focusKa,
    required this.focusEn,
    required this.focusDe,
    required this.differencesKa,
    required this.differencesEn,
    required this.differencesDe,
    required this.icon,
  });

  String getFocus(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ka:
        return focusKa;
      case AppLanguage.de:
        return focusDe;
      case AppLanguage.en:
        return focusEn;
    }
  }

  String getDifferences(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ka:
        return differencesKa;
      case AppLanguage.de:
        return differencesDe;
      case AppLanguage.en:
        return differencesEn;
    }
  }
}

final List<LiteratureItem> kScientificCorpora = [
  const LiteratureItem(
    corpus: LiteratureCorpus.who,
    tag: 'WHO 2020 / 2024',
    title: 'Global Vector Control Response & Epidemic Preparedness',
    authors: 'World Health Organization (WHO)',
    year: '2020',
    journal: 'WHO Technical Report Series & Guidelines',
    citation:
        'World Health Organization. (2020). Global vector control response 2017–2030. WHO Guidelines Approved by the Guidelines Review Committee.',
    focusKa:
        'კლინიკური მეთვალყურეობა, ეპიდემიოლოგიური ზღვრები (outbreak alert thresholds) და გადაუდებელი ვექტორული ინტერვენციები.',
    focusEn:
        'Clinical disease surveillance, epidemiological outbreak alert thresholds, and immediate vector control interventions.',
    focusDe:
        'Klinische Krankheitsüberwachung, epidemiologische Ausbruchsschwellenwerte und sofortige Vektorkontrollmaßnahmen.',
    differencesKa:
        'აქცენტი კეთდება რეალურ-დროის შემთხვევების რეგისტრაციაზე, საზოგადოებრივი ჯანდაცვის რეაგირებაზე და ლოკალურ ზღვრულ მაჩვენებლებზე.',
    differencesEn:
        'Emphasizes operational public health actions, case reporting protocols, and immediate larval reduction rather than climate projections.',
    differencesDe:
        'Konzentriert sich auf operative Maßnahmen des öffentlichen Gesundheitswesens und Meldeschwellen anstelle von Klimaprojektionen.',
    icon: Icons.local_hospital_outlined,
  ),
  const LiteratureItem(
    corpus: LiteratureCorpus.lancet,
    tag: 'The Lancet 2023',
    title: 'The 2023 Report of the Lancet Countdown on Health and Climate Change',
    authors: 'Romanello, M., Di Napoli, C., Drummond, P., et al.',
    year: '2023',
    journal: 'The Lancet, 402(10419), 2346-2394',
    citation:
        'Romanello, M., et al. (2023). The 2023 report of the Lancet Countdown on health and climate change: the imperative for a health-centred response. The Lancet, 402(10419), 2346-2394.',
    focusKa:
        'კლიმატის ცვლილების ატრიბუცია, დაავადების გადაცემის ეკოლოგიური ხელსაყრელობის (R0) ზრდა და მოსახლეობის მოწყვლადობა.',
    focusEn:
        'Climate change attribution, shifts in environmental transmission suitability (R0), and population exposure metrics.',
    focusDe:
        'Klimawandel-Attribution, Veränderungen der Umweltübertragungseignung (R0) und Exposition der Bevölkerung.',
    differencesKa:
        'ფოკუსირებულია გლობალურ და რეგიონულ ტენდენციებზე, ტემპერატურისა და ნალექების ცვლილების გავლენაზე გადამტანების გავრცელების არეალზე.',
    differencesEn:
        'Focuses on macro-level climate attribution, quantifying how anthropogenic global warming increases transmission suitability.',
    differencesDe:
        'Fokussiert auf Makro-Klimaattribution und quantifiziert, wie die Erwärmung die Übertragungseignung global erhöht.',
    icon: Icons.public_outlined,
  ),
  const LiteratureItem(
    corpus: LiteratureCorpus.ipcc,
    tag: 'IPCC AR6 2022',
    title: 'Climate Change 2022: Impacts, Adaptation and Vulnerability (Chapter 7: Health)',
    authors: 'Intergovernmental Panel on Climate Change (IPCC WGII)',
    year: '2022',
    journal: 'Cambridge University Press',
    citation:
        'IPCC. (2022). Climate Change 2022: Impacts, Adaptation and Vulnerability. Contribution of Working Group II to the Sixth Assessment Report. Cambridge Univ. Press.',
    focusKa:
        'გრძელვადიანი კლიმატური პროექციები (2030–2100), ექსტრემალური ნალექები, წყალდიდობები და კომპლექსური რისკები (Compound hazards).',
    focusEn:
        'Multi-decadal climate projections (2030–2100), extreme rainfall events, floodings, and compound cascading health risks.',
    focusDe:
        'Mehrdekadische Klimaprojektionen (2030–2100), Starkregenereignisse, Überschwemmungen und kaskadierende Gesundheitsrisiken.',
    differencesKa:
        'იკვლევს მრავალათწლიან სცენარებს (SSPs) და ადაპტაციის პოლიტიკას, განსხვავებით ყოველთვიური ეპიდემიოლოგიური რყევებისგან.',
    differencesEn:
        'Evaluates multi-decadal Shared Socioeconomic Pathways (SSPs) and structural resilience rather than monthly surveillance cycles.',
    differencesDe:
        'Bewertet mehrdekadische sozioökonomische Pfade (SSPs) und Anpassungsresilienz anstelle monatlicher Überwachungszyklen.',
    icon: Icons.shield_outlined,
  ),
  const LiteratureItem(
    corpus: LiteratureCorpus.mordecai,
    tag: 'Ecology Letters 2019',
    title: 'Thermal Biology of Mosquito-Borne Disease',
    authors: 'Mordecai, E. A., Caldwell, J. M., Grossman, M. K., et al.',
    year: '2019',
    journal: 'Ecology Letters, 22(10), 1690-1708',
    citation:
        'Mordecai, E. A., et al. (2019). Thermal biology of mosquito-borne disease. Ecology Letters, 22(10), 1690-1708.',
    focusKa:
        'კოღოს თერმული ბიოლოგია, არაწრფივი ოპტიმალური ტემპერატურა (24°C–29°C) და 1–3 თვიანი ბიოლოგიური დროითი დაყოვნება (Lags).',
    focusEn:
        'Mosquito thermal biology, non-linear optimal temperature curves (24°C–29°C), and 1–3 month biological transmission lags.',
    focusDe:
        'Thermale Biologie von Stechmücken, nicht-lineare optimale Temperaturkurven (24°C–29°C) und 1–3 monatige biologische Verzögerungen (Lags).',
    differencesKa:
        'უზრუნველყოფს ფიზიოლოგიურ მტკიცებულებას იმისა, თუ რატომ მოქმედებს წვიმა და ტემპერატურა დაგვიანებით (Lag 1-3 თვე) დაავადების შემთხვევებზე.',
    differencesEn:
        'Provides mechanistic biological proof for why precipitation and warmth drive disease peaks after a 1–3 month lag (breeding cycle).',
    differencesDe:
        'Liefert den mechanistischen biologischen Beweis für zeitverzögerte Effekte (Lags 1–3 Monate) zwischen Niederschlag und Fallzahlen.',
    icon: Icons.biotech_outlined,
  ),
];

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

  @override
  void initState() {
    super.initState();
    _selectedCorpus = activeLiterature.value;
  }

  void _applyCorpus(LiteratureCorpus corpus) {
    setState(() => _selectedCorpus = corpus);
    activeLiterature.setCorpus(corpus);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = I18n.currentLanguage;
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = size.width > 900 ? 860.0 : size.width * 0.95;

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

                    // Section: Literature Corpora Cards
                    Row(
                      children: [
                        Icon(Icons.library_books_outlined, size: 20, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          I18n.t('literatureKnowledge'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...kScientificCorpora.map((item) => _buildCorpusCard(context, item, lang)),

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
    final isSelected = _selectedCorpus == item.corpus;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
              Icon(item.icon, size: 20, color: isSelected ? colorScheme.primary : Colors.grey[400]),
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
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${item.authors} • ${item.journal}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.citation,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _applyCorpus(item.corpus),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
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
