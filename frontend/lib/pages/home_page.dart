/// Top-level page: loads platform options from the backend, hosts the
/// request form, renders the results once an integration run completes,
/// and hosts the Climate-Health Copilot AI assistant drawer.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../models/integration_request_params.dart';
import '../models/integration_result.dart';
import '../models/parsed_request.dart';
import '../models/platform_options.dart';
import '../services/api_client.dart';
import '../widgets/chat_copilot_drawer.dart';
import '../widgets/error_card.dart';
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
      currentDisease: _formKey.currentState?.currentDisease,
      currentRegion: _formKey.currentState?.currentRegion,
      currentStartDate: _formKey.currentState?.currentStartDate,
      currentEndDate: _formKey.currentState?.currentEndDate,
      onApplyPrefill: _handleApplyPrefillFromChat,
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
        title: const Text('Climate-Health Platform'),
        centerTitle: false,
        actions: [
          FilledButton.tonalIcon(
            onPressed: () => _toggleChat(context),
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: Text(
              showSplitChat ? 'დახურვა / Close' : 'AI Copilot',
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
              label: const Text('Climate-Health Copilot'),
              tooltip: 'გახსენით AI თანაშემწე / Open Copilot',
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
                  'Climate-Health Data Integration Platform',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Describe a disease and region — or fill in the form directly — '
                  'and get a harmonized, analysis-ready dataset joining climate and '
                  'health data, explained in plain language.',
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
