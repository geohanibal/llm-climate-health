/// Generates downloadable academic summary PDFs for scientific literature items
/// and custom user-provided publications on the Climate-Health Platform.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/localization.dart';
import '../models/literature_item.dart';
import 'browser_download_service.dart';

class LiteraturePdfService {
  static final PdfColor _brand = PdfColor.fromInt(0xFF1F6F5C);
  static final PdfColor _darkText = PdfColor.fromInt(0xFF1E293B);
  static final PdfColor _gray = PdfColor.fromInt(0xFF64748B);
  static final PdfColor _cardBg = PdfColor.fromInt(0xFFF8FAFC);
  static final PdfColor _borderColor = PdfColor.fromInt(0xFFE2E8F0);

  final BrowserDownloadService download;

  const LiteraturePdfService({this.download = const BrowserDownloadService()});

  static String _clean(String text) {
    return text
        .replaceAll('—', ' - ')
        .replaceAll('–', '-')
        .replaceAll('•', '-')
        .replaceAll('°C', ' deg C')
        .replaceAll('°', ' deg')
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('’', "'")
        .replaceAll('≥', '>=')
        .replaceAll('≤', '<=')
        .replaceAll('±', '+/-');
  }

  Future<void> downloadLiteraturePdf({
    required LiteratureItem item,
    required AppLanguage lang,
  }) async {
    final bytes = await buildDocumentBytes(item: item, lang: lang);
    final safeFileName = '${item.tag.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '_')}_summary.pdf';
    download.downloadBytes(bytes, 'application/pdf', safeFileName);
  }

  Future<Uint8List> buildDocumentBytes({
    required LiteratureItem item,
    required AppLanguage lang,
  }) async {
    final doc = pw.Document();

    // Use English academic text for standard corpora to ensure crisp universal formatting
    // and full Unicode compatibility with standard Helvetica fonts
    final focus = _clean(item.focusEn.isNotEmpty ? item.focusEn : item.getFocus(lang));
    final differences = _clean(item.differencesEn.isNotEmpty ? item.differencesEn : item.getDifferences(lang));
    final abstractText = _clean(item.abstractEn.isNotEmpty ? item.abstractEn : item.getAbstract(lang));
    final methodology = _clean(item.methodologyEn.isNotEmpty ? item.methodologyEn : item.getMethodology(lang));
    final keyFindings = _clean(item.keyFindingsEn.isNotEmpty ? item.keyFindingsEn : item.getKeyFindings(lang));
    final title = _clean(item.title);
    final authors = _clean(item.authors);
    final journal = _clean(item.journal);
    final citation = _clean(item.citation);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'LLM-Climate-Health Platform',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _brand),
                  ),
                  pw.Text(
                    'University of Bremen - Bachelor Thesis - Sergi Koniashvili',
                    style: pw.TextStyle(fontSize: 9, color: _gray),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _cardBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: _borderColor),
                ),
                child: pw.Text(
                  _clean(item.tag),
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _brand),
                ),
              ),
            ],
          ),
          pw.Divider(color: _brand, thickness: 1.5, height: 20),

          // Title & Authors
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _darkText),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '$authors - $journal (${item.year})',
            style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: _gray),
          ),
          if (item.url != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Official Publication: ${item.url!}',
              style: pw.TextStyle(fontSize: 9, color: _brand),
            ),
          ],
          pw.SizedBox(height: 16),

          // Section 1: Abstract / Executive Summary
          _buildSectionHeader('1. Executive Summary & Abstract'),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _cardBg,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Text(
              abstractText,
              style: pw.TextStyle(fontSize: 10.5, lineSpacing: 2, color: _darkText),
            ),
          ),
          pw.SizedBox(height: 14),

          // Section 2: Research Focus & Epidemiological Scope
          _buildSectionHeader('2. Research Focus & Epidemiological Scope'),
          pw.Text(
            focus,
            style: pw.TextStyle(fontSize: 10.5, lineSpacing: 2, color: _darkText),
          ),
          pw.SizedBox(height: 14),

          // Section 3: Methodology & Surveillance Mechanisms
          _buildSectionHeader('3. Methodology & Surveillance Mechanisms'),
          pw.Text(
            methodology,
            style: pw.TextStyle(fontSize: 10.5, lineSpacing: 2, color: _darkText),
          ),
          pw.SizedBox(height: 14),

          // Section 4: Climate Transmission Thresholds & Lag Effects
          _buildSectionHeader('4. Climate Transmission Thresholds & Key Findings'),
          pw.Text(
            keyFindings,
            style: pw.TextStyle(fontSize: 10.5, lineSpacing: 2, color: _darkText),
          ),
          pw.SizedBox(height: 14),

          // Section 5: Comparative Differences & AI Grounding Role
          _buildSectionHeader('5. Distinct Methodology & Role in Platform Analysis'),
          pw.Text(
            differences,
            style: pw.TextStyle(fontSize: 10.5, lineSpacing: 2, color: _darkText),
          ),
          pw.SizedBox(height: 16),

          // Section 6: Formal Academic Citation
          _buildSectionHeader('6. Academic Citation'),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: _cardBg,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Text(
              citation,
              style: pw.TextStyle(fontSize: 9.5, fontStyle: pw.FontStyle.italic, color: _darkText),
            ),
          ),
          pw.SizedBox(height: 20),

          // Footer info
          pw.Divider(color: _borderColor, thickness: 0.8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Generated via LLM-Climate-Health Platform',
                style: pw.TextStyle(fontSize: 8.5, color: _gray),
              ),
              pw.Text(
                'In-Context Grounding & RAG Framework',
                style: pw.TextStyle(fontSize: 8.5, color: _gray),
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: _brand,
        ),
      ),
    );
  }
}
