/// Builds a downloadable PDF report summarizing one integration run (steps,
/// explanation, dataset, and sources), so results can be saved/shared
/// outside the browser tab.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/formatting.dart';
import '../models/integration_result.dart';
import 'browser_download_service.dart';

class ReportPdfService {
  static final PdfColor _brand = PdfColor.fromInt(0xFF1F6F5C);

  /// Injectable so tests can supply a fake and assert on what would have
  /// been downloaded, without touching the browser.
  final BrowserDownloadService download;

  const ReportPdfService({this.download = const BrowserDownloadService()});

  static String _clean(String text) => text
      .replaceAll('—', ' - ')
      .replaceAll('–', '-')
      .replaceAll('•', '-')
      .replaceAll('°C', ' deg C')
      .replaceAll('°', ' deg');

  Future<void> downloadReport({
    required IntegrationResult result,
    required String disease,
    required String region,
  }) async {
    final bytes = await buildDocumentBytes(result: result, disease: disease, region: region);
    download.downloadBytes(bytes, 'application/pdf', 'climate_health_report.pdf');
  }

  /// Builds the report's PDF bytes without triggering a browser download —
  /// the part of report generation that's actually testable on the Dart VM.
  Future<Uint8List> buildDocumentBytes({
    required IntegrationResult result,
    required String disease,
    required String region,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            'Climate-Health Data Integration Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _brand),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Disease: ${_clean(disease)}    Region: ${_clean(region)}'),
          pw.Text(
            'Generated: ${result.lastVerified}${result.cached ? " (from cache)" : ""}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          _sectionTitle('Pipeline steps'),
          ..._numberedList(result.steps),
          pw.SizedBox(height: 12),
          _sectionTitle('Explanation'),
          pw.Text(_clean(result.explanation), style: const pw.TextStyle(fontSize: 10)),
          if (result.statisticalSummary != null) ...[
            pw.SizedBox(height: 12),
            _sectionTitle('Statistical & Lag Correlation Analysis'),
            if (result.statisticalSummary!.correlations.isNotEmpty)
              _statsTable(result.statisticalSummary!),
            if (result.statisticalSummary!.scientificDisclaimer.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                _clean(result.statisticalSummary!.scientificDisclaimer),
                style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey700),
              ),
            ],
          ],
          pw.SizedBox(height: 12),
          _sectionTitle('Integrated dataset'),
          _datasetTable(result),
          pw.SizedBox(height: 12),
          _sectionTitle('Sources'),
          ..._bulletList(result.sources),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _sectionTitle(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(
          _clean(text),
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _brand),
        ),
      );

  List<pw.Widget> _numberedList(List<String> items) => [
        for (var i = 0; i < items.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text('${i + 1}. ${_clean(items[i])}', style: const pw.TextStyle(fontSize: 10)),
          ),
      ];

  List<pw.Widget> _bulletList(List<String> items) => [
        for (final item in items)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text('-  ${_clean(item)}', style: const pw.TextStyle(fontSize: 10)),
          ),
      ];

  pw.Widget _statsTable(StatisticalSummary stats) {
    return pw.TableHelper.fromTextArray(
      headers: const [
        'Variable',
        'Time Lag',
        'Pearson r',
        'p-value',
        'Spearman rho',
        'Significant (p<0.05)',
      ],
      data: stats.correlations
          .map((c) => [
                c.variable == 'temperature' ? 'Temperature' : 'Precipitation',
                c.lagPeriods == 0 ? 'Lag 0 (same)' : 'Lag ${c.lagPeriods}',
                c.pearsonR != null ? c.pearsonR!.toStringAsFixed(3) : '-',
                c.pearsonP != null ? (c.pearsonP! < 0.001 ? '< 0.001' : c.pearsonP!.toStringAsFixed(3)) : '-',
                c.spearmanRho != null ? c.spearmanRho!.toStringAsFixed(3) : '-',
                c.significant ? 'Yes *' : 'No',
              ])
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: _brand),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      border: null,
    );
  }

  pw.Widget _datasetTable(IntegrationResult result) {
    return pw.TableHelper.fromTextArray(
      headers: const [
        'Period',
        'Cases',
        'Population',
        'Incidence / 100k',
        'Temp mean (deg C)',
        'Precip sum (mm)',
      ],
      data: result.data
          .map((r) => [
                r.period,
                _clean(Formatting.caseCount(r.caseCount)),
                _clean(Formatting.population(r.population)),
                _clean(Formatting.incidenceRate(r.incidenceRatePer100k)),
                r.temperatureMeanC != null ? '${r.temperatureMeanC!.toStringAsFixed(1)}' : '-',
                r.precipitationSumMm != null ? '${r.precipitationSumMm!.toStringAsFixed(0)}' : '-',
              ])
          .toList(),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
      headerDecoration: pw.BoxDecoration(color: _brand),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      border: null,
    );
  }
}
