/// Trilingual localization engine for the Climate-Health Platform:
/// supports Georgian (ka), English (en), and German (de).
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
library;

import 'package:flutter/material.dart';

enum AppLanguage {
  ka('ka', 'ქართული', '🇬🇪'),
  en('en', 'English', '🇬🇧'),
  de('de', 'Deutsch', '🇩🇪');

  final String code;
  final String label;
  final String flag;

  const AppLanguage(this.code, this.label, this.flag);

  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.ka;
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code.toLowerCase(),
      orElse: () => AppLanguage.ka,
    );
  }
}

enum LiteratureCorpus {
  all('all', 'ყველა წყარო (სინთეზი)', 'All Sources (Synthesis)', 'Alle Quellen (Synthese)'),
  who('who', 'WHO Guidelines (ეპიდემიოლოგია & ვექტორები)', 'WHO Guidelines (Epidemiology & Vectors)', 'WHO-Richtlinien (Epidemiologie & Vektoren)'),
  lancet('lancet', 'Lancet Countdown (კლიმატის ცვლილება)', 'Lancet Countdown (Climate Change)', 'Lancet Countdown (Klimawandel)'),
  ipcc('ipcc', 'IPCC AR6 WGII (გრძელვადიანი რისკები)', 'IPCC AR6 WGII (Long-Term Risks)', 'IPCC AR6 WGII (Langzeitrisiken)'),
  mordecai('mordecai', 'Vector Thermal Biology (Mordecai et al.)', 'Vector Thermal Biology (Mordecai et al.)', 'Vektor-Thermalbiologie (Mordecai et al.)'),
  custom('custom', 'მორგებული ლიტერატურა (Custom)', 'Custom Literature', 'Eigene Literatur');

  final String id;
  final String labelKa;
  final String labelEn;
  final String labelDe;
  const LiteratureCorpus(this.id, this.labelKa, this.labelEn, this.labelDe);

  String getLocalizedLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ka:
        return labelKa;
      case AppLanguage.de:
        return labelDe;
      case AppLanguage.en:
        return labelEn;
    }
  }

  static LiteratureCorpus fromId(String? id) {
    if (id == null) return LiteratureCorpus.all;
    return LiteratureCorpus.values.firstWhere(
      (c) => c.id == id.toLowerCase(),
      orElse: () => LiteratureCorpus.all,
    );
  }
}

class AppLocaleController extends ValueNotifier<AppLanguage> {
  AppLocaleController([super.value = AppLanguage.ka]);

  void setLanguage(AppLanguage language) {
    if (value != language) {
      value = language;
    }
  }
}

class LiteratureController extends ValueNotifier<LiteratureCorpus> {
  LiteratureController([super.value = LiteratureCorpus.all]);

  String? customLiteratureTitle;
  String? customLiteratureSummary;

  void setCorpus(LiteratureCorpus corpus, {String? customTitle, String? customSummary}) {
    customLiteratureTitle = customTitle;
    customLiteratureSummary = customSummary;
    if (value != corpus) {
      value = corpus;
    } else {
      notifyListeners();
    }
  }
}

/// Global reactive locale controller for the platform.
final appLocale = AppLocaleController(AppLanguage.ka);

/// Global reactive active literature controller for the platform.
final activeLiterature = LiteratureController(LiteratureCorpus.all);

class I18n {
  const I18n._();

  static AppLanguage get currentLanguage => appLocale.value;

  static String t(String key, {AppLanguage? lang}) {
    final active = lang ?? currentLanguage;
    final dict = _translations[active];
    if (dict != null && dict.containsKey(key)) {
      return dict[key]!;
    }
    // Fallback to English, then key itself
    return _translations[AppLanguage.en]?[key] ?? key;
  }

