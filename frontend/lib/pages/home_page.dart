/// Top-level page: loads platform options from the backend, hosts the
/// request form, renders the results once an integration run completes,
/// and hosts the Climate-Health Copilot AI assistant drawer.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../core/responsive.dart';
import '../models/integration_request_params.dart';
import '../models/integration_result.dart';
import '../models/parsed_request.dart';
import '../models/platform_options.dart';
import '../services/api_client.dart';
import '../widgets/chat_copilot_drawer.dart';
import '../widgets/error_card.dart';
import '../widgets/literature_knowledge_dialog.dart';
import '../widgets/natural_language_card.dart';
import '../widgets/request_form_card.dart';
import '../widgets/results_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiClient _api = const ApiClient();
  final GlobalKey<RequestFormCardState> _formKey = GlobalKey<RequestFormCardState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  PlatformOptions? _options;
  String? _optionsError;

  bool _isSubmitting = false;
  String? _submitError;
  IntegrationResult? _result;

  bool _isParsing = false;
  String? _parseError;
  String? _parseNotes;

  bool _isDesktopChatOpen = false;
  bool _isChatExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await _api.fetchOptions();
      setState(() => _options = options);
    } catch (e) {
      setState(() => _optionsError = 'Could not reach the backend: $e');
    }
  }

  Future<void> _handleParseRequest(String text) async {
    setState(() {
      _isParsing = true;
      _parseError = null;
      _parseNotes = null;
    });
    try {
      final parsed = await _api.parseRequest(text);
      _formKey.currentState?.applyPrefill(parsed);
      setState(() => _parseNotes = parsed.notes);
    } catch (e) {
      setState(() => _parseError = e.toString());
    } finally {
      setState(() => _isParsing = false);
    }
  }

  void _handleApplyPrefillFromChat(ParsedRequest parsed) {
    _formKey.currentState?.applyPrefill(parsed);
    setState(() => _parseNotes = parsed.notes);
  }

  void _handleApplyAndSearchFromChat(ParsedRequest parsed) {
    setState(() => _parseNotes = parsed.notes);
    _formKey.currentState?.applyPrefillAndSubmit(parsed);
  }

  void _handleResetSearchFromChat() {
    setState(() {
      _result = null;
      _submitError = null;
    });
  }

  Future<void> _handleSubmit(IntegrationRequestParams params) async {
    setState(() {
      _isSubmitting = true;
      _submitError = null;
      _result = null;
    });
    try {
      final result = await _api.runIntegration(params);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _submitError = e.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Widget _buildCopilotDrawer({required VoidCallback onClose}) {
    return ChatCopilotDrawer(
      options: _options,
      activeResult: _result,
      isSearching: _isSubmitting,
      searchError: _submitError,
      currentDisease: _formKey.currentState?.currentDisease,
      currentRegion: _formKey.currentState?.currentRegion,
      currentStartDate: _formKey.currentState?.currentStartDate,
      currentEndDate: _formKey.currentState?.currentEndDate,
      onApplyPrefill: _handleApplyPrefillFromChat,
      onApplyAndSearch: _handleApplyAndSearchFromChat,
      onResetSearch: _handleResetSearchFromChat,
      onClose: onClose,
      isExpanded: _isChatExpanded,
      onToggleExpand: () => setState(() => _isChatExpanded = !_isChatExpanded),
    );
  }

  void _toggleChat(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) {
      setState(() => _isDesktopChatOpen = !_isDesktopChatOpen);
    } else {
      if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
        Navigator.of(context).pop();
      } else {
        _scaffoldKey.currentState?.openEndDrawer();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideScreen = screenWidth >= 1100;
    final showSplitChat = isWideScreen && _isDesktopChatOpen;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(I18n.t('platformTitle')),
        centerTitle: false,
        actions: [
          OutlinedButton.icon(
            onPressed: () => LiteratureKnowledgeDialog.show(
              context,
              onCompareInChat: (prompt) {
                if (!_isDesktopChatOpen && isWideScreen) {
                  setState(() => _isDesktopChatOpen = true);
                } else if (!isWideScreen && !(_scaffoldKey.currentState?.isEndDrawerOpen ?? false)) {
                  _scaffoldKey.currentState?.openEndDrawer();
                }
              },
            ),
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            label: Text(I18n.t('literatureShort')),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          _buildLanguageSelector(context),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: () => _toggleChat(context),
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: Text(
              showSplitChat ? I18n.t('close') : I18n.t('aiCopilot'),
            ),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      endDrawer: isWideScreen
          ? null
          : Drawer(
              width: _isChatExpanded
                  ? math.min(screenWidth * 0.96, 850.0)
                  : math.min(screenWidth * 0.92, 440.0),
              child: _buildCopilotDrawer(
                onClose: () => Navigator.of(context).pop(),
              ),
            ),
      floatingActionButton: showSplitChat
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _toggleChat(context),
              icon: const Icon(Icons.auto_awesome),
              label: Text(I18n.t('openCopilot')),
              tooltip: I18n.t('openCopilot'),
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final chatWidth = _isChatExpanded
              ? math.min(width * 0.65, 860.0)
              : 440.0;
          final availableWidth = showSplitChat ? width - chatWidth : width;

          final mainContent = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(availableWidth) ?? double.infinity,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(Responsive.pagePadding(width)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(context),
                    const SizedBox(height: 20),
                    _buildBody(),
                  ],
                ),
              ),
            ),
          );

          if (!showSplitChat) {
            return mainContent;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: mainContent),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                width: chatWidth,
                height: constraints.maxHeight,
                child: _buildCopilotDrawer(
                  onClose: () => setState(() => _isDesktopChatOpen = false),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final activeLang = appLocale.value;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<AppLanguage>(
      tooltip: I18n.t('language'),
      initialValue: activeLang,
      onSelected: (AppLanguage lang) {
        appLocale.setLanguage(lang);
      },
      itemBuilder: (context) => AppLanguage.values.map((lang) {
        final isSelected = lang == activeLang;
        return PopupMenuItem<AppLanguage>(
          value: lang,
          child: Row(
            children: [
              Text(lang.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                lang.label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Icon(Icons.check, size: 16, color: colorScheme.primary),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(activeLang.flag, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              activeLang.code.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 16, color: colorScheme.onSurface),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.public, size: 36, color: colors.onPrimaryContainer),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  I18n.t('heroTitle'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  I18n.t('heroSubtitle'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_optionsError != null) {
      return ErrorCard(message: _optionsError!);
    }
    if (_options == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NaturalLanguageCard(
          isParsing: _isParsing,
          error: _parseError,
          notes: _parseNotes,
          onParse: _handleParseRequest,
        ),
        const SizedBox(height: 16),
        RequestFormCard(
          key: _formKey,
          options: _options!,
          isSubmitting: _isSubmitting,
          onSubmit: _handleSubmit,
        ),
        const SizedBox(height: 24),
        if (_isSubmitting) const Center(child: CircularProgressIndicator()),
        if (_submitError != null) ErrorCard(message: _submitError!),
        if (_result != null) ResultsView(result: _result!),
      ],
    );
  }
}
