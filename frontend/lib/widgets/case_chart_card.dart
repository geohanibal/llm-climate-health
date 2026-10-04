/// Interactive multi-series line chart with user toggles for case counts,
/// temperature, and precipitation.
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

class CaseChartCard extends StatefulWidget {
  final List<PeriodRecord> data;
  final String resolution;

  const CaseChartCard({super.key, required this.data, required this.resolution});

  @override
  State<CaseChartCard> createState() => _CaseChartCardState();
}

class _CaseChartCardState extends State<CaseChartCard> {
  static const _resolutionLabel = {
    'day': 'day',
    'month': 'month',
    'year': 'year',
    'decade': 'decade',
  };
  static final _compactFormat = NumberFormat.compact();

  late bool _showCases;
  late bool _showIncidence;
  late bool _showTemperature;
  late bool _showPrecipitation;

  @override
  void initState() {
    super.initState();
    _showCases = widget.data.any((r) => r.caseCount != null);
    _showIncidence = widget.data.any((r) => r.incidenceRatePer100k != null);
    _showTemperature = widget.data.any((r) => r.temperatureMeanC != null);
    _showPrecipitation = widget.data.any((r) => r.precipitationSumMm != null);
  }

  @override
  Widget build(BuildContext context) {
    final label = _resolutionLabel[widget.resolution] ?? widget.resolution;
    final hasCases = widget.data.any((r) => r.caseCount != null);
    final hasIncidence = widget.data.any((r) => r.incidenceRatePer100k != null);
    final hasTemps = widget.data.any((r) => r.temperatureMeanC != null);
    final hasPrecip = widget.data.any((r) => r.precipitationSumMm != null);

    if (!hasCases && !hasIncidence && !hasTemps && !hasPrecip) {
      return SectionCard(
        title: 'Case counts & climate per $label',
        leading: Icons.show_chart,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('No case or climate data available for this selection.')),
        ),
      );
    }

    final activeCount =
        (_showCases && hasCases ? 1 : 0) +
        (_showIncidence && hasIncidence ? 1 : 0) +
        (_showTemperature && hasTemps ? 1 : 0) +
        (_showPrecipitation && hasPrecip ? 1 : 0);

    return SectionCard(
      title: 'Case counts & climate per $label',
      leading: Icons.show_chart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggles(context, hasCases, hasIncidence, hasTemps, hasPrecip),
          const SizedBox(height: 12),
          if (activeCount == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'Select at least one metric above to display the chart series.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            )
          else
            SizedBox(
              height: 280,
              child: _buildChart(
                context,
                showCases: _showCases && hasCases,
                showIncidence: _showIncidence && hasIncidence,
                showTemps: _showTemperature && hasTemps,
                showPrecip: _showPrecipitation && hasPrecip,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggles(
    BuildContext context,
    bool hasCases,
    bool hasIncidence,
    bool hasTemps,
    bool hasPrecip,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final caseColor = isDark ? AppColors.chartCasesDark : AppColors.chartCases;
    final incidenceColor = isDark ? AppColors.chartIncidenceDark : AppColors.chartIncidence;
    final tempColor = isDark ? AppColors.chartTemperatureDark : AppColors.chartTemperature;
    final precipColor = isDark ? AppColors.chartPrecipitationDark : AppColors.chartPrecipitation;

    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (hasCases)
          FilterChip(
            label: const Text('Cases (left axis)'),
            selected: _showCases,
            selectedColor: caseColor.withAlpha(50),
            checkmarkColor: caseColor,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: _showCases ? caseColor : null,
            ),
            avatar: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: caseColor),
            ),
            onSelected: (val) => setState(() => _showCases = val),
          ),
        if (hasIncidence)
          FilterChip(
            label: const Text('Incidence / 100k'),
            selected: _showIncidence,
            selectedColor: incidenceColor.withAlpha(50),
            checkmarkColor: incidenceColor,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: _showIncidence ? incidenceColor : null,
            ),
            avatar: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: incidenceColor),
            ),
            onSelected: (val) => setState(() => _showIncidence = val),
          ),
        if (hasTemps)
          FilterChip(
            label: const Text('Temperature (right axis)'),
            selected: _showTemperature,
            selectedColor: tempColor.withAlpha(50),
            checkmarkColor: tempColor,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: _showTemperature ? tempColor : null,
            ),
            avatar: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: tempColor),
            ),
            onSelected: (val) => setState(() => _showTemperature = val),
          ),
        if (hasPrecip)
          FilterChip(
            label: const Text('Precipitation'),
            selected: _showPrecipitation,
            selectedColor: precipColor.withAlpha(50),
            checkmarkColor: precipColor,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: _showPrecipitation ? precipColor : null,
            ),
            avatar: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(shape: BoxShape.circle, color: precipColor),
            ),
            onSelected: (val) => setState(() => _showPrecipitation = val),
          ),
      ],
    );
  }

  Widget _buildChart(
    BuildContext context, {
    required bool showCases,
    required bool showIncidence,
    required bool showTemps,
    required bool showPrecip,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final caseColor = isDark ? AppColors.chartCasesDark : AppColors.chartCases;
    final incidenceColor = isDark ? AppColors.chartIncidenceDark : AppColors.chartIncidence;
    final tempColor = isDark ? AppColors.chartTemperatureDark : AppColors.chartTemperature;
    final precipColor = isDark ? AppColors.chartPrecipitationDark : AppColors.chartPrecipitation;
    final outline = Theme.of(context).colorScheme.outline;
    final gridColor = outline.withAlpha(isDark ? 50 : 80);
    final axisTextStyle =
        TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant);

    final caseRange = _paddedRange([
      for (final r in widget.data)
        if (r.caseCount != null) r.caseCount!,
    ]);
    final incidenceRange = _paddedRange([
      for (final r in widget.data)
        if (r.incidenceRatePer100k != null) r.incidenceRatePer100k!,
    ]);
    final tempRange = _paddedRange([
      for (final r in widget.data)
        if (r.temperatureMeanC != null) r.temperatureMeanC!,
    ]);
    final precipRange = _paddedRange([
      for (final r in widget.data)
        if (r.precipitationSumMm != null) r.precipitationSumMm!,
    ]);

    // Choose base coordinate range for chart Y axis:
    // Priority: Cases -> Incidence -> Precip -> Temp
    final baseRange = showCases
        ? caseRange
        : (showIncidence ? incidenceRange : (showPrecip ? precipRange : tempRange));

    double mapToChartY(double value, ({double min, double max, double span}) srcRange) {
      if (srcRange.span == 0) return (baseRange.min + baseRange.max) / 2;
      final t = (value - srcRange.min) / srcRange.span;
      return baseRange.min + t * baseRange.span;
    }

    double chartYToVal(double y, ({double min, double max, double span}) targetRange) {
      if (baseRange.span == 0) return targetRange.min;
      final t = (y - baseRange.min) / baseRange.span;
      return targetRange.min + t * targetRange.span;
    }

    final caseSpots = <FlSpot>[
      if (showCases)
        for (var i = 0; i < widget.data.length; i++)
          if (widget.data[i].caseCount != null) FlSpot(i.toDouble(), widget.data[i].caseCount!),
    ];

    final incidenceSpots = <FlSpot>[
      if (showIncidence)
        for (var i = 0; i < widget.data.length; i++)
          if (widget.data[i].incidenceRatePer100k != null)
            FlSpot(
              i.toDouble(),
              showCases
                  ? mapToChartY(widget.data[i].incidenceRatePer100k!, incidenceRange)
                  : widget.data[i].incidenceRatePer100k!,
            ),
    ];

    final tempSpots = <FlSpot>[
      if (showTemps)
        for (var i = 0; i < widget.data.length; i++)
          if (widget.data[i].temperatureMeanC != null)
            FlSpot(
              i.toDouble(),
              showCases || showIncidence || showPrecip
                  ? mapToChartY(widget.data[i].temperatureMeanC!, tempRange)
                  : widget.data[i].temperatureMeanC!,
            ),
    ];

    final precipSpots = <FlSpot>[
      if (showPrecip)
        for (var i = 0; i < widget.data.length; i++)
          if (widget.data[i].precipitationSumMm != null)
            FlSpot(
              i.toDouble(),
              showCases || showIncidence
                  ? mapToChartY(widget.data[i].precipitationSumMm!, precipRange)
                  : widget.data[i].precipitationSumMm!,
            ),
    ];

    final caseBar = LineChartBarData(
      spots: caseSpots,
      isCurved: true,
      barWidth: 2.5,
      color: caseColor,
      dotData: FlDotData(
        show: widget.data.length <= 15,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4,
          color: caseColor,
          strokeWidth: 2,
          strokeColor: Theme.of(context).colorScheme.surface,
        ),
      ),
      belowBarData: BarAreaData(show: true, color: caseColor.withAlpha(25)),
    );

    final incidenceBar = LineChartBarData(
      spots: incidenceSpots,
      isCurved: true,
      barWidth: 2.2,
      color: incidenceColor,
      dotData: FlDotData(
        show: widget.data.length <= 15,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4,
          color: incidenceColor,
          strokeWidth: 2,
          strokeColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );

    final tempBar = LineChartBarData(
      spots: tempSpots,
      isCurved: true,
      barWidth: 2.2,
      color: tempColor,
      dotData: FlDotData(
        show: widget.data.length <= 15,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 4,
          color: tempColor,
          strokeWidth: 2,
          strokeColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );

    final precipBar = LineChartBarData(
      spots: precipSpots,
      isCurved: true,
      barWidth: 2.0,
      color: precipColor,
      dashArray: [5, 4],
      dotData: FlDotData(
        show: widget.data.length <= 15,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3.5,
          color: precipColor,
          strokeWidth: 1.5,
          strokeColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );

    final showRightAxis = showTemps && (showCases || showIncidence || showPrecip);

    return LineChart(
      LineChartData(
        minY: baseRange.min,
        maxY: baseRange.max,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showCases || showIncidence || showPrecip || showTemps,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(
                _compactFormat.format(value),
                style: axisTextStyle.copyWith(
                  color: showCases
                      ? caseColor
                      : (showIncidence
                          ? incidenceColor
                          : (showPrecip ? precipColor : tempColor)),
                ),
              ),
            ),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showRightAxis,
              reservedSize: 44,
              getTitlesWidget: (value, meta) => Text(
                '${chartYToVal(value, tempRange).round()}°',
                style: axisTextStyle.copyWith(color: tempColor),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: (widget.data.length / 6).clamp(1, widget.data.length).toDouble(),
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
              final idx = touchedSpots.isEmpty ? -1 : touchedSpots.first.x.toInt();
              if (idx < 0 || idx >= widget.data.length) return [];
              final record = widget.data[idx];
              final period = record.period;

              return [
                for (var i = 0; i < touchedSpots.length; i++)
                  _tooltipItem(
                    context,
                    prefix: i == 0 ? '$period\n' : '',
                    spot: touchedSpots[i],
                    incidenceBar: incidenceBar,
                    tempBar: tempBar,
                    precipBar: precipBar,
                    caseColor: caseColor,
                    incidenceColor: incidenceColor,
                    tempColor: tempColor,
                    precipColor: precipColor,
                    record: record,
                  ),
              ];
            },
          ),
        ),
        lineBarsData: [
          if (showCases) caseBar,
          if (showIncidence) incidenceBar,
          if (showTemps) tempBar,
          if (showPrecip) precipBar,
        ],
      ),
    );
  }

  LineTooltipItem _tooltipItem(
    BuildContext context, {
    required String prefix,
    required LineBarSpot spot,
    required LineChartBarData incidenceBar,
    required LineChartBarData tempBar,
    required LineChartBarData precipBar,
    required Color caseColor,
    required Color incidenceColor,
    required Color tempColor,
    required Color precipColor,
    required PeriodRecord record,
  }) {
    final String label;
    final Color color;

    if (spot.bar == tempBar) {
      label = Formatting.temperature(record.temperatureMeanC);
      color = tempColor;
    } else if (spot.bar == precipBar) {
      label = Formatting.precipitation(record.precipitationSumMm);
      color = precipColor;
    } else if (spot.bar == incidenceBar) {
      label = Formatting.incidenceRate(record.incidenceRatePer100k);
      color = incidenceColor;
    } else {
      label = Formatting.caseCount(record.caseCount);
      color = caseColor;
    }

    return LineTooltipItem(
      prefix,
      TextStyle(color: Theme.of(context).colorScheme.onInverseSurface.withAlpha(190), fontSize: 11),
      children: [
        TextSpan(
          text: label,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _bottomTitle(BuildContext context, double value) {
    final idx = value.toInt();
    if (idx < 0 || idx >= widget.data.length) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        widget.data[idx].period,
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
