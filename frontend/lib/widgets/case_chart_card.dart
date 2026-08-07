/// Line chart of case counts over the requested period, at whatever
/// resolution (month/year/decade) the backend resolved.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    return SectionCard(
      title: 'Case counts per $label',
      child: SizedBox(height: 260, child: _buildChart()),
    );
  }

  Widget _buildChart() {
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        if (data[i].caseCount != null) FlSpot(i.toDouble(), data[i].caseCount!),
    ];
    if (spots.isEmpty) {
      return const Center(child: Text('No case data available for this selection.'));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 52,
              getTitlesWidget: (value, meta) => Text(
                _compactFormat.format(value),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: (data.length / 6).clamp(1, data.length).toDouble(),
              getTitlesWidget: _bottomTitle,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: const Color(0xFF1F6F5C),
            dotData: FlDotData(show: data.length <= 15),
            belowBarData: BarAreaData(show: true, color: const Color(0x331F6F5C)),
          ),
        ],
      ),
    );
  }

  Widget _bottomTitle(double value, TitleMeta meta) {
    final idx = value.toInt();
    if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(data[idx].period, style: const TextStyle(fontSize: 10)),
    );
  }
}
