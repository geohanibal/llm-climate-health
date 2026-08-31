/// Summary KPI statistics card displaying aggregate metrics over the dataset.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../core/formatting.dart';
import '../models/period_record.dart';

class KpiSummaryCard extends StatelessWidget {
  final List<PeriodRecord> data;
  final String resolution;

  const KpiSummaryCard({super.key, required this.data, required this.resolution});

  static final _numberFormat = NumberFormat.decimalPattern('en_US');

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final casesList = [for (final r in data) if (r.caseCount != null) r.caseCount!];
    final popList = [for (final r in data) if (r.population != null) r.population!];
    final tempList = [for (final r in data) if (r.temperatureMeanC != null) r.temperatureMeanC!];
    final precipList = [for (final r in data) if (r.precipitationSumMm != null) r.precipitationSumMm!];

    final totalCases = casesList.isEmpty ? null : casesList.reduce((a, b) => a + b);
    final avgPop = popList.isEmpty ? null : popList.reduce((a, b) => a + b) / popList.length;
    final avgTemp = tempList.isEmpty ? null : tempList.reduce((a, b) => a + b) / tempList.length;
    final totalPrecip = precipList.isEmpty ? null : precipList.reduce((a, b) => a + b);
    final avgPrecip = precipList.isEmpty ? null : totalPrecip! / precipList.length;

    PeriodRecord? peakRecord;
    if (casesList.isNotEmpty) {
      peakRecord = data.reduce((curr, next) {
        final currV = curr.caseCount ?? -1;
        final nextV = next.caseCount ?? -1;
        return currV >= nextV ? curr : next;
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final caseColor = isDark ? AppColors.chartCasesDark : AppColors.chartCases;
    final tempColor = isDark ? AppColors.chartTemperatureDark : AppColors.chartTemperature;
    final precipColor = isDark ? AppColors.chartPrecipitationDark : AppColors.chartPrecipitation;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final popSubtitle = avgPop != null
            ? '${casesList.length} periods (Pop: ${NumberFormat.compact().format(avgPop)})'
            : '${casesList.length} reported periods';

        final peakSubtitle = peakRecord != null && peakRecord.caseCount != null
            ? '${_numberFormat.format(peakRecord.caseCount!.round())} cases' +
                (peakRecord.incidenceRatePer100k != null
                    ? ' (${peakRecord.incidenceRatePer100k!.toStringAsFixed(1)}/100k)'
                    : '')
            : 'No peak data';

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiTile(
              width: isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
              title: 'Total Cases',
              value: totalCases != null ? _numberFormat.format(totalCases.round()) : '—',
              subtitle: popSubtitle,
              icon: Icons.personal_injury_outlined,
              color: caseColor,
            ),
            _KpiTile(
              width: isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
              title: 'Avg Temperature',
              value: avgTemp != null ? Formatting.temperature(avgTemp) : '—',
              subtitle: tempList.isNotEmpty
                  ? 'Min: ${tempList.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}° / Max: ${tempList.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}°'
                  : 'No temp data',
              icon: Icons.thermostat_outlined,
              color: tempColor,
            ),
            _KpiTile(
              width: isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
              title: 'Total Rainfall',
              value: totalPrecip != null ? '${totalPrecip.toStringAsFixed(0)} mm' : '—',
              subtitle: avgPrecip != null ? 'Avg: ${avgPrecip.toStringAsFixed(1)} mm/period' : 'No precip data',
              icon: Icons.water_drop_outlined,
              color: precipColor,
            ),
            _KpiTile(
              width: isMobile ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4,
              title: 'Peak Outbreak',
              value: peakRecord != null && peakRecord.caseCount != null
                  ? peakRecord.period
                  : '—',
              subtitle: peakSubtitle,
              icon: Icons.trending_up_outlined,
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiTile({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: colors.onSurfaceVariant.withAlpha(180),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
