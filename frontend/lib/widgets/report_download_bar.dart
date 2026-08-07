/// Action bar offering a one-click PDF export of the whole results view
/// (steps, explanation, dataset, and sources combined into one report).
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../models/integration_result.dart';
import '../services/report_pdf_service.dart';

class ReportDownloadBar extends StatefulWidget {
  final IntegrationResult result;

  const ReportDownloadBar({super.key, required this.result});

  @override
  State<ReportDownloadBar> createState() => _ReportDownloadBarState();
}

class _ReportDownloadBarState extends State<ReportDownloadBar> {
  static const _pdfService = ReportPdfService();
  bool _isGenerating = false;

  Future<void> _download() async {
    setState(() => _isGenerating = true);
    try {
      await _pdfService.downloadReport(
        result: widget.result,
        disease: widget.result.disease,
        region: widget.result.region,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate the PDF report: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton.icon(
        onPressed: _isGenerating ? null : _download,
        icon: _isGenerating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.picture_as_pdf_outlined, size: 18),
        label: Text(_isGenerating ? 'Generating…' : 'Download full report (PDF)'),
      ),
    );
  }
}
