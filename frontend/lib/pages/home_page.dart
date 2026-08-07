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
import '../widgets/request_form_card.dart';
import '../widgets/results_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiClient _api = const ApiClient();

  PlatformOptions? _options;
  String? _optionsError;

  bool _isSubmitting = false;
  String? _submitError;
  IntegrationResult? _result;

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
        RequestFormCard(
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
