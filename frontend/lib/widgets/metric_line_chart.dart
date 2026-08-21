/// Reusable single-series line chart for one metric (case counts,
/// temperature, ...) over the requested period. [CaseChartCard] and
/// [TemperatureChartCard] both delegate their drawing to this widget so the
/// two "small multiples" (see their doc comments) share identical mark
/// specs, gridlines, and hover/tooltip behavior — deliberately two aligned
/// single-axis charts rather than one dual-axis chart, since case counts
/// and temperature live on very different scales and a shared axis would
/// invent a correlation that isn't in the data.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/period_record.dart';

class MetricLineChart extends StatelessWidget {
  final List<PeriodRecord> data;
  final double? Function(PeriodRecord) valueOf;
  final String Function(double) formatValue;
  final String noDataMessage;
  final Color lightColor;
  final Color darkColor;

  const MetricLineChart({
    super.key,
    required this.data,
    required this.valueOf,
    required this.formatValue,
    required this.noDataMessage,
    required this.lightColor,
    required this.darkColor,
  });

  static final _compactFormat = NumberFormat.compact();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seriesColor = isDark ? darkColor : lightColor;
    final outline = Theme.of(context).colorScheme.outline;
    final gridColor = outline.withValues(alpha: isDark ? 0.25 : 0.4);

    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        if (valueOf(data[i]) case final value?) FlSpot(i.toDouble(), value),
    ];
    if (spots.isEmpty) {
      return Center(child: Text(noDataMessage));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) => Text(
                _compactFormat.format(value),
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
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
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              final period = data[spot.x.toInt()].period;
              return LineTooltipItem(
                '$period\n',
                TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.75),
                  fontSize: 11,
                ),
                children: [
                  TextSpan(
                    text: formatValue(spot.y),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          getTouchedSpotIndicator: (barData, indicators) => indicators.map((_) {
            return TouchedSpotIndicatorData(
              FlLine(color: seriesColor.withValues(alpha: 0.4), strokeWidth: 1),
              FlDotData(
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: seriesColor,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            );
          }).toList(),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            color: seriesColor,
            dotData: FlDotData(
              show: data.length <= 15,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: seriesColor,
                strokeWidth: 2,
                strokeColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(show: true, color: seriesColor.withValues(alpha: 0.1)),
          ),
        ],
      ),
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
}
