/// Combined case-count + temperature line chart over the requested period,
/// at whatever resolution (month/year/decade) the backend resolved.
///
/// Case counts (tens to hundreds) and temperature (degrees C) sit on very
/// different scales, so this is a genuine dual-axis chart: case counts read
/// off the left axis in their own units, temperature is rescaled onto the
/// same visual range and read off the right axis in its own units. That
/// rescaling is a deliberate readability trade-off (requested explicitly,
/// after flagging the standard "two charts instead" alternative) — the two
/// axes are independent, so where the lines cross or sit relative to each
/// other on screen carries no meaning, only each line's own shape against
/// its own axis does. A legend and matching axis colors keep it clear which
/// line reads off which side.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../core/formatting.dart';
import '../models/period_record.dart';
import 'section_card.dart';

class CaseChartCard extends StatelessWidget {
  final List<PeriodRecord> data;
  final String resolution;

  const CaseChartCard({super.key, required this.data, required this.resolution});

  static const _resolutionLabel = {
    'month': 'month',
    'year': 'year',
    'decade': 'decade',
  };
  static final _compactFormat = NumberFormat.compact();

  @override
  Widget build(BuildContext context) {
    final label = _resolutionLabel[resolution] ?? resolution;
    final hasCases = data.any((r) => r.caseCount != null);
    final hasTemps = data.any((r) => r.temperatureMeanC != null);

    return SectionCard(
      title: 'Case counts & temperature per $label',
      leading: Icons.show_chart,
      child: !hasCases && !hasTemps
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No case or temperature data available for this selection.')),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegend(context, hasCases, hasTemps),
                const SizedBox(height: 8),
                SizedBox(height: 260, child: _buildChart(context, hasCases, hasTemps)),
              ],
            ),
    );
  }

  Widget _buildLegend(BuildContext context, bool hasCases, bool hasTemps) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        if (hasCases) _legendEntry(context, isDark ? AppColors.chartCasesDark : AppColors.chartCases, 'Case counts (left axis)'),
        if (hasTemps)
          _legendEntry(
            context,
            isDark ? AppColors.chartTemperatureDark : AppColors.chartTemperature,
            'Temperature (right axis)',
          ),
      ],
    );
  }

  Widget _legendEntry(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 3, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildChart(BuildContext context, bool hasCases, bool hasTemps) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final caseColor = isDark ? AppColors.chartCasesDark : AppColors.chartCases;
    final tempColor = isDark ? AppColors.chartTemperatureDark : AppColors.chartTemperature;
    final outline = Theme.of(context).colorScheme.outline;
    final gridColor = outline.withValues(alpha: isDark ? 0.25 : 0.4);
    final axisTextStyle = TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant);

    final caseRange = _paddedRange([
      for (final r in data)
        if (r.caseCount != null) r.caseCount!,
    ]);
    final tempRange = _paddedRange([
      for (final r in data)
        if (r.temperatureMeanC != null) r.temperatureMeanC!,
    ]);

    // Maps a real temperature onto the case-count axis's coordinate space
    // (and back again for the right-axis labels/tooltip) — the mechanism
    // that lets one shared plot area host both independently-scaled lines.
    double tempToChartY(double temp) {
      if (tempRange.span == 0) return (caseRange.min + caseRange.max) / 2;
      final t = (temp - tempRange.min) / tempRange.span;
      return caseRange.min + t * caseRange.span;
    }

    double chartYToTemp(double y) {
      if (caseRange.span == 0) return tempRange.min;
      final t = (y - caseRange.min) / caseRange.span;
      return tempRange.min + t * tempRange.span;
    }

    final caseSpots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        if (data[i].caseCount != null) FlSpot(i.toDouble(), data[i].caseCount!),
    ];
    final tempSpots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        if (data[i].temperatureMeanC != null) FlSpot(i.toDouble(), tempToChartY(data[i].temperatureMeanC!)),
    ];

    final caseBar = LineChartBarData(
      spots: caseSpots,
      isCurved: true,
      barWidth: 2,
      color: caseColor,
      dotData: FlDotData(
        show: data.length <= 15,
        getDotPainter: (spot, percent, bar, index) =>
            FlDotCirclePainter(radius: 4, color: caseColor, strokeWidth: 2, strokeColor: Theme.of(context).colorScheme.surface),
      ),
      belowBarData: BarAreaData(show: true, color: caseColor.withValues(alpha: 0.1)),
    );
    final tempBar = LineChartBarData(
      spots: tempSpots,
      isCurved: true,
      barWidth: 2,
      color: tempColor,
      dotData: FlDotData(
        show: data.length <= 15,
        getDotPainter: (spot, percent, bar, index) =>
            FlDotCirclePainter(radius: 4, color: tempColor, strokeWidth: 2, strokeColor: Theme.of(context).colorScheme.surface),
      ),
    );

    return LineChart(
      LineChartData(
        minY: caseRange.min,
        maxY: caseRange.max,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: hasCases,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(_compactFormat.format(value), style: axisTextStyle.copyWith(color: caseColor)),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: hasTemps,
              reservedSize: 44,
              getTitlesWidget: (value, meta) =>
                  Text('${chartYToTemp(value).round()}°', style: axisTextStyle.copyWith(color: tempColor)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: (data.length / 6).clamp(1, data.length).toDouble(),
              getTitlesWidget: (value, meta) => _bottomTitle(context, value),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(bottom: BorderSide(color: gridColor), left: BorderSide(color: gridColor)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipColor: (_) => Theme.of(context).colorScheme.inverseSurface,
            getTooltipItems: (touchedSpots) {
              final period = touchedSpots.isEmpty ? '' : data[touchedSpots.first.x.toInt()].period;
              return [
                for (var i = 0; i < touchedSpots.length; i++)
                  _tooltipItem(
                    context,
                    prefix: i == 0 ? '$period\n' : '',
                    isTemp: touchedSpots[i].bar == tempBar,
                    rawValue: touchedSpots[i].bar == tempBar ? chartYToTemp(touchedSpots[i].y) : touchedSpots[i].y,
                    color: touchedSpots[i].bar == tempBar ? tempColor : caseColor,
                  ),
              ];
            },
          ),
          getTouchedSpotIndicator: (barData, indicators) => indicators.map((_) {
            final color = barData == tempBar ? tempColor : caseColor;
            return TouchedSpotIndicatorData(
              FlLine(color: color.withValues(alpha: 0.4), strokeWidth: 1),
              FlDotData(
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(radius: 4, color: color, strokeWidth: 2, strokeColor: Theme.of(context).colorScheme.surface),
              ),
            );
          }).toList(),
        ),
        lineBarsData: [
          if (hasCases) caseBar,
          if (hasTemps) tempBar,
        ],
      ),
    );
  }

  LineTooltipItem _tooltipItem(
    BuildContext context, {
    required String prefix,
    required bool isTemp,
    required double rawValue,
    required Color color,
  }) {
    final value = isTemp ? Formatting.temperature(rawValue) : Formatting.caseCount(rawValue);
    return LineTooltipItem(
      prefix,
      TextStyle(color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.75), fontSize: 11),
      children: [
        TextSpan(
          text: value,
          style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _bottomTitle(BuildContext context, double value) {
    final idx = value.toInt();
    if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        data[idx].period,
        style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }

  ({double min, double max, double span}) _paddedRange(Iterable<double> values) {
    if (values.isEmpty) return (min: 0, max: 1, span: 1);
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final rawSpan = maxV - minV;
    final pad = rawSpan == 0 ? math.max(minV.abs() * 0.1, 1.0) : rawSpan * 0.1;
    final min = minV - pad;
    final max = maxV + pad;
    return (min: min, max: max, span: max - min);
  }
}
