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
          pw.Text('Disease: $disease    Region: $region'),
          pw.Text(
            'Generated: ${result.lastVerified}${result.cached ? " (from cache)" : ""}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          _sectionTitle('Pipeline steps'),
          ..._numberedList(result.steps),
          pw.SizedBox(height: 12),
          _sectionTitle('Explanation'),
          pw.Text(result.explanation, style: const pw.TextStyle(fontSize: 10)),
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
          text,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _brand),
        ),
      );

  List<pw.Widget> _numberedList(List<String> items) => [
        for (var i = 0; i < items.length; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text('${i + 1}. ${items[i]}', style: const pw.TextStyle(fontSize: 10)),
          ),
      ];

  List<pw.Widget> _bulletList(List<String> items) => [
        for (final item in items)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text('-  $item', style: const pw.TextStyle(fontSize: 10)),
          ),
      ];

  pw.Widget _datasetTable(IntegrationResult result) {
    return pw.TableHelper.fromTextArray(
      headers: const [
        'Period',
        'Cases',
        'Population',
        'Incidence / 100k',
        'Temp mean (°C)',
        'Precip sum (mm)',
      ],
      data: result.data
          .map((r) => [
                r.period,
                Formatting.caseCount(r.caseCount),
                Formatting.population(r.population),
                Formatting.incidenceRate(r.incidenceRatePer100k),
                Formatting.temperature(r.temperatureMeanC),
                Formatting.precipitation(r.precipitationSumMm),
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
