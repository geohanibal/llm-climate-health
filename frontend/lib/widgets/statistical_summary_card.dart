/// Card displaying cross-correlation analysis across time lags and scientific disclaimers.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';
import '../models/integration_result.dart';
import 'section_card.dart';

class StatisticalSummaryCard extends StatelessWidget {
  final StatisticalSummary stats;
  final String resolution;

  const StatisticalSummaryCard({
    super.key,
    required this.stats,
    required this.resolution,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final unitLabel = resolution == 'month' ? 'month(s)' : (resolution == 'year' ? 'year(s)' : 'period(s)');

    return SectionCard(
      title: 'Statistical & Lag Correlation Analysis',
      leading: Icons.analytics_outlined,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withAlpha(120),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${stats.sampleSize} periods analyzed',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bivariate correlation between climate variables and disease metrics across delayed time lags. '
            'In vector-borne diseases, weather changes lead case counts by 1–2 months due to breeding and incubation cycles.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          if (stats.correlations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Insufficient data points to compute correlation metrics (< 3 periods).',
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            )
          else
            _buildCorrelationTable(context, colors, isDark, unitLabel),
          const SizedBox(height: 14),
          _buildMethodologicalDisclaimer(context, colors, isDark),
        ],
      ),
    );
  }

  Widget _buildCorrelationTable(
    BuildContext context,
    ColorScheme colors,
    bool isDark,
    String unitLabel,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant.withAlpha(80)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              isDark ? colors.surfaceContainerHighest : colors.surfaceContainerLow,
            ),
            columnSpacing: 20,
            horizontalMargin: 16,
            columns: const [
              DataColumn(label: Text('Climate Variable', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Time Lag', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Pearson r', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('p-value', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Spearman ρ', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Significance', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: [
              for (final c in stats.correlations)
                DataRow(
                  color: c.significant
                      ? WidgetStatePropertyAll(
                          isDark
                              ? Colors.green.withAlpha(35)
                              : Colors.green.withAlpha(25),
                        )
                      : null,
                  cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.variable == 'temperature'
                                ? Icons.thermostat_outlined
                                : Icons.water_drop_outlined,
                            size: 16,
                            color: c.variable == 'temperature' ? Colors.orange : Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.variable == 'temperature' ? 'Temperature' : 'Precipitation',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        c.lagPeriods == 0 ? 'Lag 0 (same $unitLabel)' : 'Lag ${c.lagPeriods} ($unitLabel prior)',
                        style: TextStyle(
                          fontWeight: c.lagPeriods > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        c.pearsonR != null ? c.pearsonR!.toStringAsFixed(3) : '—',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: c.significant ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        c.pearsonP != null
                            ? (c.pearsonP! < 0.001 ? '< 0.001' : c.pearsonP!.toStringAsFixed(3))
                            : '—',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    DataCell(
                      Text(
                        c.spearmanRho != null ? c.spearmanRho!.toStringAsFixed(3) : '—',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    DataCell(
                      c.significant
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(40),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withAlpha(100)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 12, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'p < 0.05 *',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Text('Not sig.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodologicalDisclaimer(
    BuildContext context,
    ColorScheme colors,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? colors.surfaceContainerHighest.withAlpha(100) : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stats.scientificDisclaimer.isNotEmpty
                  ? stats.scientificDisclaimer
                  : 'Note: Climate metrics use single-point reanalysis; intended for exploratory analysis (EDA).',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
