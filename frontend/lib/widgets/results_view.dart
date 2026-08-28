/// Composes every results section (steps, explanation, chart, table,
/// sources) once an [IntegrationResult] has come back from the backend.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../models/integration_result.dart';
import 'case_chart_card.dart';
import 'data_audit_card.dart';
import 'dataset_table_card.dart';
import 'explanation_card.dart';
import 'kpi_summary_card.dart';
import 'pipeline_steps_card.dart';
import 'report_download_bar.dart';
import 'sources_card.dart';

class ResultsView extends StatelessWidget {
  final IntegrationResult result;

  const ResultsView({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportDownloadBar(result: result),
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
        const SizedBox(height: 16),
        CaseChartCard(data: result.data, resolution: result.resolution),
        const SizedBox(height: 16),
        DatasetTableCard(data: result.data),
        const SizedBox(height: 16),
        SourcesCard(sources: result.sources),
      ],
    );
  }
}

