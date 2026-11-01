/// Modal dialog for comparing two data sources (FR-27 / Task F & F2 / A19).
///
/// Compares two climate sources (e.g. Open-Meteo ERA5 vs NASA POWER or custom upload)
/// or two case sources (builtin vs WHO GHO, custom_url, or uploaded CSV) over their
/// temporal overlap, computing Pearson r, mean difference, and deterministic heuristic verdicts
/// without modifying the main integrated dataset.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../models/discovered_source.dart';
import '../models/integration_result.dart';
import '../models/platform_options.dart';
import '../models/source_comparison.dart';
import '../services/api_client.dart';
import 'source_search_dialog.dart';

class SourceComparisonDialog extends StatefulWidget {
  final IntegrationResult result;
  final ApiClient apiClient;
  final PlatformOptions? options;

  const SourceComparisonDialog({
    super.key,
    required this.result,
    this.apiClient = const ApiClient(),
    this.options,
  });

  @override
  State<SourceComparisonDialog> createState() => _SourceComparisonDialogState();
}

class _SourceComparisonDialogState extends State<SourceComparisonDialog> {
  late String _compareKind; // 'climate' or 'cases'
  late String _altClimateSource; // 'open-meteo-era5', 'nasa-power', 'tmd', 'custom_upload'
  late String _altCaseSource; // 'who_gho', 'custom_url', 'custom_upload'
  late final TextEditingController _customCaseUrlCtrl;

  // WHO GHO indicator selection
  String? _whoIndicatorCode;
  String? _whoIndicatorName;

  // File uploads for Source B
  Uint8List? _caseUploadBytes;
  String? _caseUploadFileName;
  Uint8List? _climateUploadBytes;
  String? _climateUploadFileName;

  bool _loading = false;
  String? _errorMessage;
  SourceComparisonResponse? _comparisonResult;

  @override
  void initState() {
    super.initState();
    _compareKind = 'climate';
    _altCaseSource = 'who_gho';

    final curClim = widget.result.requestEcho['climate_source'] as String? ?? 'open-meteo-era5';
    _altClimateSource = curClim == 'open-meteo-era5' ? 'nasa-power' : 'open-meteo-era5';

    _customCaseUrlCtrl = TextEditingController(
      text: widget.result.requestEcho['custom_source_url'] as String? ?? '',
    );
    _whoIndicatorCode = widget.result.requestEcho['who_indicator_code'] as String?;
    _whoIndicatorName = widget.result.requestEcho['who_indicator_name'] as String?;

    // Auto-run climate comparison on open for immediate feedback
    _runComparison();
  }

