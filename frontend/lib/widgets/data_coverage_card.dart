/// Data coverage and temporal gap detection card (FR-26, A18).
///
/// Plain-language explanations of missing periods, deterministic likely
/// reasons (e.g. OpenDengue starting 2009-01 for Thailand), completeness
/// progress bars, and one-click actions to search alternative sources or
/// adjust the requested date range.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../models/integration_result.dart';

class DataCoverageCard extends StatelessWidget {
  final List<DataCoverage> coverage;
  final String currentClimateSource;
  final VoidCallback? onSearchCaseSources;
  final VoidCallback? onSearchPopulationSources;
  final void Function(DateTime start, DateTime end)? onAdjustDateRange;
  final void Function(String source)? onChangeClimateSource;

  const DataCoverageCard({
    super.key,
    required this.coverage,
    this.currentClimateSource = 'open-meteo-era5',
    this.onSearchCaseSources,
    this.onSearchPopulationSources,
    this.onAdjustDateRange,
    this.onChangeClimateSource,
  });

  static DateTime? _parsePeriod(String? p, {bool isEnd = false}) {
    if (p == null || p.isEmpty) return null;
    try {
      if (p.length == 7 && p.contains('-')) {
        final year = int.parse(p.substring(0, 4));
        final month = int.parse(p.substring(5, 7));
        if (isEnd) {
          // Last day of month
          final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
          return nextMonth.subtract(const Duration(days: 1));
        }
        return DateTime(year, month, 1);
      }
      if (p.length == 4) {
        final year = int.parse(p);
        return isEnd ? DateTime(year, 12, 31) : DateTime(year, 1, 1);
      }
      return DateTime.tryParse(p);
    } catch (_) {
      return null;
    }
  }

