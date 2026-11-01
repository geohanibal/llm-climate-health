/// Modal dialog for comparing two data sources (FR-27 / Task F / A19).
///
/// Compares two climate sources (e.g. Open-Meteo ERA5 vs NASA POWER) or two case
/// sources (builtin vs custom_url) over their temporal overlap, computing Pearson r,
/// mean difference, and deterministic heuristic verdicts without modifying the
/// main integrated dataset.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../models/integration_result.dart';
import '../models/source_comparison.dart';
import '../services/api_client.dart';

class SourceComparisonDialog extends StatefulWidget {
  final IntegrationResult result;
  final ApiClient apiClient;

  const SourceComparisonDialog({
    super.key,
    required this.result,
    this.apiClient = const ApiClient(),
  });

  @override
  State<SourceComparisonDialog> createState() => _SourceComparisonDialogState();
}

class _SourceComparisonDialogState extends State<SourceComparisonDialog> {
  late String _compareKind;
  late String _altClimateSource;
  late final TextEditingController _customCaseUrlCtrl;

  bool _loading = false;
  String? _errorMessage;
  SourceComparisonResponse? _comparisonResult;

  @override
  void initState() {
    super.initState();
    _compareKind = 'climate';
    final curClim = widget.result.requestEcho['climate_source'] as String? ?? 'open-meteo-era5';
    _altClimateSource = curClim == 'open-meteo-era5' ? 'nasa-power' : 'open-meteo-era5';
    _customCaseUrlCtrl = TextEditingController(
      text: widget.result.requestEcho['custom_source_url'] as String? ?? '',
    );
    // Auto-run climate comparison on open for immediate feedback
    _runComparison();
  }

  @override
  void dispose() {
    _customCaseUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _runComparison() async {
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
        alternativeCaseDataSource: _compareKind == 'cases' ? 'custom_url' : null,
        alternativeCustomSourceUrl:
            _compareKind == 'cases' ? _customCaseUrlCtrl.text.trim() : null,
      );

      final res = await widget.apiClient.compareSources(req);
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
    final dialogWidth = (size.width * 0.9).clamp(520.0, 840.0);
    final dialogHeight = (size.height * 0.85).clamp(420.0, 720.0);

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
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    // Drop the previous result: a climate result must not stay
                    // visible under the "cases" tab (and vice versa).
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
                    items: const [
                      DropdownMenuItem(
                        value: 'open-meteo-era5',
                        child: Text('Open-Meteo (ERA5)'),
                      ),
                      DropdownMenuItem(
                        value: 'nasa-power',
                        child: Text('NASA POWER (MERRA-2)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null && val != _altClimateSource) {
                        setState(() => _altClimateSource = val);
                        _runComparison();
                      }
                    },
                  ),
                ],
                ElevatedButton.icon(
                  // Cases need an alternative URL before anything can run.
                  onPressed: _loading ||
                          (_compareKind == 'cases' && _customCaseUrlCtrl.text.trim().isEmpty)
                      ? null
                      : _runComparison,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(I18n.t('compareButton')),
                ),
              ],
            ),
            if (_compareKind == 'cases') ...[
              const SizedBox(height: 10),
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
              const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
              const SizedBox(height: 12),
              Text(
                I18n.t('resolutionMismatchError'),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (res.resolutionMismatchMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  res.resolutionMismatchMessage!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView(
      children: [
        // Source comparison subtitle / banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${res.sourceALabel}  ↔  ${res.sourceBLabel} (${res.resolution})',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                I18n.t('ruleOfThumbDisclaimer'),
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Variable cards
        for (final v in res.variables) _buildVariableCard(context, v, res),
      ],
    );
  }

  Widget _buildVariableCard(
    BuildContext context,
    VariableComparison v,
    SourceComparisonResponse res,
  ) {
    final theme = Theme.of(context);
    final (chipColor, chipIcon, verdictLabelKey) = switch (v.verdict) {
      'very_similar' => (Colors.green, Icons.check_circle_outline, 'verdictVerySimilar'),
      'similar' => (Colors.teal, Icons.info_outline, 'verdictSimilar'),
      'clearly_different' => (Colors.orange.shade800, Icons.warning_amber_outlined, 'verdictClearlyDifferent'),
      _ => (Colors.grey.shade700, Icons.help_outline, 'verdictTooFewPoints'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Variable name & Verdict chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    v.variable,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: chipColor.withAlpha(120)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(chipIcon, size: 16, color: chipColor),
                      const SizedBox(width: 6),
                      Text(
                        I18n.t(verdictLabelKey),
                        style: TextStyle(
                          color: chipColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Plain-language explanation
            Text(
              v.verdictExplanation,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 12),

            // Sparkline Visualization of both series
            if (v.seriesA.isNotEmpty && v.seriesB.isNotEmpty) ...[
              Container(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withAlpha(80)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildLegendItem(Colors.blue, res.sourceALabel),
                        const SizedBox(width: 16),
                        _buildLegendItem(Colors.orange.shade800, res.sourceBLabel),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: ComparisonSparklinePainter(
                          seriesA: v.seriesA,
                          seriesB: v.seriesB,
                          colorA: Colors.blue,
                          colorB: Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Key metrics table
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildMetricChip(
                  label: I18n.t('nOverlappingPoints'),
                  value: '${v.overlapPeriods}',
                ),
                if (v.pearsonR != null)
                  _buildMetricChip(
                    label: 'Pearson r',
                    value: '${v.pearsonR!.toStringAsFixed(2)} (${v.formattedPValue ?? ""})',
                  ),
                if (v.meanDifference != null)
                  _buildMetricChip(
                    label: I18n.t('meanDifference'),
                    value: '${v.meanDifference! >= 0 ? "+" : ""}${v.meanDifference!.toStringAsFixed(2)}',
                  ),
                if (v.meanAbsoluteDifference != null)
                  _buildMetricChip(
                    label: I18n.t('meanAbsoluteDifference'),
                    value: v.meanAbsoluteDifference!.toStringAsFixed(2),
                  ),
                if (v.relativeMeanAbsoluteDifferencePercent != null)
                  _buildMetricChip(
                    label: I18n.t('relativeMad'),
                    value: '${v.relativeMeanAbsoluteDifferencePercent!.toStringAsFixed(1)}%',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildMetricChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Custom painter for side-by-side time series sparkline
class ComparisonSparklinePainter extends CustomPainter {
  final List<SeriesPoint> seriesA;
  final List<SeriesPoint> seriesB;
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
    final values = [
      ...seriesA.map((p) => p.value).whereType<double>(),
      ...seriesB.map((p) => p.value).whereType<double>(),
    ];
    if (values.isEmpty) return;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs();
    final effectiveRange = range == 0 ? 1.0 : range;

    final paintA = Paint()
      ..color = colorA
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final paintB = Paint()
      ..color = colorB
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    void drawSeries(List<SeriesPoint> series, Paint paint) {
      final path = Path();
      bool started = false;
      final n = series.length;
      if (n <= 1) return;

      for (int i = 0; i < n; i++) {
        final val = series[i].value;
        if (val == null) {
          started = false;
          continue;
        }
        final x = (i / (n - 1)) * size.width;
        final y = size.height - ((val - minVal) / effectiveRange) * size.height;

        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawSeries(seriesA, paintA);
    drawSeries(seriesB, paintB);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