  static const Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.ka: {
      // General & Header
      'platformTitle': 'Climate-Health Platform',
      'appBarTitle': 'Climate-Health Data Integration Platform',
      'heroTitle': 'Climate-Health Data Integration Platform',
      'heroSubtitle':
          'მიუთითეთ დაავადება და რეგიონი — ან პირდაპირ შეავსეთ ფორმა — და მიიღეთ კლიმატისა და ჯანდაცვის მონაცემთა ჰარმონიზებული, ანალიზისთვის მზა ბაზა, მარტივი ენით ახსნილი.',
      'aiCopilot': 'AI Copilot',
      'close': 'დახურვა',
      'openCopilot': 'Climate-Health Copilot',
      'language': 'ენა',

      // Literature Knowledge Base
      'literature': 'სამეცნიერო ლიტერატურა',
      'literatureShort': 'ლიტერატურა',
      'literatureKnowledge': 'სამეცნიერო ლიტერატურა & ცოდნის ბაზა',
      'literatureDialogSubtitle': 'AI ანალიზის სამეცნიერო დასაყრდენი და ლიტერატურის წყაროების მართვა',
      'literatureIsTrainingTitle': 'არის თუ არა ეს AI-ის გაწვრთნა?',
      'literatureIsTrainingAnswer':
          'არა. ეს არის In-Context Grounding და Retrieval-Augmented Generation (RAG). AI მოდელის ნეირონული წონები (weights) რჩება უცვლელი. სისტემა რეალურ დროში ეყრდნობა ამ აკადემიურ წყაროებს, რათა თავიდან აიცილოს ჰალუცინაციები და უზრუნველყოს მკაცრი სამეცნიერო სისწორე.',
      'literatureActiveCorpus': 'აქტიური ლიტერატურა ანალიზისთვის:',
      'compareLiteratureInChat': 'შეადარე განსხვავებები AI ჩატში',
      'literatureSelected': 'ლიტერატურა არჩეულია:',
      'literatureDifferencesTitle': 'რა განსხვავებებია ამ ლიტერატურას შორის?',
      'literatureDifferencesText':
          '• WHO: აქცენტი კლინიკურ მეთვალყურეობაზე, ეპიდემიის ზღვრებსა და გადაუდებელ ვექტორულ კონტროლზე.\n• Lancet Countdown: გლობალური კლიმატის ცვლილების როლი, გადაცემის ხელსაყრელობა (R0) და მოსახლეობის მოწყვლადობა.\n• IPCC AR6: გრძელვადიანი კლიმატური სცენარები, ექსტრემალური ნალექები და კომპლექსური რისკები.\n• Mordecai et al.: კოღოს თერმული ბიოლოგია, ოპტიმალური ტემპერატურა (24-29°C) და 1-3 თვიანი დროითი დაყოვნება (Lags).',
      'addLiterature': 'ლიტერატურის დამატება',
      'addCustomLiterature': 'საკუთარი ლიტერატურის დამატება',
      'customLiteratureTitle': 'დაამატე ახალი სამეცნიერო წყარო',
      'customLiteratureSubtitle': 'მიუთითეთ კვლევის პარამეტრები ან ატვირთეთ დოკუმენტი AI ანალიზში ჩასართავად',
      'literatureTitleField': 'სათაური / Title',
      'literatureAuthorsField': 'ავტორები / ორგანიზაცია',
      'literatureYearField': 'გამოცემის წელი',
      'literatureJournalField': 'ჟურნალი / გამოცემა',
      'literatureUrlField': 'DOI ან ვებ/PDF ბმული (არასავალდებულო)',
      'literatureFocusField': 'კვლევის ფოკუსი და რეზიუმე (Abstract)',
      'literatureDifferencesField': 'როლი ანალიზში და განსხვავება (Relevance / Differences)',
      'attachFile': 'ფაილის მიბმა (.pdf / .txt / .md)',
      'fileAttached': 'მიბმული ფაილი:',
      'saveLiterature': 'ლიტერატურის შენახვა',
      'downloadLiteraturePdf': 'PDF გადმოწერა',
      'downloadFullBook': 'მთლიანი წიგნი / PDF',
      'downloadSummaryDigest': 'მოკლე დაიჯესტი (PDF)',
      'readFullLiterature': 'სრული შინაარსი & დეტალები',
      'officialSource': 'ორიგინალი წყარო',
      'deleteLiterature': 'წაშლა',
      'customBadge': 'მორგებული',
      'copyCitation': 'ციტირების კოპირება',
      'citationCopied': 'ციტირება დაკოპირდა ბუფერში!',
      'literatureAddedSuccess': 'ახალი ლიტერატურა წარმატებით დაემატა!',
      'abstractTab': 'მიმოხილვა & ფოკუსი',
      'methodologyTab': 'მეთოდოლოგია & მონაცემები',
      'keyFindingsTab': 'ძირითადი მიგნებები & ზღვრები',
      'citationTab': 'აკადემიური ციტირება',
      'activeLiteratureBadge': 'ლიტერატურა',
      'runSearchNow': 'ძებნის გაშვება',
      'runSearchDirectly': 'ძებნის დაწყება',
      'aiExtractButton': 'AI ამოკითხვა',
      'aiExtracting': 'AI აანალიზებს დოკუმენტს / ბმულს...',
      'aiExtractSuccess': 'მონაცემები ავტომატურად შეივსო AI-ის მიერ!',
      'aiOverwritePromptTitle': 'ჩავანაცვლოთ შევსებული მონაცემები AI ვერსიით?',
      'aiOverwritePromptBody':
          'თქვენ უკვე გაქვთ შევსებული ველები. გსურთ ჩაანაცვლოთ თქვენი მონაცემები AI-ის მიერ ამოკითხული ვერსიით, თუ დატოვოთ თქვენი შევსებული?',
      'aiOverwriteAccept': 'AI ვერსიით ჩანაცვლება',
      'aiOverwriteKeepMine': 'ჩემი ვერსიის დატოვება',
      'aiExtractPreviewTitle': 'AI-ის მიერ ამოკითხული ვერსია',
      'aiExtractError': 'AI ამოკითხვა ვერ მოხერხდა: ',
      'aiExtractHint':
          'მიუთითეთ ბმული ან ატვირთეთ PDF და AI ავტომატურად ამოიკითხავს სათაურს, ავტორებს, წელს და რეზიუმეს.',

      // Natural language card
      'naturalLanguageTitle': 'მოითხოვეთ ბუნებრივი ენით',
      'naturalLanguageSubtitle': 'ჩაწერეთ თავისუფალი ტექსტით და Gemini LLM ავტომატურად შეავსებს ფორმას',
      'naturalLanguageHint': 'მაგ. „დენგე ტაილანდში 2018-დან 2022 წლამდე ტემპერატურით და ნალექით“',
      'fillForm': 'ფორმის შევსება',
      'parsing': 'მუშავდება…',

      // Request form
      'requestFormTitle': 'მოთხოვნის პარამეტრები',
      'disease': 'დაავადება',
      'region': 'რეგიონი',
      'pickOnMap': 'რუკაზე არჩევა',
      'climateVariables': 'კლიმატური ცვლადები',
      'temperature': 'ტემპერატურა',
      'precipitation': 'ნალექი',
      'dateRange': 'პერიოდი',
      'startDate': 'დაწყება',
      'endDate': 'დასრულება',
      'aggregation': 'დროითი გარჩევადობა',
      'climateSource': 'კლიმატის წყარო',
      'caseDataSource': 'ჯანდაცვის მონაცემთა წყარო',
      'populationSource': 'მოსახლეობის წყარო',
      'runIntegration': 'ინტეგრაციის გაშვება',
      'runningIntegration': 'მონაცემები მუშავდება…',

      // Actions & Copilot Drawer
      'suggestedParamsTitle': 'შემოთავაზებული პარამეტრები',
      'applyAndSearch': 'ძებნის დაწყება',
      'applyToForm': 'მხოლოდ შევსება',
      'newSearch': 'ახალი ძიება',
      'deepAnalysis': 'დეტალური ანალიზი',
      'pdfReport': 'PDF რეპორტი',
      'quickActions': 'სწრაფი მოქმედებები:',
      'activeData': 'აქტიური მონაცემები',
      'searchingInProgress': 'მიმდინარეობს ძებნა და ინტეგრაცია...',
      'searchSuccess': 'ძებნა და ინტეგრაცია წარმატებით დასრულდა!',
      'keyResults': 'ძირითადი შედეგები',
      'totalReportedCases': 'სულ დაფიქსირებული შემთხვევები',
      'peakPeriod': 'პიკური პერიოდი',
      'meanClimate': 'საშუალო კლიმატი',
      'laggedCorrelations': 'კლიმატის კორელაციები (Lagged Cross-Correlation)',
      'scientificSummary': 'სამეცნიერო შეჯამება',
      'newSearchActivated': 'ახალი ძიების რეჟიმი გააქტიურებულია.',
      'whatToExplore': 'რომელი დაავადებისა და რეგიონის გამოკვლევა გსურთ?',
      'suggestedQuestions': 'სავარაუდო კითხვები:',
      'collapse': 'აკეცვა',
      'showAllPrompts': 'ყველა კითხვა',
      'askQuestion': 'დასვით შეკითხვა (ქართულად, English, Deutsch)...',
      'clearChat': 'საუბრის გასუფთავება',
      'expandChat': 'გადიდება',
      'standardWidth': 'სტანდარტული ზომა',

      // Results view
      'integratedDataset': 'ინტეგრირებული მონაცემთა ბაზა',
      'downloadReportPdf': 'სრული რეპორტის გადმოწერა (PDF)',
      'sources': 'სამეცნიერო წყაროები',
      'pipelineSteps': 'ინტეგრაციის ეტაპები',
      'explanation': 'სამეცნიერო განმარტება',
      'statisticalSummary': 'სტატისტიკური ანალიზი',
      'dataAudit': 'მონაცემთა აუდიტი',

      // Demographic & Population search and upload
      'searchPopulationTitle': 'დემოგრაფიული მონაცემების მოძიება',
      'searchPopulationHint': 'მოძებნეთ ინდიკატორი (მაგ. urban, rural, 65, density)...',
      'searchPopulationOnline': 'ინტერნეტში მოძებნა',
      'uploadPopulationCsv': 'მოსახლეობის CSV ატვირთვა',
      'customPopulationUrl': 'მორგებული დემოგრაფიული URL',
      'customPopulationUrlHint': 'https://example.org/population_data.csv',
      'noPopulationSourcesFound': 'დემოგრაფიული წყაროები ვერ მოიძებნა. სცადეთ საკუთარი CSV ან URL.',
      'searchFailed': 'ძიება ვერ მოხერხდა',
      'useThis': 'არჩევა',
      'cancel': 'გაუქმება',
      'search': 'ძებნა',
      'change': 'შეცვლა',
      'dailyDownscalingWarningTitle': 'შენიშვნა დღიურ გარჩევადობაზე:',
      'dailyDownscalingWarningBody':
          'ჯანდაცვის ორიგინალი მონაცემი რეგისტრირებულია წლიურ ან თვიურ დონეზე. დღიურ რეჟიმში სისტემა იყენებს მასის შემნახველ გლუვ ინტერპოლაციას (Temporal Downscaling). ავთენტური დღიური ცვალებადობისთვის რეკომენდებულია დღიური CSV ფაილის ატვირთვა.',
    },