  String _formatColumnLabel(String column) {
    switch (column) {
      case 'case_count':
        return I18n.t('disease');
      case 'population':
        return I18n.t('populationSource');
      case 'incidence_rate_per_100k':
        return 'Incidence / 100k';
      case 'temperature_mean_c':
        return I18n.t('temperature');
      case 'temperature_min_c':
        return I18n.t('temperature_min');
      case 'temperature_max_c':
        return I18n.t('temperature_max');
      case 'precipitation_sum_mm':
        return I18n.t('precipitation');
      default:
        return column;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Filter to columns with missing data
    final missingItems = coverage.where((c) => c.missingCount > 0).toList();
    if (missingItems.isEmpty) return const SizedBox.shrink();

    final hasHighMissing = missingItems.any(
      (c) => c.missingPercent > 50.0 && c.reason != 'not_provided_by_source',
    );
    final onlyNotProvided = missingItems.every(
      (c) => c.reason == 'not_provided_by_source',
    );

    Color borderColor;
    Color bgColor;
    Color iconColor;
    IconData headerIcon;

    if (onlyNotProvided) {
      borderColor = colors.outline.withAlpha(80);
      bgColor = colors.surfaceContainerHighest.withAlpha(60);
      iconColor = colors.onSurfaceVariant;
      headerIcon = Icons.info_outline;
    } else if (hasHighMissing) {
      borderColor = Colors.red.shade400;
      bgColor = Colors.red.shade50;
      iconColor = Colors.red.shade700;
      headerIcon = Icons.error_outline;
    } else {
      borderColor = Colors.amber.shade600;
      bgColor = Colors.amber.shade50;
      iconColor = Colors.amber.shade900;
      headerIcon = Icons.warning_amber_rounded;
    }

    // Inspect which domains have gaps for action buttons
    final caseCov = coverage.where((c) => c.column == 'case_count').firstOrNull;
    final popCov = coverage.where((c) => c.column == 'population').firstOrNull;
    final climateCov = coverage.where((c) => c.column.startsWith('temperature') || c.column.startsWith('precipitation')).firstOrNull;

    final hasCaseGaps = caseCov != null && caseCov.missingCount > 0 && caseCov.reason != 'not_provided_by_source';
    final hasPopGaps = popCov != null && popCov.missingCount > 0 && popCov.reason != 'not_provided_by_source';
    final hasClimateGaps = climateCov != null && climateCov.missingCount > 0 && climateCov.reason != 'not_provided_by_source';

    // Alternative climate source
    String? altClimateSource;
    String? altClimateLabel;
    if (currentClimateSource == 'open-meteo-era5') {
      altClimateSource = 'nasa-power';
      altClimateLabel = 'NASA POWER';
    } else if (currentClimateSource == 'nasa-power') {
      altClimateSource = 'open-meteo-era5';
      altClimateLabel = 'Open-Meteo ERA5';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(headerIcon, color: iconColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    I18n.t('dataCoverageTitle'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...missingItems.map((item) {
              final label = _formatColumnLabel(item.column);
              final rangesStr = item.missingRanges
                  .map((r) => r.start == r.end ? r.start : '${r.start} – ${r.end}')
                  .join(', ');

              String reasonText = '';
              if (item.reason == 'outside_source_coverage') {
                final range = item.availableRange != null
                    ? '${item.availableRange!['start']} – ${item.availableRange!['end']}'
                    : (item.firstAvailable != null
                        ? '${item.firstAvailable} – ${item.lastAvailable ?? ''}'
                        : '');
                reasonText = I18n.t('reasonOutsideSourceCoverage').replaceAll('{range}', range);
              } else if (item.reason == 'gaps_inside_source') {
                reasonText = I18n.t('reasonGapsInsideSource');
              } else if (item.reason == 'not_provided_by_source') {
                reasonText = I18n.t('reasonNotProvidedBySource');
              } else if (item.reason != null) {
                reasonText = I18n.t('reasonUnknown');
              }

              final missingMsg = I18n.t('dataCoverageMissing')
                  .replaceAll('{missing}', '${item.missingCount}')
                  .replaceAll('{total}', '${item.totalPeriods}')
                  .replaceAll('{ranges}', rangesStr);

              final completePercent = (100.0 - item.missingPercent).clamp(0.0, 100.0);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$missingMsg (${completePercent.toStringAsFixed(1)} % complete)',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item.totalPeriods > 0
                            ? item.periodsWithValue / item.totalPeriods
                            : 0.0,
                        backgroundColor: colors.surface.withAlpha(150),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item.missingPercent > 50.0 ? Colors.red.shade700 : Colors.amber.shade800,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    if (reasonText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reasonText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (hasCaseGaps && onSearchCaseSources != null)
                  FilledButton.tonalIcon(
                    onPressed: onSearchCaseSources,
                    icon: const Icon(Icons.search, size: 16),
                    label: Text(I18n.t('searchOtherCaseSources')),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (hasCaseGaps &&
                    caseCov.reason == 'outside_source_coverage' &&
                    caseCov.firstAvailable != null &&
                    onAdjustDateRange != null) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      final start = _parsePeriod(caseCov.firstAvailable, isEnd: false);
                      final end = _parsePeriod(caseCov.lastAvailable, isEnd: true);
                      if (start != null && end != null) {
                        onAdjustDateRange!(start, end);
                      }
                    },
                    icon: const Icon(Icons.tune, size: 16),
                    label: Text(
                      I18n.t('adjustPeriodToAvailableData').replaceAll(
                        '{range}',
                        '${caseCov.firstAvailable} – ${caseCov.lastAvailable ?? ''}',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
                if (hasPopGaps && onSearchPopulationSources != null)
                  FilledButton.tonalIcon(
                    onPressed: onSearchPopulationSources,
                    icon: const Icon(Icons.people_alt_outlined, size: 16),
                    label: Text(I18n.t('searchPopulationSources')),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                if (hasClimateGaps &&
                    altClimateSource != null &&
                    onChangeClimateSource != null)
                  OutlinedButton.icon(
                    onPressed: () => onChangeClimateSource!(altClimateSource!),
                    icon: const Icon(Icons.wb_sunny_outlined, size: 16),
                    label: Text(
                      I18n.t('tryAlternativeClimateSource')
                          .replaceAll('{source}', altClimateLabel ?? ''),
                    ),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              I18n.t('coverageComparabilityNote'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
