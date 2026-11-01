/// Tabular view of the integrated dataset, with CSV/JSON download buttons
/// so the user can save the result to their own computer.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../core/formatting.dart';
import '../models/period_record.dart';
import '../services/dataset_export_service.dart';
import 'section_card.dart';

class DatasetTableCard extends StatelessWidget {
  final List<PeriodRecord> data;
  static const _exportService = DatasetExportService();

  const DatasetTableCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final hasMin = data.any((r) => r.temperatureMinC != null);
    final hasMax = data.any((r) => r.temperatureMaxC != null);

    return SectionCard(
      title: 'Integrated dataset',
      leading: Icons.table_chart_outlined,
      trailing: Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _exportService.export(data, ExportFormat.csv),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('CSV'),
          ),
          OutlinedButton.icon(
            onPressed: () => _exportService.export(data, ExportFormat.json),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('JSON'),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Period')),
            const DataColumn(label: Text('Cases')),
            const DataColumn(label: Text('Population')),
            const DataColumn(label: Text('Incidence / 100k')),
            const DataColumn(label: Text('Temp mean (°C)')),
            if (hasMin) const DataColumn(label: Text('Temp min (°C)')),
            if (hasMax) const DataColumn(label: Text('Temp max (°C)')),
            const DataColumn(label: Text('Precip sum (mm)')),
          ],
          rows: data
              .map(
                (r) => DataRow(cells: [
                  DataCell(Text(r.period)),
                  DataCell(Text(Formatting.caseCount(r.caseCount))),
                  DataCell(Text(Formatting.population(r.population))),
                  DataCell(Text(Formatting.incidenceRate(r.incidenceRatePer100k))),
                  DataCell(Text(Formatting.temperature(r.temperatureMeanC))),
                  if (hasMin) DataCell(Text(Formatting.temperature(r.temperatureMinC))),
                  if (hasMax) DataCell(Text(Formatting.temperature(r.temperatureMaxC))),
                  DataCell(Text(Formatting.precipitation(r.precipitationSumMm))),
                ]),
              )
              .toList(),
        ),
      ),
    );
  }
}