    AppLanguage.en: {
      // General & Header
      'platformTitle': 'Climate-Health Platform',
      'appBarTitle': 'Climate-Health Data Integration Platform',
      'heroTitle': 'Climate-Health Data Integration Platform',
      'heroSubtitle':
          'Describe a disease and region — or fill in the form directly — and get a harmonized, analysis-ready dataset joining climate and health data, explained in plain language.',
      'aiCopilot': 'AI Copilot',
      'close': 'Close',
      'openCopilot': 'Climate-Health Copilot',
      'language': 'Language',

      // Literature Knowledge Base
      'literature': 'Scientific Literature',
      'literatureShort': 'Literature',
      'literatureKnowledge': 'Scientific Literature & Knowledge Base',
      'literatureDialogSubtitle': 'Scientific grounding for AI analysis and literature corpus management',
      'literatureIsTrainingTitle': 'Is this AI model training?',
      'literatureIsTrainingAnswer':
          'No. This is In-Context Grounding and Retrieval-Augmented Generation (RAG). The neural network weights remain completely unchanged. The system references these verified academic sources in real-time to prevent hallucinations and ensure rigorous scientific accuracy.',
      'literatureActiveCorpus': 'Active literature for analysis:',
      'compareLiteratureInChat': 'Compare differences in AI Copilot',
      'literatureSelected': 'Selected literature:',
      'literatureDifferencesTitle': 'What are the key differences between these sources?',
      'literatureDifferencesText':
          '• WHO: Focuses on clinical surveillance, outbreak alert thresholds, and urgent vector control.\n• Lancet Countdown: Focuses on macro-climate attribution, transmission suitability (R0), and vulnerability metrics.\n• IPCC AR6: Focuses on multi-decadal climate scenarios, extreme precipitation, and compound risks.\n• Mordecai et al.: Focuses on mosquito thermal biology, optimal temperature curves (24-29°C), and 1-3 month biological lags.',
      'addLiterature': 'Add Literature',
      'addCustomLiterature': 'Add Custom Scientific Literature',
      'customLiteratureTitle': 'Add New Scientific Source',
      'customLiteratureSubtitle': 'Specify study parameters or attach documents to ground AI analysis',
      'literatureTitleField': 'Title',
      'literatureAuthorsField': 'Authors / Organization',
      'literatureYearField': 'Year',
      'literatureJournalField': 'Journal / Publisher',
      'literatureUrlField': 'DOI or Web/PDF URL (optional)',
      'literatureFocusField': 'Research Focus & Abstract',
      'literatureDifferencesField': 'Relevance to Climate-Health & Methodology',
      'attachFile': 'Attach File (.pdf / .txt / .md)',
      'fileAttached': 'Attached file:',
      'saveLiterature': 'Save Literature',
      'downloadLiteraturePdf': 'Download PDF Digest',
      'downloadFullBook': 'Full Book / PDF',
      'downloadSummaryDigest': 'Summary Digest (PDF)',
      'readFullLiterature': 'Read Full Text & Details',
      'officialSource': 'Official Source / Paper',
      'deleteLiterature': 'Delete',
      'customBadge': 'Custom',
      'copyCitation': 'Copy Citation',
      'citationCopied': 'Citation copied to clipboard!',
      'literatureAddedSuccess': 'Custom literature added successfully!',
      'abstractTab': 'Abstract & Focus',
      'methodologyTab': 'Methodology & Data',
      'keyFindingsTab': 'Key Findings & Thresholds',
      'citationTab': 'Academic Citation',
      'activeLiteratureBadge': 'Literature',
      'runSearchNow': 'Run Search Now',
      'runSearchDirectly': 'Start Search',
      'aiExtractButton': 'AI Extract',
      'aiExtracting': 'AI is analyzing document / link...',
      'aiExtractSuccess': 'Metadata extracted and filled automatically by AI!',
      'aiOverwritePromptTitle': 'Replace filled fields with AI version?',
      'aiOverwritePromptBody':
          'You have already entered some information. Would you like to overwrite your fields with the AI-extracted version, or keep your own?',
      'aiOverwriteAccept': 'Replace with AI Version',
      'aiOverwriteKeepMine': 'Keep My Version',
      'aiExtractPreviewTitle': 'AI-Extracted Version',
      'aiExtractError': 'AI extraction failed: ',
      'aiExtractHint':
          'Provide a link or upload a PDF, and AI will automatically extract title, authors, year, and abstract.',

      // Natural language card
      'naturalLanguageTitle': 'Describe what you need in plain language',
      'naturalLanguageSubtitle': 'Type in free text and Gemini LLM will automatically populate the form',
      'naturalLanguageHint': 'e.g. "Dengue in Thailand from 2018 to 2022 with temperature and precipitation"',
      'fillForm': 'Fill in the form',
      'parsing': 'Parsing…',

      // Request form
      'requestFormTitle': 'Request parameters',
      'disease': 'Disease',
      'region': 'Region',
      'pickOnMap': 'Pick on map',
      'climateVariables': 'Climate variables',
      'temperature': 'Temperature',
      'precipitation': 'Precipitation',
      'dateRange': 'Date range',
      'startDate': 'Start',
      'endDate': 'End',
      'aggregation': 'Time resolution',
      'climateSource': 'Climate source',
      'caseDataSource': 'Case data source',
      'populationSource': 'Population source',
      'runIntegration': 'Run integration',
      'runningIntegration': 'Running integration…',

      // Actions & Copilot Drawer
      'suggestedParamsTitle': 'Suggested Query Parameters',
      'applyAndSearch': 'Apply & Search',
      'applyToForm': 'Apply to Form',
      'newSearch': 'New Search',
      'deepAnalysis': 'Deep Analysis',
      'pdfReport': 'PDF Report',
      'quickActions': 'Quick Actions:',
      'activeData': 'Active Data',
      'searchingInProgress': 'Running search and data integration...',
      'searchSuccess': 'Search and integration completed successfully!',
      'keyResults': 'Key Results',
      'totalReportedCases': 'Total reported cases',
      'peakPeriod': 'Peak outbreak period',
      'meanClimate': 'Mean climate',
      'laggedCorrelations': 'Climate Correlations (Lagged Cross-Correlation)',
      'scientificSummary': 'Scientific Summary',
      'newSearchActivated': 'New search mode activated.',
      'whatToExplore': 'Which disease and region would you like to explore?',
      'suggestedQuestions': 'Suggested questions:',
      'collapse': 'Collapse',
      'showAllPrompts': 'Show all questions',
      'askQuestion': 'Ask a question (English, ქართულად, Deutsch)...',
      'clearChat': 'Clear chat',
      'expandChat': 'Expand chat',
      'standardWidth': 'Standard width',

      // Results view
      'integratedDataset': 'Integrated dataset',
      'downloadReportPdf': 'Download full report (PDF)',
      'sources': 'Sources',
      'pipelineSteps': 'Pipeline steps',
      'explanation': 'Plain-language explanation',
      'statisticalSummary': 'Statistical summary',
      'dataAudit': 'Data transformation audit',

      // Demographic & Population search and upload
      'searchPopulationTitle': 'Search Demographic Indicators & Datasets',
      'searchPopulationHint': 'Search indicator (e.g. urban, rural, 65, density)...',
      'searchPopulationOnline': 'Search online',
      'uploadPopulationCsv': 'Upload Population CSV',
      'customPopulationUrl': 'Custom Demographic URL',
      'customPopulationUrlHint': 'https://example.org/population_data.csv',
      'noPopulationSourcesFound': 'No demographic sources found. Try a custom CSV or URL.',
      'searchFailed': 'Search failed',
      'useThis': 'Use this',
      'cancel': 'Cancel',
      'search': 'Search',
      'change': 'Change',
      'dailyDownscalingWarningTitle': 'Note on Daily Resolution:',
      'dailyDownscalingWarningBody':
          'Primary surveillance data is reported at yearly or monthly resolution. In daily mode, the platform applies mass-preserving smooth temporal downscaling. For genuine day-by-day variation, please upload a daily resolution CSV.',
    },

