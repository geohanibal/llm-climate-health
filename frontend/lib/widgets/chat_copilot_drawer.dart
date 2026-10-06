/// Climate-Health Copilot drawer: interactive conversational AI assistant
/// tailored specifically for the ETL climate-health thesis platform.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../models/chat_models.dart';
import '../models/integration_result.dart';
import '../models/parsed_request.dart';
import '../models/platform_options.dart';
import '../services/api_client.dart';
import '../services/dataset_export_service.dart';
import '../services/report_pdf_service.dart';
import 'literature_knowledge_dialog.dart';

class ChatCopilotDrawer extends StatefulWidget {
  final PlatformOptions? options;
  final IntegrationResult? activeResult;
  final bool isSearching;
  final String? searchError;
  final String? currentDisease;
  final String? currentRegion;
  final DateTime? currentStartDate;
  final DateTime? currentEndDate;
  final ValueChanged<ParsedRequest> onApplyPrefill;
  final ValueChanged<ParsedRequest>? onApplyAndSearch;
  final VoidCallback? onResetSearch;
  final VoidCallback onClose;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;
  final ValueNotifier<String?>? externalMessageNotifier;

  const ChatCopilotDrawer({
    super.key,
    required this.options,
    required this.activeResult,
    this.isSearching = false,
    this.searchError,
    required this.currentDisease,
    required this.currentRegion,
    required this.currentStartDate,
    required this.currentEndDate,
    required this.onApplyPrefill,
    this.onApplyAndSearch,
    this.onResetSearch,
    required this.onClose,
    this.isExpanded = false,
    this.onToggleExpand,
    this.externalMessageNotifier,
  });

  @override
  State<ChatCopilotDrawer> createState() => _ChatCopilotDrawerState();
}

class _ChatCopilotDrawerState extends State<ChatCopilotDrawer> {
  final ApiClient _api = const ApiClient();
  final DatasetExportService _exportService = const DatasetExportService();
  final ReportPdfService _pdfService = const ReportPdfService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isGeneratingPdf = false;
  List<String> _currentPrompts = [];
  final ScrollController _chipsScrollController = ScrollController();
  bool _arePromptsExpanded = false;

