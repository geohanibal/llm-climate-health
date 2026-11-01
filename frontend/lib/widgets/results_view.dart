/// Composes every results section (steps, explanation, chart, table,
/// sources) once an [IntegrationResult] has come back from the backend.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../models/integration_result.dart';
import 'case_chart_card.dart';
import 'data_audit_card.dart';
import 'data_coverage_card.dart';
import 'dataset_table_card.dart';
import 'explanation_card.dart';
import 'kpi_summary_card.dart';
import 'pipeline_steps_card.dart';
import 'report_download_bar.dart';
import 'source_comparison_dialog.dart';
import 'sources_card.dart';
import 'statistical_summary_card.dart';

class ResultsView extends StatelessWidget {
  final IntegrationResult result;
  final VoidCallback? onSearchCaseSources;
  final VoidCallback? onSearchPopulationSources;
  final void Function(DateTime start, DateTime end)? onAdjustDateRange;
  final void Function(String source)? onChangeClimateSource;

  const ResultsView({
    super.key,
    required this.result,
    this.onSearchCaseSources,
    this.onSearchPopulationSources,
    this.onAdjustDateRange,
    this.onChangeClimateSource,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              key: const Key('compare_sources_button'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => SourceComparisonDialog(result: result),
                );
              },
              icon: const Icon(Icons.compare_arrows, size: 18),
              label: Text(I18n.t('compareSources')),
            ),
            ReportDownloadBar(result: result),
          ],
        ),
        if (result.transformationAudit != null) ...[
          const SizedBox(height: 12),
          DataAuditCard(audit: result.transformationAudit!),
        ],
        const SizedBox(height: 12),
        PipelineStepsCard(
          steps: result.steps,
          cached: result.cached,
          lastVerified: result.lastVerified,
        ),
        const SizedBox(height: 16),
        ExplanationCard(
          explanation: result.explanation,
          explanationSource: result.explanationSource,
        ),
        const SizedBox(height: 16),
        KpiSummaryCard(data: result.data, resolution: result.resolution),
        if (result.statisticalSummary != null) ...[
          const SizedBox(height: 16),
          StatisticalSummaryCard(
            stats: result.statisticalSummary!,
            resolution: result.resolution,
          ),
        ],
        if (result.dataCoverage.any((c) => c.missingCount > 0)) ...[
          const SizedBox(height: 16),
          DataCoverageCard(
            coverage: result.dataCoverage,
            currentClimateSource:
                result.requestEcho['climate_source'] as String? ?? 'open-meteo-era5',
            onSearchCaseSources: onSearchCaseSources,
            onSearchPopulationSources: onSearchPopulationSources,
            onAdjustDateRange: onAdjustDateRange,
            onChangeClimateSource: onChangeClimateSource,
          ),
        ],
        const SizedBox(height: 16),
        CaseChartCard(data: result.data, resolution: result.resolution),
        const SizedBox(height: 16),
        DatasetTableCard(result: result),
        const SizedBox(height: 16),
        SourcesCard(sources: result.sources),
      ],
    );
  }
}