  @override
  void dispose() {
    _customCaseUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile({required bool isClimate}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      if (isClimate) {
        _climateUploadBytes = result.files.single.bytes;
        _climateUploadFileName = result.files.single.name;
        _altClimateSource = 'custom_upload';
      } else {
        _caseUploadBytes = result.files.single.bytes;
        _caseUploadFileName = result.files.single.name;
        _altCaseSource = 'custom_upload';
      }
    });
    _runComparison();
  }

  Future<void> _openWhoGhoSearch() async {
    final picked = await showDialog<DiscoveredSource>(
      context: context,
      builder: (ctx) => SourceSearchDialog(
        diseaseKey: widget.result.disease,
        diseaseLabel: widget.result.disease,
        region: widget.result.region,
      ),
    );
    if (picked != null) {
      setState(() {
        if (picked.isWhoGho) {
          _whoIndicatorCode = picked.indicatorCode;
          _whoIndicatorName = picked.title;
          _altCaseSource = 'who_gho';
        } else {
          _altCaseSource = 'custom_url';
          _customCaseUrlCtrl.text = picked.resourceUrl ?? picked.datasetUrl;
        }
      });
      _runComparison();
    }
  }

  bool _isTmdAvailable() {
    if (widget.result.region != 'Thailand') return false;
    // Hidden until the backend confirms that TMD API keys are configured.
    return widget.options?.tmdConfigured ?? false;
  }

  Future<void> _runComparison() async {
    // Validate inputs
    if (_compareKind == 'cases') {
      if (_altCaseSource == 'who_gho' && _whoIndicatorCode == null) {
        setState(() {
          _errorMessage = I18n.t('pickWhoIndicator');
          _comparisonResult = null;
        });
        return;
      }
      if (_altCaseSource == 'custom_url' && _customCaseUrlCtrl.text.trim().isEmpty) {
        setState(() {
          _errorMessage = I18n.t('enterCaseUrl');
          _comparisonResult = null;
        });
        return;
      }
      if (_altCaseSource == 'custom_upload' && _caseUploadBytes == null) {
        setState(() {
          _errorMessage = I18n.t('noFileSelected');
          _comparisonResult = null;
        });
        return;
      }
    } else {
      if (_altClimateSource == 'custom_upload' && _climateUploadBytes == null) {
        setState(() {
          _errorMessage = I18n.t('noFileSelected');
          _comparisonResult = null;
        });
        return;
      }
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final echo = widget.result.requestEcho;
      final req = SourceComparisonRequest(
        disease: widget.result.disease,
        region: widget.result.region,
        variables: (echo['variables'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            const ['temperature', 'precipitation'],
        startDate: (echo['start_date'] as String?) ?? '2020-01-01',
        endDate: (echo['end_date'] as String?) ?? '2020-12-31',
        aggregation: (echo['aggregation'] as String?) ?? 'native',
        climateSource: (echo['climate_source'] as String?) ?? 'open-meteo-era5',
        caseDataSource: (echo['case_data_source'] as String?) ?? 'builtin',
        populationSource: (echo['population_source'] as String?) ?? 'worldbank',
        customSourceUrl: echo['custom_source_url'] as String?,
        whoIndicatorCode: echo['who_indicator_code'] as String?,
        whoIndicatorName: echo['who_indicator_name'] as String?,
        customPopulationUrl: echo['custom_population_url'] as String?,
        populationIndicatorCode: echo['population_indicator_code'] as String?,
        populationIndicatorName: echo['population_indicator_name'] as String?,
        compareKind: _compareKind,
        alternativeClimateSource: _altClimateSource,
        alternativeCaseDataSource: _compareKind == 'cases' ? _altCaseSource : null,
        alternativeCustomSourceUrl:
            _compareKind == 'cases' && _altCaseSource == 'custom_url'
                ? _customCaseUrlCtrl.text.trim()
                : null,
        alternativeWhoIndicatorCode:
            _compareKind == 'cases' && _altCaseSource == 'who_gho' ? _whoIndicatorCode : null,
        alternativeWhoIndicatorName:
            _compareKind == 'cases' && _altCaseSource == 'who_gho' ? _whoIndicatorName : null,
      );

      final SourceComparisonResponse res;
      if (_compareKind == 'cases' && _altCaseSource == 'custom_upload') {
        res = await widget.apiClient.compareSourcesWithUpload(
          req,
          _caseUploadBytes!,
          _caseUploadFileName ?? 'cases.csv',
        );
      } else if (_compareKind == 'climate' && _altClimateSource == 'custom_upload') {
        res = await widget.apiClient.compareSourcesWithUpload(
          req,
          _climateUploadBytes!,
          _climateUploadFileName ?? 'climate.csv',
        );
      } else {
        res = await widget.apiClient.compareSources(req);
      }

      if (mounted) {
        setState(() {
          _comparisonResult = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final dialogWidth = (size.width * 0.9).clamp(520.0, 860.0);
    final dialogHeight = (size.height * 0.88).clamp(420.0, 760.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogWidth, maxHeight: dialogHeight),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.compare_arrows, color: theme.colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          I18n.t('compareSourcesTitle'),
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          I18n.t('compareSourcesSubtitle'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Disclaimer Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        I18n.t('comparisonDisclaimer'),
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Source Pair Selector Controls
              _buildSelectorRow(context),
              const SizedBox(height: 16),

              // Main Body Content
              Expanded(
                child: _loading
                    ? Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 12),
                              Text(I18n.t('comparingSources')),
                            ],
                          ),
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                                  const SizedBox(height: 8),
                                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _runComparison,
                                    child: Text(I18n.t('compareButton')),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _comparisonResult != null
                            ? _buildComparisonResults(context, _comparisonResult!)
                            : const SizedBox.shrink(),
              ),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(I18n.t('close')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorRow(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'climate',
                      label: Text(I18n.t('compareClimateSources')),
                      icon: const Icon(Icons.cloud_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: 'cases',
                      label: Text(I18n.t('compareCaseSources')),
                      icon: const Icon(Icons.local_hospital_outlined, size: 18),
                    ),
                  ],
                  selected: {_compareKind},
                  onSelectionChanged: (val) {
                    setState(() {
                      _compareKind = val.first;
                      _comparisonResult = null;
                      _errorMessage = null;
                    });
                    if (_compareKind == 'climate') {
                      _runComparison();
                    }
                  },
                ),
                if (_compareKind == 'climate') ...[
                  const Text('vs:'),
                  DropdownButton<String>(
                    value: _altClimateSource,
                    isDense: true,
                    items: [
                      const DropdownMenuItem(
                        value: 'open-meteo-era5',
                        child: Text('Open-Meteo (ERA5)'),
                      ),
                      const DropdownMenuItem(
                        value: 'nasa-power',
                        child: Text('NASA POWER (MERRA-2)'),
                      ),
                      if (_isTmdAvailable())
                        const DropdownMenuItem(
                          value: 'tmd',
                          child: Text('TMD (Thailand)'),
                        ),
                      DropdownMenuItem(
                        value: 'custom_upload',
                        child: Text(I18n.t('uploadCsvFile')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _altClimateSource = val);
                        if (val != 'custom_upload') {
                          _runComparison();
                        }
                      }
                    },
                  ),
                ],
                ElevatedButton.icon(
                  onPressed: _loading ? null : _runComparison,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(I18n.t('compareButton')),
                ),
              ],
            ),

            // Climate Upload sub-row
            if (_compareKind == 'climate' && _altClimateSource == 'custom_upload') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickFile(isClimate: true),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      _climateUploadFileName != null
                          ? I18n.t('selectedFile').replaceAll('{file}', _climateUploadFileName!)
                          : I18n.t('pickCsvFile'),
                    ),
                  ),
                  if (_climateUploadFileName != null) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                  ],
                ],
              ),
            ],

            // Cases Source B Sub-Controls
            if (_compareKind == 'cases') ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${I18n.t('sourceBType')}:', style: const TextStyle(fontWeight: FontWeight.w600)),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'who_gho',
                        label: Text(I18n.t('whoGhoIndicator')),
                        icon: const Icon(Icons.search, size: 16),
                      ),
                      const ButtonSegment(
                        value: 'custom_url',
                        label: Text('URL'),
                        icon: Icon(Icons.link, size: 16),
                      ),
                      ButtonSegment(
                        value: 'custom_upload',
                        label: Text(I18n.t('uploadCsvFile')),
                        icon: const Icon(Icons.upload_file, size: 16),
                      ),
                    ],
                    selected: {_altCaseSource},
                    onSelectionChanged: (val) {
                      setState(() {
                        _altCaseSource = val.first;
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Cases: WHO GHO
              if (_altCaseSource == 'who_gho') ...[
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openWhoGhoSearch,
                      icon: const Icon(Icons.search, size: 18),
                      label: Text(I18n.t('pickWhoIndicator')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _whoIndicatorCode != null
                            ? I18n.t('selectedIndicator').replaceAll('{indicator}', _whoIndicatorName ?? _whoIndicatorCode!)
                            : I18n.t('noPopulationSourcesFound'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: _whoIndicatorCode == null ? FontStyle.italic : FontStyle.normal,
                          color: _whoIndicatorCode != null ? theme.colorScheme.primary : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'WHO GHO data is annual. Both sources will be compared at yearly resolution.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],

              // Cases: Custom URL
              if (_altCaseSource == 'custom_url') ...[
                TextField(
                  controller: _customCaseUrlCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: I18n.t('alternativeCaseUrlLabel'),
                    hintText: 'https://example.org/cases_data.csv',
                    isDense: true,
                    border: const OutlineInputBorder(),
                    helperText: I18n.t('caseComparisonUrlNote'),
                    helperMaxLines: 2,
                  ),
                ),
              ],

              // Cases: Custom Upload
              if (_altCaseSource == 'custom_upload') ...[
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickFile(isClimate: false),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(
                        _caseUploadFileName != null
                            ? I18n.t('selectedFile').replaceAll('{file}', _caseUploadFileName!)
                            : I18n.t('pickCsvFile'),
                      ),
                    ),
                    if (_caseUploadFileName != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    ],
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonResults(
    BuildContext context,
    SourceComparisonResponse res,
  ) {
    final theme = Theme.of(context);

    if (res.resolutionMismatch) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 12),
              Text(
                I18n.t('resolutionMismatchError'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                res.resolutionMismatchMessage ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      children: [
        // Subtitle row: Source A vs Source B
        Row(
          children: [
            Expanded(
              child: Text(
                '${res.sourceALabel} vs. ${res.sourceBLabel}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(80),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                res.resolution.toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Yearly Resolution Banner (if applicable)
        if (res.comparedAtYearlyResolution) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withAlpha(100)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.calendar_month, size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        I18n.t('comparedAtYearlyResolutionNote'),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                if (res.excludedYears.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    I18n.t('excludedIncompleteYears').replaceAll('{years}', res.excludedYears.join(', ')),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Variables comparison cards
        for (final cmp in res.variables) ...[
          _buildVariableComparisonCard(context, cmp, res),
          const SizedBox(height: 14),
        ],

        // Footer methodology note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(60),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ${I18n.t('ruleOfThumbDisclaimer')}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              if (res.compareKind == 'climate') ...[
                const SizedBox(height: 4),
                Text(
                  '• ${I18n.t('seasonalCycleNote')}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariableComparisonCard(
    BuildContext context,
    VariableComparison cmp,
    SourceComparisonResponse res,
  ) {
    final theme = Theme.of(context);

    final Color verdictColor;
    final IconData verdictIcon;
    final String verdictLabel;

    switch (cmp.verdict) {
      case 'very_similar':
        verdictColor = Colors.green;
        verdictIcon = Icons.check_circle_outline;
        verdictLabel = I18n.t('verdictVerySimilar');
        break;
      case 'similar':
        verdictColor = Colors.teal;
        verdictIcon = Icons.published_with_changes;
        verdictLabel = I18n.t('verdictSimilar');
        break;
      case 'too_few_points':
        verdictColor = Colors.orange;
        verdictIcon = Icons.warning_amber_rounded;
        verdictLabel = I18n.t('verdictTooFewPoints');
        break;
      default:
        verdictColor = Colors.deepOrange;
        verdictIcon = Icons.error_outline;
        verdictLabel = I18n.t('verdictClearlyDifferent');
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Verdict Chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    cmp.variable,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(verdictIcon, size: 16, color: verdictColor),
                  label: Text(
                    verdictLabel,
                    style: TextStyle(
                      color: verdictColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: verdictColor.withAlpha(20),
                  side: BorderSide(color: verdictColor.withAlpha(80)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Plain-Language Verdict Explanation
            Text(
              cmp.verdictExplanation,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),

            if (cmp.tooFewPoints && res.comparedAtYearlyResolution) ...[
              const SizedBox(height: 6),
              Text(
                I18n.t('fewYearlyPointsWarning').replaceAll('{n}', cmp.overlapPeriods.toString()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Sparkline Overlay
            if (cmp.seriesA.isNotEmpty && cmp.seriesB.isNotEmpty) ...[
              SizedBox(
                height: 85,
                child: CustomPaint(
                  painter: ComparisonSparklinePainter(
                    seriesA: cmp.seriesA.map((p) => p.value).toList(),
                    seriesB: cmp.seriesB.map((p) => p.value).toList(),
                    colorA: Colors.teal.shade700,
                    colorB: Colors.deepOrange.shade600,
                  ),
                  size: Size.infinite,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 14, height: 3, color: Colors.teal.shade700),
                  const SizedBox(width: 6),
                  Text(res.sourceALabel, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 16),
                  Container(width: 14, height: 3, color: Colors.deepOrange.shade600),
                  const SizedBox(width: 6),
                  Text(res.sourceBLabel, style: const TextStyle(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Expandable details table for experts
            Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  'Detailed metrics (n = ${cmp.overlapPeriods})',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                children: [
                  Table(
                    border: TableBorder.all(
                      color: theme.dividerColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                    },
                    children: [
                      TableRow(children: [
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(I18n.t('nOverlappingPoints'), style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            cmp.overlapPeriods.toString(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]),
                      TableRow(children: [
                        const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text('Pearson correlation (r)', style: TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            cmp.pearsonR != null ? cmp.pearsonR!.toStringAsFixed(4) : 'n/a',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]),
                      TableRow(children: [
                        const Padding(
                          padding: EdgeInsets.all(6.0),
                          child: Text('p-value', style: TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            cmp.formattedPValue ?? 'n/a',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(I18n.t('meanDifference'), style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            cmp.meanDifference != null ? '${cmp.meanDifference! >= 0 ? '+' : ''}${cmp.meanDifference!.toStringAsFixed(2)}' : 'n/a',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(I18n.t('meanAbsoluteDifference'), style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            cmp.meanAbsoluteDifference != null ? cmp.meanAbsoluteDifference!.toStringAsFixed(2) : 'n/a',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]),
                      TableRow(children: [
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(I18n.t('relativeMad'), style: const TextStyle(fontSize: 12)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            cmp.relativeMeanAbsoluteDifferencePercent != null
                                ? '${cmp.relativeMeanAbsoluteDifferencePercent!.toStringAsFixed(1)}%'
                                : 'n/a',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom sparkline painter for rendering both normalized series side by side.
class ComparisonSparklinePainter extends CustomPainter {
  final List<double?> seriesA;
  final List<double?> seriesB;
  final Color colorA;
  final Color colorB;

  ComparisonSparklinePainter({
    required this.seriesA,
    required this.seriesB,
    required this.colorA,
    required this.colorB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (seriesA.isEmpty || seriesB.isEmpty) return;

    // Determine min/max over non-null values across both series
    final nonNullA = seriesA.whereType<double>().toList();
    final nonNullB = seriesB.whereType<double>().toList();
    if (nonNullA.isEmpty || nonNullB.isEmpty) return;

    final allVals = [...nonNullA, ...nonNullB];
    final minVal = allVals.reduce((a, b) => a < b ? a : b);
    final maxVal = allVals.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs() > 1e-6 ? maxVal - minVal : 1.0;

    final paintA = Paint()
      ..color = colorA
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintB = Paint()
      ..color = colorB
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final n = seriesA.length;
    final dx = n > 1 ? size.width / (n - 1) : 0.0;

    _drawSeries(canvas, size, seriesA, minVal, range, dx, paintA);
    _drawSeries(canvas, size, seriesB, minVal, range, dx, paintB);
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<double?> series,
    double minVal,
    double range,
    double dx,
    Paint paint,
  ) {
    final path = Path();
    bool started = false;

    for (int i = 0; i < series.length; i++) {
      final val = series[i];
      if (val == null) {
        started = false;
        continue;
      }
      final x = i * dx;
      final normY = (val - minVal) / range;
      final y = size.height - (normY * (size.height - 8)) - 4;

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ComparisonSparklinePainter oldDelegate) {
    return oldDelegate.seriesA != seriesA ||
        oldDelegate.seriesB != seriesB ||
        oldDelegate.colorA != colorA ||
        oldDelegate.colorB != colorB;
  }
}