  @override
  void initState() {
    super.initState();
    _initWelcome();
    widget.externalMessageNotifier?.addListener(_handleExternalMessage);
    if (widget.externalMessageNotifier?.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleExternalMessage();
      });
    }
  }

  void _handleExternalMessage() {
    final msg = widget.externalMessageNotifier?.value;
    if (msg != null && msg.trim().isNotEmpty) {
      widget.externalMessageNotifier?.value = null;
      _sendMessage(msg);
    }
  }

  void _initWelcome() {
    _messages.clear();
    final lang = I18n.currentLanguage;
    final String content;

    switch (lang) {
      case AppLanguage.ka:
        content =
            "👋 **გამარჯობა! მე ვარ Climate-Health Copilot.**\n\n"
            "თქვენი ინტელექტუალური ასისტენტი კლიმატისა და ჯანდაცვის მონაცემთა ინტეგრაციის პლატფორმაში.\n\n"
            "შეგიძლიათ მკითხოთ ნებისმიერ საკითხზე (ქართულად, English, ან Deutsch):\n"
            "• ხელმისაწვდომი დაავადებები (დენგე, მალარია, ქოლერა) და რეგიონები;\n"
            "• როგორ მუშაობს ERA5 კლიმატის მონაცემები (ტემპერატურა & ნალექი);\n"
            "• რატომ არის მნიშვნელოვანი Lagged კორელაცია (Lags 1–3);\n"
            "• როგორ მოამზადოთ საკუთარი CSV ფაილი ასატვირთად;\n"
            "• ან მთხოვოთ ფორმის ავტომატურად შევსება და ძებნის დაწყება!";
        break;
      case AppLanguage.de:
        content =
            "👋 **Hallo! Ich bin der Climate-Health Copilot.**\n\n"
            "Ihr intelligenter Forschungsassistent für die Klima- und Gesundheitsdaten-Integrationsplattform.\n\n"
            "Sie können mich auf Deutsch, English oder ქართულად fragen:\n"
            "• Verfügbare Krankheiten (Dengue, Malaria, Cholera) und Regionen;\n"
            "• Wie die ERA5-Klimadaten (Temperatur & Niederschlag) funktionieren;\n"
            "• Warum zeitverzögerte Korrelationen (Lags 1–3) biologisch entscheidend sind;\n"
            "• Wie Sie Ihre eigene CSV-Datei für den Upload vorbereiten;\n"
            "• Oder bitten Sie mich, das Formular auszufüllen und die Suche direkt zu starten!";
        break;
      case AppLanguage.en:
        content =
            "👋 **Hello! I am the Climate-Health Copilot.**\n\n"
            "Your intelligent research assistant for this Climate-Health Data Integration Platform.\n\n"
            "You can ask me in English, Deutsch, or ქართულად:\n"
            "• Available diseases (Dengue, Malaria, Cholera) and geographic coverage;\n"
            "• How ERA5 climate reanalysis works (temperature & precipitation);\n"
            "• Biological vector breeding cycles and why lagged correlations (Lag 1-3) matter;\n"
            "• How to prepare your custom CSV file for upload;\n"
            "• Or ask me to automatically populate the query form for you!";
        break;
    }

    _messages.add(
      ChatMessage(
        role: 'assistant',
        content: content,
      ),
    );
    _updateDefaultPrompts();
  }

  void _updateDefaultPrompts() {
    final lang = I18n.currentLanguage;
    if (widget.activeResult != null) {
      final res = widget.activeResult!;
      switch (lang) {
        case AppLanguage.ka:
          _currentPrompts = [
            "🔬 ჩაატარე დეტალური ანალიზი და ამიხსენი შედეგები",
            "🦟 რატომ არის Lagged კორელაცია მნიშვნელოვანი?",
            "🌡️ რომელი ამინდის ფაქტორი უფრო ძლიერ მოქმედებს ${res.region}-ში?",
            "🔄 ახალი ძიების დაწყება",
          ];
          break;
        case AppLanguage.de:
          _currentPrompts = [
            "🔬 Detaillierte Analyse durchführen",
            "🦟 Warum ist die zeitverzögerte Korrelation wichtig?",
            "🌡️ Welcher Wetterfaktor hat in ${res.region} größeren Einfluss?",
            "🔄 Neue Suche starten",
          ];
          break;
        case AppLanguage.en:
          _currentPrompts = [
            "🔬 Run deep analysis and explain results",
            "🦟 Why is lagged cross-correlation important?",
            "🌡️ Which weather variable has higher impact in ${res.region}?",
            "🔄 Start new search",
          ];
          break;
      }
    } else {
      switch (lang) {
        case AppLanguage.ka:
          _currentPrompts = [
            "📚 შეადარე გამოყენებული სამეცნიერო ლიტერატურა",
            "🌍 რა მონაცემებია ხელმისაწვდომი ტაილანდზე?",
            "📋 დამიყენე ფორმა დენგეზე ტაილანდში (2018-2022)",
            "🔬 რა არის ERA5 reanalysis სადგურის მონაცემებთან შედარებით?",
          ];
          break;
        case AppLanguage.de:
          _currentPrompts = [
            "📚 Vergleiche die verwendete wissenschaftliche Literatur",
            "🌍 Welche Daten sind für Thailand verfügbar?",
            "📋 Formular für Dengue in Thailand (2018-2022) ausfüllen",
            "🔬 Was ist ERA5-Reanalyse im Vergleich zu Stationsdaten?",
          ];
          break;
        case AppLanguage.en:
          _currentPrompts = [
            "📚 Compare scientific literature used for analysis",
            "🌍 What data is available for Thailand?",
            "📋 Set form for Dengue in Thailand (2018-2022)",
            "🔬 What is ERA5 Reanalysis vs station data?",
          ];
          break;
      }
    }
  }

  @override
  void didUpdateWidget(covariant ChatCopilotDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.externalMessageNotifier != widget.externalMessageNotifier) {
      oldWidget.externalMessageNotifier?.removeListener(_handleExternalMessage);
      widget.externalMessageNotifier?.addListener(_handleExternalMessage);
      if (widget.externalMessageNotifier?.value != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleExternalMessage();
        });
      }
    }
    if (oldWidget.activeResult != widget.activeResult) {
      _updateDefaultPrompts();
      if (widget.activeResult != null) {
        _onNewResultArrived(widget.activeResult!);
      }
    }
    if (oldWidget.isSearching != widget.isSearching) {
      if (widget.isSearching) {
        _scrollToBottom();
      }
    }
    if (oldWidget.searchError != widget.searchError && widget.searchError != null) {
      _onSearchErrorArrived(widget.searchError!);
    }
  }

  String _buildResultSummaryText(IntegrationResult result, AppLanguage lang) {
    final stats = result.statisticalSummary;
    final totalCasesStr = stats?.totalCases != null
        ? stats!.totalCases!.toStringAsFixed(0)
        : '${result.data.length} ჩანაწერი';
    final tempStr = stats?.meanTemperatureC != null
        ? '${stats!.meanTemperatureC!.toStringAsFixed(1)} °C'
        : 'N/A';
    final precipStr = stats?.meanPrecipitationMm != null
        ? '${stats!.meanPrecipitationMm!.toStringAsFixed(1)} მმ'
        : 'N/A';

    final buffer = StringBuffer();
    switch (lang) {
      case AppLanguage.ka:
        final peakInfo = stats?.peakPeriod != null
            ? '${stats!.peakPeriod} (${stats.peakCases?.toStringAsFixed(0) ?? "?"} შემთხვევა, ინციდენტობა: ${stats.peakIncidencePer100k?.toStringAsFixed(1) ?? "?"} / 100k)'
            : 'მონაცემები დამუშავებულია';
        buffer.writeln('🎉 **ძებნა და ინტეგრაცია წარმატებით დასრულდა!**');
        buffer.writeln();
        buffer.writeln('📊 **ძირითადი შედეგები (${result.disease.toUpperCase()} — ${result.region}):**');
        buffer.writeln('• **დროითი გარჩევადობა:** ${result.resolution} (${result.data.length} პერიოდი)');
        buffer.writeln('• **სულ დაფიქსირებული შემთხვევები:** $totalCasesStr');
        buffer.writeln('• **პიკური პერიოდი:** $peakInfo');
        buffer.writeln('• **საშუალო კლიმატი:** ტემპერატურა: $tempStr | ნალექი: $precipStr');
        if (stats != null && stats.correlations.isNotEmpty) {
          buffer.writeln('• **კლიმატის კორელაციები (Lagged Cross-Correlation):**');
          for (final c in stats.correlations) {
            final sigMark = c.significant ? ' ⭐ *(სარწმუნო p < 0.05)*' : '';
            buffer.writeln('  - ${c.variable} Lag ${c.lagPeriods}: r = ${c.pearsonR?.toStringAsFixed(2) ?? "N/A"}$sigMark');
          }
        }
        if (result.explanation.isNotEmpty) {
          final shortExpl = result.explanation.length > 250
              ? '${result.explanation.substring(0, 250)}…'
              : result.explanation;
          buffer.writeln();
          buffer.writeln('🔬 **სამეცნიერო შეჯამება:**');
          buffer.writeln(shortExpl);
        }
        buffer.writeln();
        buffer.writeln('💡 *შეგიძლიათ პირდაპირ აქედან გადმოწეროთ შედეგები (CSV / JSON / PDF), მომთხოვოთ დეტალური ანალიზი, ან დაიწყოთ ახალი ძიება.*');
        break;

      case AppLanguage.de:
        final peakInfo = stats?.peakPeriod != null
            ? '${stats!.peakPeriod} (${stats.peakCases?.toStringAsFixed(0) ?? "?"} Fälle, Inzidenz: ${stats.peakIncidencePer100k?.toStringAsFixed(1) ?? "?"} / 100k)'
            : 'Daten verarbeitet';
        buffer.writeln('🎉 **Suche und Datenintegration erfolgreich abgeschlossen!**');
        buffer.writeln();
        buffer.writeln('📊 **Hauptergebnisse (${result.disease.toUpperCase()} — ${result.region}):**');
        buffer.writeln('• **Zeitliche Auflösung:** ${result.resolution} (${result.data.length} Perioden)');
        buffer.writeln('• **Gemeldete Gesamtfälle:** $totalCasesStr');
        buffer.writeln('• **Höchststand-Zeitraum:** $peakInfo');
        buffer.writeln('• **Durchschnittsklima:** Temperatur: $tempStr | Niederschlag: ${stats?.meanPrecipitationMm != null ? "${stats!.meanPrecipitationMm!.toStringAsFixed(1)} mm" : "N/A"}');
        if (stats != null && stats.correlations.isNotEmpty) {
          buffer.writeln('• **Klimakorrelationen (Zeitverzögerte Kreuzkorrelation):**');
          for (final c in stats.correlations) {
            final sigMark = c.significant ? ' ⭐ *(signifikant p < 0.05)*' : '';
            buffer.writeln('  - ${c.variable} Lag ${c.lagPeriods}: r = ${c.pearsonR?.toStringAsFixed(2) ?? "N/A"}$sigMark');
          }
        }
        if (result.explanation.isNotEmpty) {
          final shortExpl = result.explanation.length > 250
              ? '${result.explanation.substring(0, 250)}…'
              : result.explanation;
          buffer.writeln();
          buffer.writeln('🔬 **Wissenschaftliche Zusammenfassung:**');
          buffer.writeln(shortExpl);
        }
        buffer.writeln();
        buffer.writeln('💡 *Sie können Ergebnisse direkt exportieren (CSV / JSON / PDF), eine detaillierte Analyse anfordern oder eine neue Suche starten.*');
        break;

      case AppLanguage.en:
        final peakInfo = stats?.peakPeriod != null
            ? '${stats!.peakPeriod} (${stats.peakCases?.toStringAsFixed(0) ?? "?"} cases, incidence: ${stats.peakIncidencePer100k?.toStringAsFixed(1) ?? "?"} / 100k)'
            : 'Data processed';
        buffer.writeln('🎉 **Search and integration completed successfully!**');
        buffer.writeln();
        buffer.writeln('📊 **Key Results (${result.disease.toUpperCase()} — ${result.region}):**');
        buffer.writeln('• **Time resolution:** ${result.resolution} (${result.data.length} periods)');
        buffer.writeln('• **Total reported cases:** $totalCasesStr');
        buffer.writeln('• **Peak outbreak period:** $peakInfo');
        buffer.writeln('• **Mean climate:** Temperature: $tempStr | Precipitation: ${stats?.meanPrecipitationMm != null ? "${stats!.meanPrecipitationMm!.toStringAsFixed(1)} mm" : "N/A"}');
        if (stats != null && stats.correlations.isNotEmpty) {
          buffer.writeln('• **Climate Correlations (Lagged Cross-Correlation):**');
          for (final c in stats.correlations) {
            final sigMark = c.significant ? ' ⭐ *(significant p < 0.05)*' : '';
            buffer.writeln('  - ${c.variable} Lag ${c.lagPeriods}: r = ${c.pearsonR?.toStringAsFixed(2) ?? "N/A"}$sigMark');
          }
        }
        if (result.explanation.isNotEmpty) {
          final shortExpl = result.explanation.length > 250
              ? '${result.explanation.substring(0, 250)}…'
              : result.explanation;
          buffer.writeln();
          buffer.writeln('🔬 **Scientific Summary:**');
          buffer.writeln(shortExpl);
        }
        buffer.writeln();
        buffer.writeln('💡 *You can download results directly (CSV / JSON / PDF), ask for a deep analysis, or start a new search.*');
        break;
    }
    return buffer.toString();
  }

  void _onNewResultArrived(IntegrationResult result) {
    final lang = I18n.currentLanguage;
    final summaryText = _buildResultSummaryText(result, lang);

    final prompts = switch (lang) {
      AppLanguage.ka => [
          '🔬 ჩაატარე დეტალური ანალიზი და ამიხსენი შედეგები',
          '🦟 რატომ არის Lagged კორელაცია მნიშვნელოვანი?',
          '🌡️ რომელი ამინდის ფაქტორი უფრო ძლიერ მოქმედებს?',
          '🔄 ახალი ძიების დაწყება',
        ],
      AppLanguage.de => [
          '🔬 Detaillierte Analyse durchführen',
          '🦟 Warum ist die zeitverzögerte Korrelation wichtig?',
          '🌡️ Welcher Wetterfaktor hat größeren Einfluss?',
          '🔄 Neue Suche starten',
        ],
      AppLanguage.en => [
          '🔬 Run deep analysis and explain results',
          '🦟 Why is lagged cross-correlation important?',
          '🌡️ Which weather variable has higher impact?',
          '🔄 Start new search',
        ],
    };

    setState(() {
      _messages.add(
        ChatMessage(
          role: 'assistant',
          content: summaryText,
          suggestedPrompts: prompts,
        ),
      );
      _currentPrompts = prompts;
    });
    _scrollToBottom();
  }

  void _onSearchErrorArrived(String error) {
    final lang = I18n.currentLanguage;
    final msg = switch (lang) {
      AppLanguage.ka =>
        '⚠️ **ინტეგრაციის შეცდომა:** $error\n\n'
        'გთხოვთ შეამოწმოთ არჩეული პარამეტრები ან სცადოთ სხვა მონაცემთა წყარო.',
      AppLanguage.de =>
        '⚠️ **Integrationsfehler:** $error\n\n'
        'Bitte überprüfen Sie die ausgewählten Parameter oder versuchen Sie eine andere Datenquelle.',
      AppLanguage.en =>
        '⚠️ **Integration error:** $error\n\n'
        'Please review your parameters or try a different data source.',
    };
    setState(() {
      _messages.add(
        ChatMessage(
          role: 'assistant',
          content: msg,
        ),
      );
    });
    _scrollToBottom();
  }

  void _exportData(ExportFormat format) {
    if (widget.activeResult == null) return;
    final res = widget.activeResult!;
    final lang = I18n.currentLanguage;
    final fmtName = format == ExportFormat.csv ? "CSV" : "JSON";
    try {
      _exportService.export(
        res.data,
        format,
        fileNamePrefix: '${res.disease}_${res.region}'.toLowerCase(),
      );
      final msg = switch (lang) {
        AppLanguage.ka => '$fmtName ფაილი წარმატებით გადმოიწერა!',
        AppLanguage.de => '$fmtName-Datei erfolgreich heruntergeladen!',
        AppLanguage.en => '$fmtName file exported successfully!',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export error: $e')),
      );
    }
  }

  Future<void> _exportPdf() async {
    if (widget.activeResult == null || _isGeneratingPdf) return;
    final res = widget.activeResult!;
    setState(() => _isGeneratingPdf = true);
    try {
      await _pdfService.downloadReport(
        result: res,
        disease: res.disease,
        region: res.region,
      );
      if (mounted) {
        final lang = I18n.currentLanguage;
        final msg = switch (lang) {
          AppLanguage.ka => 'PDF რეპორტი წარმატებით გადმოიწერა!',
          AppLanguage.de => 'PDF-Bericht erfolgreich heruntergeladen!',
          AppLanguage.en => 'PDF report downloaded successfully!',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _triggerDeepAnalysis() {
    if (widget.activeResult == null) return;
    final res = widget.activeResult!;
    final lang = I18n.currentLanguage;
    final prompt = switch (lang) {
      AppLanguage.ka =>
        'გააკეთე მიღებული შედეგების დეტალური ეპიდემიოლოგიური და კლიმატური ანალიზი (${res.disease} - ${res.region}): '
        'ამიხსენი პიკური პერიოდი, Lagged კორელაციები (Lags 0-3), ტემპერატურისა და ნალექის გავლენა და პრაქტიკული რეკომენდაციები.',
      AppLanguage.de =>
        'Führe eine detaillierte epidemiologische und klimatische Analyse der Ergebnisse für (${res.disease} - ${res.region}) durch: '
        'Erkläre den Höchststand, die zeitverzögerten Korrelationen (Lags 0-3), den Einfluss von Temperatur und Niederschlag sowie Handlungsempfehlungen.',
      AppLanguage.en =>
        'Provide a detailed epidemiological and climate analysis of the results for (${res.disease} - ${res.region}): '
        'Explain the peak outbreak period, lagged cross-correlations (Lags 0-3), temperature and precipitation impacts, and actionable recommendations.',
    };
    _sendMessage(prompt);
  }

  void _startNewSearch() {
    widget.onResetSearch?.call();
    final lang = I18n.currentLanguage;
    final String content;
    final List<String> prompts;

    switch (lang) {
      case AppLanguage.ka:
        content =
            '🔄 **ახალი ძიების რეჟიმი გააქტიურებულია.**\n\n'
            'რომელი დაავადებისა და რეგიონის გამოკვლევა გსურთ?\n'
            'შეგიძლიათ პირდაპირ მომწეროთ ან აირჩიოთ ქვემოთ მოცემული ერთ-ერთი ვარიანტი:\n'
            '• **Dengue in Thailand** (2018-2022);\n'
            '• **Malaria in Kenya** (2016-2020);\n'
            '• **Dengue in Peru** (2015-2023);\n'
            '• **Cholera in Somalia** (2017-2023).';
        prompts = [
          '📋 Set form for Dengue in Thailand (2018-2022)',
          '📋 Set form for Malaria in Kenya (2016-2020)',
          '📋 Set form for Dengue in Peru (2015-2023)',
          '🔬 რა კლიმატური მონაცემებია ხელმისაწვდომი?',
        ];
        break;
      case AppLanguage.de:
        content =
            '🔄 **Neuer Suchmodus aktiviert.**\n\n'
            'Welche Krankheit und Region möchten Sie untersuchen?\n'
            'Sie können direkt schreiben oder eine der folgenden Optionen wählen:\n'
            '• **Dengue in Thailand** (2018-2022);\n'
            '• **Malaria in Kenya** (2016-2020);\n'
            '• **Dengue in Peru** (2015-2023);\n'
            '• **Cholera in Somalia** (2017-2023).';
        prompts = [
          '📋 Formular für Dengue in Thailand (2018-2022) ausfüllen',
          '📋 Formular für Malaria in Kenia (2016-2020) ausfüllen',
          '📋 Formular für Dengue in Peru (2015-2023) ausfüllen',
          '🔬 Welche Klimadaten sind verfügbar?',
        ];
        break;
      case AppLanguage.en:
        content =
            '🔄 **New search mode activated.**\n\n'
            'Which disease and region would you like to explore?\n'
            'You can describe it directly or choose one of the suggestions below:\n'
            '• **Dengue in Thailand** (2018-2022);\n'
            '• **Malaria in Kenya** (2016-2020);\n'
            '• **Dengue in Peru** (2015-2023);\n'
            '• **Cholera in Somalia** (2017-2023).';
        prompts = [
          '📋 Set form for Dengue in Thailand (2018-2022)',
          '📋 Set form for Malaria in Kenya (2016-2020)',
          '📋 Set form for Dengue in Peru (2015-2023)',
          '🔬 What climate datasets are available?',
        ];
        break;
    }

    setState(() {
      _messages.add(
        ChatMessage(
          role: 'assistant',
          content: content,
          suggestedPrompts: prompts,
        ),
      );
      _currentPrompts = prompts;
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    widget.externalMessageNotifier?.removeListener(_handleExternalMessage);
    _textController.dispose();
    _scrollController.dispose();
    _chipsScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  ChatContext _buildContext() {
    ActiveResultSummary? resultSummary;
    if (widget.activeResult != null) {
      resultSummary = ActiveResultSummary.fromIntegrationResult(widget.activeResult!);
    }

    String? startStr;
    if (widget.currentStartDate != null) {
      startStr =
          '${widget.currentStartDate!.year}-${widget.currentStartDate!.month.toString().padLeft(2, '0')}-01';
    }
    String? endStr;
    if (widget.currentEndDate != null) {
      endStr =
          '${widget.currentEndDate!.year}-${widget.currentEndDate!.month.toString().padLeft(2, '0')}-01';
    }

    return ChatContext(
      currentDisease: widget.currentDisease,
      currentRegion: widget.currentRegion,
      currentStartDate: startStr,
      currentEndDate: endStr,
      activeResult: resultSummary,
      language: I18n.currentLanguage.code,
      literatureSource: activeLiterature.value.id,
    );
  }

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isLoading || widget.isSearching) return;

    if (clean == '🔄 ახალი ძიების დაწყება') {
      _startNewSearch();
      return;
    }

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', content: clean));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final context = _buildContext();
      final response = await _api.sendChatMessage(
        messages: _messages,
        context: context,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content: response.reply,
            suggestedAction: response.suggestedAction,
            suggestedPrompts: response.suggestedPrompts,
          ),
        );
        if (response.suggestedPrompts.isNotEmpty) {
          _currentPrompts = response.suggestedPrompts;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            role: 'assistant',
            content: "⚠️ შეცდომა პასუხის მიღებისას: $e",
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, colorScheme),
          if (widget.activeResult != null) _buildActiveResultActionBar(colorScheme),
          _buildQuickSearchBar(colorScheme),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (widget.isSearching ? 1 : (_isLoading ? 1 : 0)),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildMessageBubble(_messages[index], colorScheme);
                } else if (widget.isSearching) {
                  return _buildSearchingBubble(colorScheme);
                } else {
                  return _buildLoadingBubble(colorScheme);
                }
              },
            ),
          ),
          if (_currentPrompts.isNotEmpty && !_isLoading && !widget.isSearching)
            _buildQuickChips(colorScheme),
          const Divider(height: 1),
          _buildInputBar(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Climate-Health Copilot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                _buildContextBadge(colorScheme),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: I18n.t('clearChat'),
            onPressed: _isLoading ? null : () => setState(_initWelcome),
          ),
          if (widget.onToggleExpand != null)
            IconButton(
              icon: Icon(
                widget.isExpanded ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                size: 22,
              ),
              tooltip: widget.isExpanded ? I18n.t('standardWidth') : I18n.t('expandChat'),
              onPressed: widget.onToggleExpand,
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: I18n.t('close'),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildContextBadge(ColorScheme colorScheme) {
    if (widget.isSearching) {
      final runningText = I18n.currentLanguage == AppLanguage.ka
          ? 'ინტეგრაცია მიმდინარეობს...'
          : (I18n.currentLanguage == AppLanguage.de ? 'Integration läuft...' : 'Running integration...');
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: colorScheme.primary),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              runningText,
              style: TextStyle(fontSize: 11, color: colorScheme.primary, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (widget.activeResult != null) {
      final res = widget.activeResult!;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '${I18n.t('activeData')}: ${res.disease} • ${res.region}',
              style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (widget.currentDisease != null) {
      return Text(
        'Form: ${widget.currentDisease} • ${widget.currentRegion ?? ""}',
        style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      'Multilingual Research AI Assistant',
      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
    );
  }

  Widget _buildActiveResultActionBar(ColorScheme colorScheme) {
    final res = widget.activeResult;
    if (res == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${I18n.t('activeData')}: ${res.disease} (${res.region})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                ),
                icon: const Icon(Icons.replay_rounded, size: 14),
                label: Text(I18n.t('newSearch'), style: const TextStyle(fontSize: 11)),
                onPressed: _startNewSearch,
              ),
            ],
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: const Icon(Icons.file_download_outlined, size: 14),
                  label: const Text('CSV', style: TextStyle(fontSize: 11)),
                  onPressed: () => _exportData(ExportFormat.csv),
                ),
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: const Icon(Icons.code_rounded, size: 14),
                  label: const Text('JSON', style: TextStyle(fontSize: 11)),
                  onPressed: () => _exportData(ExportFormat.json),
                ),
                const SizedBox(width: 6),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined, size: 14),
                  label: Text(
                    _isGeneratingPdf ? '...' : I18n.t('pdfReport'),
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: _isGeneratingPdf ? null : _exportPdf,
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  icon: const Icon(Icons.analytics_outlined, size: 14),
                  label: Text('🔬 ${I18n.t('deepAnalysis')}', style: const TextStyle(fontSize: 11)),
                  onPressed: _triggerDeepAnalysis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSearchBar(ColorScheme colorScheme) {
    return ValueListenableBuilder<LiteratureCorpus>(
      valueListenable: activeLiterature,
      builder: (context, corpus, _) {
        final lang = I18n.currentLanguage;
        final hasFormTargets = widget.currentDisease != null &&
            widget.currentRegion != null &&
            widget.activeResult == null &&
            !widget.isSearching &&
            widget.onApplyAndSearch != null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => LiteratureKnowledgeDialog.show(
                  context,
                  onCompareInChat: (p) => _sendMessage(p),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.menu_book_outlined, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '📚 ${corpus.getLocalizedLabel(lang)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 14),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (hasFormTargets)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 14),
                  label: Text(
                    '${I18n.t('applyAndSearch')}: ${widget.currentDisease}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    final parsed = ParsedRequest(
                      disease: widget.currentDisease,
                      region: widget.currentRegion,
                      startDate: widget.currentStartDate,
                      endDate: widget.currentEndDate,
                      notes: 'Triggered from Copilot toolbar',
                    );
                    widget.onApplyAndSearch!(parsed);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, ColorScheme colorScheme) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.smart_toy_outlined, size: 16, color: colorScheme.primary),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: _formatFormattedText(
                    msg.content,
                    isUser ? Colors.white : colorScheme.onSurface,
                    colorScheme,
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Icon(Icons.person, size: 16, color: colorScheme.onSecondaryContainer),
                ),
              ],
            ],
          ),
          if (msg.suggestedAction != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: _buildActionCard(msg.suggestedAction!, colorScheme),
            ),
          ],
          if (!isUser &&
              widget.activeResult != null &&
              (msg.content.contains('ძებნა და ინტეგრაცია წარმატებით დასრულდა') ||
               msg.content.contains('Suche und Datenintegration erfolgreich abgeschlossen') ||
               msg.content.contains('Search and integration completed successfully'))) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: _buildResultInlineActions(colorScheme),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultInlineActions(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                I18n.t('quickActions'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.file_download_outlined, size: 14),
                label: const Text('CSV', style: TextStyle(fontSize: 11)),
                onPressed: () => _exportData(ExportFormat.csv),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.code_rounded, size: 14),
                label: const Text('JSON', style: TextStyle(fontSize: 11)),
                onPressed: () => _exportData(ExportFormat.json),
              ),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: _isGeneratingPdf
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 14),
                label: Text(
                  _isGeneratingPdf ? '...' : I18n.t('pdfReport'),
                  style: const TextStyle(fontSize: 11),
                ),
                onPressed: _isGeneratingPdf ? null : _exportPdf,
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.analytics_outlined, size: 14),
                label: Text('🔬 ${I18n.t('deepAnalysis')}', style: const TextStyle(fontSize: 11)),
                onPressed: _triggerDeepAnalysis,
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                icon: const Icon(Icons.replay_rounded, size: 14),
                label: Text('🔄 ${I18n.t('newSearch')}', style: const TextStyle(fontSize: 11)),
                onPressed: _startNewSearch,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingBubble(ColorScheme colorScheme) {
    final lang = I18n.currentLanguage;
    final details = switch (lang) {
      AppLanguage.ka =>
        '• ERA5 კლიმატის მონაცემების ამოღება (ტემპერატურა & ნალექი);\n'
        '• ეპიდემიოლოგიური მონაცემების ჰარმონიზაცია;\n'
        '• Lagged კროს-კორელაციების გამოთვლა (Lags 0–3).',
      AppLanguage.de =>
        '• Abruf von ERA5-Klimadaten (Temperatur & Niederschlag);\n'
        '• Harmonisierung epidemiologischer Falldaten;\n'
        '• Berechnung zeitverzögerter Kreuzkorrelationen (Lags 0–3).',
      AppLanguage.en =>
        '• Fetching ERA5 climate reanalysis (temperature & precipitation);\n'
        '• Harmonizing epidemiological surveillance records;\n'
        '• Computing lagged cross-correlations (Lags 0–3).',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.rocket_launch_rounded, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        I18n.t('searchingInProgress'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    details,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(FormPrefillAction action, ColorScheme colorScheme) {
    final lang = I18n.currentLanguage;
    final diseaseLabel = I18n.t('disease');
    final regionLabel = I18n.t('region');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 18, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                I18n.t('suggestedParamsTitle'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (action.disease != null)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('$diseaseLabel: ${action.disease}', style: const TextStyle(fontSize: 11)),
                ),
              if (action.region != null)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('$regionLabel: ${action.region}', style: const TextStyle(fontSize: 11)),
                ),
              if (action.startDate != null && action.endDate != null)
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text('${action.startDate} - ${action.endDate}',
                      style: const TextStyle(fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: Text(I18n.t('applyAndSearch'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: widget.isSearching
                    ? null
                    : () {
                        final parsed = action.toParsedRequest();
                        if (widget.onApplyAndSearch != null) {
                          widget.onApplyAndSearch!(parsed);
                        } else {
                          widget.onApplyPrefill(parsed);
                        }
                        final snack = switch (lang) {
                          AppLanguage.ka => 'ძებნა გაეშვა: ${action.disease ?? ""} • ${action.region ?? ""}',
                          AppLanguage.de => 'Suche gestartet: ${action.disease ?? ""} • ${action.region ?? ""}',
                          AppLanguage.en => 'Search started: ${action.disease ?? ""} • ${action.region ?? ""}',
                        };
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(snack),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 16),
                label: Text(I18n.t('applyToForm'),
                    style: const TextStyle(fontSize: 12)),
                onPressed: () {
                  widget.onApplyPrefill(action.toParsedRequest());
                  final snack = switch (lang) {
                    AppLanguage.ka => 'პარამეტრები გადატანილია ფორმაში!',
                    AppLanguage.de => 'Parameter ins Formular übernommen!',
                    AppLanguage.en => 'Parameters applied to form!',
                  };
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(snack),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formatFormattedText(String text, Color defaultColor, ColorScheme colorScheme) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      final isBullet = line.trimLeft().startsWith('•') || line.trimLeft().startsWith('- ');
      final cleanText = isBullet ? line.replaceFirst(RegExp(r'^\s*[-•]\s*'), '') : line;

      final spans = _parseInlineFormatting(cleanText, defaultColor, colorScheme);

      if (isBullet) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: defaultColor, fontWeight: FontWeight.bold)),
                Expanded(child: RichText(text: TextSpan(children: spans))),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: RichText(text: TextSpan(children: spans)),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  List<TextSpan> _parseInlineFormatting(String line, Color defaultColor, ColorScheme colorScheme) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\*\*.*?\*\*|\*.*?\*|`.*?`)');
    int lastEnd = 0;

    for (final match in regex.allMatches(line)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: line.substring(lastEnd, match.start),
          style: TextStyle(color: defaultColor, fontSize: 13.5, height: 1.4),
        ));
      }

      final matchText = match.group(0)!;
      if (matchText.startsWith('**') && matchText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: TextStyle(
            color: defaultColor,
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            height: 1.4,
          ),
        ));
      } else if (matchText.startsWith('*') && matchText.endsWith('*')) {
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: TextStyle(
            color: defaultColor,
            fontStyle: FontStyle.italic,
            fontSize: 13.5,
            height: 1.4,
          ),
        ));
      } else if (matchText.startsWith('`') && matchText.endsWith('`')) {
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: TextStyle(
            color: colorScheme.primary,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < line.length) {
      spans.add(TextSpan(
        text: line.substring(lastEnd),
        style: TextStyle(color: defaultColor, fontSize: 13.5, height: 1.4),
      ));
    }

    return spans;
  }

  Widget _buildLoadingBubble(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.smart_toy_outlined, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  'Copilot is thinking...',
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChips(ColorScheme colorScheme) {
    if (_currentPrompts.isEmpty) return const SizedBox.shrink();

    if (_arePromptsExpanded) {
      return Container(
        constraints: const BoxConstraints(maxHeight: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  I18n.t('suggestedQuestions'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => setState(() => _arePromptsExpanded = false),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          I18n.t('collapse'),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.expand_less, size: 16, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _currentPrompts.map((prompt) {
                    return ActionChip(
                      label: Text(
                        prompt,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      tooltip: prompt,
                      backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.35),
                      side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.25)),
                      onPressed: () => _sendMessage(prompt),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 32),
            tooltip: 'Scroll left',
            onPressed: () {
              if (_chipsScrollController.hasClients) {
                _chipsScrollController.animateTo(
                  math.max(0, _chipsScrollController.offset - 180),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad,
                  PointerDeviceKind.stylus,
                },
              ),
              child: ListView.separated(
                controller: _chipsScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _currentPrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _currentPrompts[index];
                  return ActionChip(
                    label: Text(
                      prompt,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    tooltip: prompt,
                    backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
                    onPressed: () => _sendMessage(prompt),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 32),
            tooltip: 'Scroll right',
            onPressed: () {
              if (_chipsScrollController.hasClients) {
                _chipsScrollController.animateTo(
                  _chipsScrollController.offset + 180,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.unfold_more, size: 18),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 26, minHeight: 32),
            tooltip: I18n.t('showAllPrompts'),
            onPressed: () => setState(() => _arePromptsExpanded = true),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textInputAction: TextInputAction.send,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: I18n.t('askQuestion'),
                hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              ),
              onSubmitted: (val) => _sendMessage(val),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isLoading ? null : () => _sendMessage(_textController.text),
            icon: const Icon(Icons.send_rounded, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
