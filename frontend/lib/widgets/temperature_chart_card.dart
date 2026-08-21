/// Line chart of mean temperature over the requested period, at whatever
/// resolution (month/year/decade) the backend resolved. Drawn as its own
/// small-multiple card, aligned by period with [CaseChartCard] right above
/// it, rather than sharing one dual-axis chart — see [MetricLineChart]'s
/// doc comment for why.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../app.dart';
import '../core/formatting.dart';
import '../models/period_record.dart';
import 'metric_line_chart.dart';
import 'section_card.dart';

class TemperatureChartCard extends StatelessWidget {
  final List<PeriodRecord> data;
  final String resolution;

  const TemperatureChartCard({super.key, required this.data, required this.resolution});

  static const _resolutionLabel = {
    'month': 'month',
    'year': 'year',
    'decade': 'decade',
  };

  @override
  Widget build(BuildContext context) {
    final label = _resolutionLabel[resolution] ?? resolution;
    return SectionCard(
      title: 'Temperature per $label',
      leading: Icons.thermostat_outlined,
      child: SizedBox(
        height: 260,
        child: MetricLineChart(
          data: data,
          valueOf: (r) => r.temperatureMeanC,
          formatValue: (v) => Formatting.temperature(v),
          noDataMessage: 'No temperature data available for this selection.',
          lightColor: AppColors.chartTemperature,
          darkColor: AppColors.chartTemperatureDark,
        ),
      ),
    );
  }
}