    AppLanguage.de: {
      // General & Header
      'platformTitle': 'Klima-Gesundheit-Plattform',
      'appBarTitle': 'Klima- und Gesundheitsdaten-Integrationsplattform',
      'heroTitle': 'Klima- und Gesundheitsdaten-Integrationsplattform',
      'heroSubtitle':
          'Wählen Sie eine Krankheit und Region — oder füllen Sie das Formular direkt aus — und erhalten Sie einen harmonisierten, analysebereiten Datensatz, verständlich erklärt.',
      'aiCopilot': 'KI-Copilot',
      'close': 'Schließen',
      'openCopilot': 'Klima-Gesundheit-Copilot',
      'language': 'Sprache',

      // Literature Knowledge Base
      'literature': 'Wissenschaftliche Literatur',
      'literatureShort': 'Literatur',
      'literatureKnowledge': 'Wissenschaftliche Literatur & Wissensbasis',
      'literatureDialogSubtitle': 'Wissenschaftliche Grundlagen für KI-Analyse und Literaturkorpus-Verwaltung',
      'literatureIsTrainingTitle': 'Ist das KI-Modelltraining?',
      'literatureIsTrainingAnswer':
          'Nein. Dies ist In-Context-Grounding und Retrieval-Augmented Generation (RAG). Die neuronalen Gewichte bleiben völlig unverändert. Das System greift in Echtzeit auf diese verifizierten akademischen Quellen zu, um Halluzinationen zu verhindern und wissenschaftliche Exaktheit zu gewährleisten.',
      'literatureActiveCorpus': 'Aktive Literatur für die Analyse:',
      'compareLiteratureInChat': 'Unterschiede im KI-Copilot vergleichen',
      'literatureSelected': 'Ausgewählte Literatur:',
      'literatureDifferencesTitle': 'Was sind die Hauptunterschiede zwischen diesen Quellen?',
      'literatureDifferencesText':
          '• WHO: Schwerpunkt auf klinischer Überwachung, Ausbruchsschwellenwerten und Vektorkontrolle.\n• Lancet Countdown: Schwerpunkt auf makroklimatischer Attribution, Übertragungseignung (R0) und Vulnerabilität.\n• IPCC AR6: Schwerpunkt auf mehrdekadischen Klimaszenarien, Extremniederschlägen und Verbundrisiken.\n• Mordecai et al.: Schwerpunkt auf thermischer Vektorbiologie, optimalen Temperaturen (24-29°C) und 1-3 Monaten Verzögerung (Lags).',
      'addLiterature': 'Literatur hinzufügen',
      'addCustomLiterature': 'Eigene wissenschaftliche Literatur hinzufügen',
      'customLiteratureTitle': 'Neue wissenschaftliche Quelle hinzufügen',
      'customLiteratureSubtitle': 'Studienparameter angeben oder Dokumente für die KI-Analyse anfügen',
      'literatureTitleField': 'Titel',
      'literatureAuthorsField': 'Autoren / Organisation',
      'literatureYearField': 'Jahr',
      'literatureJournalField': 'Journal / Verlag',
      'literatureUrlField': 'DOI oder Web/PDF-URL (optional)',
      'literatureFocusField': 'Forschungsfokus & Abstract',
      'literatureDifferencesField': 'Relevanz für Klima-Gesundheit & Methodik',
      'attachFile': 'Datei anhängen (.pdf / .txt / .md)',
      'fileAttached': 'Angehängte Datei:',
      'saveLiterature': 'Literatur speichern',
      'downloadLiteraturePdf': 'PDF-Zusammenfassung herunterladen',
      'downloadFullBook': 'Gesamtes Buch / PDF',
      'downloadSummaryDigest': 'Zusammenfassung (PDF)',
      'readFullLiterature': 'Volltext & Details lesen',
      'officialSource': 'Offizielle Quelle / Paper',
      'deleteLiterature': 'Löschen',
      'customBadge': 'Benutzerdefiniert',
      'copyCitation': 'Zitation kopieren',
      'citationCopied': 'Zitation in Zwischenablage kopiert!',
      'literatureAddedSuccess': 'Literatur erfolgreich hinzugefügt!',
      'abstractTab': 'Abstract & Fokus',
      'methodologyTab': 'Methodik & Daten',
      'keyFindingsTab': 'Wichtigste Erkenntnisse & Schwellenwerte',
      'citationTab': 'Akademische Zitation',
      'activeLiteratureBadge': 'Literatur',
      'runSearchNow': 'Suche jetzt starten',
      'runSearchDirectly': 'Suche starten',
      'aiExtractButton': 'KI Extrahieren',
      'aiExtracting': 'KI analysiert Dokument / Link...',
      'aiExtractSuccess': 'Metadaten erfolgreich durch KI extrahiert und ausgefüllt!',
      'aiOverwritePromptTitle': 'Ausgefüllte Felder durch KI-Version ersetzen?',
      'aiOverwritePromptBody':
          'Sie haben bereits Felder ausgefüllt. Möchten Sie Ihre Daten durch die von der KI extrahierte Version ersetzen oder Ihre eigene behalten?',
      'aiOverwriteAccept': 'Mit KI-Version ersetzen',
      'aiOverwriteKeepMine': 'Eigene Version behalten',
      'aiExtractPreviewTitle': 'Von KI extrahierte Version',
      'aiExtractError': 'KI-Extraktion fehlgeschlagen: ',
      'aiExtractHint':
          'Geben Sie einen Link an oder laden Sie ein PDF hoch, und die KI extrahiert Titel, Autoren, Jahr und Abstract.',

      // Natural language card
      'naturalLanguageTitle': 'In natürlicher Sprache beschreiben',
      'naturalLanguageSubtitle': 'Geben Sie Freitext ein und Gemini LLM füllt das Formular automatisch aus',
      'naturalLanguageHint': 'z.B. „Dengue in Thailand von 2018 bis 2022 mit Temperatur und Niederschlag“',
      'fillForm': 'Formular ausfüllen',
      'parsing': 'Wird verarbeitet…',

      // Request form
      'requestFormTitle': 'Abfrageparameter',
      'disease': 'Krankheit',
      'region': 'Region',
      'pickOnMap': 'Auf Karte wählen',
      'climateVariables': 'Klimavariablen',
      'temperature': 'Temperatur',
      'precipitation': 'Niederschlag',
      'dateRange': 'Zeitraum',
      'startDate': 'Start',
      'endDate': 'Ende',
      'aggregation': 'Zeitliche Auflösung',
      'climateSource': 'Klima-Datenquelle',
      'caseDataSource': 'Falldatenquelle',
      'populationSource': 'Bevölkerungsquelle',
      'runIntegration': 'Integration ausführen',
      'runningIntegration': 'Wird ausgeführt…',

      // Actions & Copilot Drawer
      'suggestedParamsTitle': 'Vorgeschlagene Abfrageparameter',
      'applyAndSearch': 'Übernehmen & Suchen',
      'applyToForm': 'Nur ausfüllen',
      'newSearch': 'Neue Suche',
      'deepAnalysis': 'Detaillierte Analyse',
      'pdfReport': 'PDF-Bericht',
      'quickActions': 'Schnellaktionen:',
      'activeData': 'Aktive Daten',
      'searchingInProgress': 'Suche und Datenintegration läuft...',
      'searchSuccess': 'Suche und Integration erfolgreich abgeschlossen!',
      'keyResults': 'Hauptergebnisse',
      'totalReportedCases': 'Gemeldete Gesamtfälle',
      'peakPeriod': 'Höchststand-Zeitraum',
      'meanClimate': 'Durchschnittsklima',
      'laggedCorrelations': 'Klimakorrelationen (Zeitverzögerte Kreuzkorrelation)',
      'scientificSummary': 'Wissenschaftliche Zusammenfassung',
      'newSearchActivated': 'Neuer Suchmodus aktiviert.',
      'whatToExplore': 'Welche Krankheit und Region möchten Sie untersuchen?',
      'suggestedQuestions': 'Vorgeschlagene Fragen:',
      'collapse': 'Einklappen',
      'showAllPrompts': 'Alle Fragen anzeigen',
      'askQuestion': 'Frage stellen (Deutsch, English, ქართულად)...',
      'clearChat': 'Chat leeren',
      'expandChat': 'Chat vergrößern',
      'standardWidth': 'Standardbreite',

      // Results view
      'integratedDataset': 'Integrierter Datensatz',
      'downloadReportPdf': 'Vollständigen Bericht herunterladen (PDF)',
      'sources': 'Quellen',
      'pipelineSteps': 'Pipelineschritte',
      'explanation': 'Wissenschaftliche Erklärung',
      'statisticalSummary': 'Statistische Zusammenfassung',
      'dataAudit': 'Datentransformations-Audit',

      // Demographic & Population search and upload
      'searchPopulationTitle': 'Demografische Indikatoren & Datensätze suchen',
      'searchPopulationHint': 'Indikator suchen (z. B. urban, rural, 65, density)...',
      'searchPopulationOnline': 'Online suchen',
      'uploadPopulationCsv': 'Bevölkerungs-CSV hochladen',
      'customPopulationUrl': 'Benutzerdefinierte Bevölkerungs-URL',
      'customPopulationUrlHint': 'https://example.org/population_data.csv',
      'noPopulationSourcesFound': 'Keine demografischen Quellen gefunden. Versuchen Sie eine eigene CSV oder URL.',
      'searchFailed': 'Suche fehlgeschlagen',
      'useThis': 'Auswählen',
      'cancel': 'Abbrechen',
      'search': 'Suchen',
      'change': 'Ändern',
      'dailyDownscalingWarningTitle': 'Hinweis zur täglichen Auflösung:',
      'dailyDownscalingWarningBody':
          'Die primären Meldedaten liegen auf Jahres- oder Monatsebene vor. Im Tagesmodus wendet die Plattform eine massenerhaltende glatte zeitliche Interpolation an. Für authentische tägliche Schwankungen laden Sie bitte eine tägliche CSV-Datei hoch.',
    },
  };
}
