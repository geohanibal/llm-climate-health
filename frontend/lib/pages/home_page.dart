/// Top-level page: loads platform options from the backend, hosts the
/// request form, and renders the results once an integration run completes.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../models/integration_request_params.dart';
import '../models/integration_result.dart';
import '../models/platform_options.dart';
import '../services/api_client.dart';
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

  PlatformOptions? _options;
  String? _optionsError;

  bool _isSubmitting = false;
  String? _submitError;
  IntegrationResult? _result;

  bool _isParsing = false;
  String? _parseError;
  String? _parseNotes;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Climate-Health Data Integration Platform'),
        centerTitle: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(width) ?? double.infinity,
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
