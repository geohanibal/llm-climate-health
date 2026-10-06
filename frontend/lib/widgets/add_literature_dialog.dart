/// Dialog allowing researchers and users to input custom scientific literature
/// and publications to ground the platform's AI Copilot and comparative evaluations.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
library;

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../models/literature_item.dart';

class AddLiteratureDialog extends StatefulWidget {
  final ValueChanged<LiteratureItem>? onLiteratureAdded;

  const AddLiteratureDialog({
    super.key,
    this.onLiteratureAdded,
  });

  static Future<LiteratureItem?> show(
    BuildContext context, {
    ValueChanged<LiteratureItem>? onLiteratureAdded,
  }) {
    return showDialog<LiteratureItem>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddLiteratureDialog(onLiteratureAdded: onLiteratureAdded),
    );
  }

  @override
  State<AddLiteratureDialog> createState() => _AddLiteratureDialogState();
}

class _AddLiteratureDialogState extends State<AddLiteratureDialog> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _authorsController = TextEditingController();
  final _yearController = TextEditingController(text: DateTime.now().year.toString());
  final _journalController = TextEditingController();
  final _urlController = TextEditingController();
  final _focusController = TextEditingController();
  final _differencesController = TextEditingController();

  String? _attachedFileName;
  String? _attachedFileContent;
  bool _isPickingFile = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _yearController.dispose();
    _journalController.dispose();
    _urlController.dispose();
    _focusController.dispose();
    _differencesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'csv', 'md'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        String? content;
        if (file.bytes != null && (file.extension == 'txt' || file.extension == 'md')) {
          try {
            content = utf8.decode(file.bytes!);
          } catch (_) {
            content = null;
          }
        }
        setState(() {
          _attachedFileName = file.name;
          _attachedFileContent = content;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingFile = false);
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final authors = _authorsController.text.trim();
    final year = _yearController.text.trim();
    final journal = _journalController.text.trim();
    final url = _urlController.text.trim().isNotEmpty ? _urlController.text.trim() : null;
    final focus = _focusController.text.trim();
    final differences = _differencesController.text.trim();

    final citation = '$authors ($year). $title. $journal.${url != null ? ' $url' : ''}';
    final customId = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final tag = 'Custom $year';

    final newItem = LiteratureItem(
      corpus: LiteratureCorpus.custom,
      id: customId,
      tag: tag,
      title: title,
      authors: authors,
      year: year,
      journal: journal,
      citation: citation,
      url: url,
      focusKa: focus,
      focusEn: focus,
      focusDe: focus,
      differencesKa: differences,
      differencesEn: differences,
      differencesDe: differences,
      abstractKa: focus,
      abstractEn: focus,
      abstractDe: focus,
      methodologyKa: 'მომხმარებლის მიერ მითითებული მეთოდოლოგია: $differences',
      methodologyEn: 'User-specified empirical methodology: $differences',
      methodologyDe: 'Vom Benutzer angegebene Methodik: $differences',
      keyFindingsKa: focus,
      keyFindingsEn: focus,
      keyFindingsDe: focus,
      icon: Icons.edit_note_rounded,
      isCustom: true,
      attachedFileName: _attachedFileName,
      fullContent: _attachedFileContent,
    );

    CustomLiteratureStore.instance.addCustomItem(newItem);
    widget.onLiteratureAdded?.call(newItem);

    Navigator.of(context).pop(newItem);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = size.width > 760 ? 700.0 : size.width * 0.94;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: size.height * 0.90,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.post_add_rounded, color: colorScheme.onPrimaryContainer, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          I18n.t('customLiteratureTitle'),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          I18n.t('customLiteratureSubtitle'),
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: I18n.t('close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: I18n.t('literatureTitleField'),
                          hintText: 'e.g. Climate factors driving Aedes mosquito proliferation',
                          prefixIcon: const Icon(Icons.title_rounded),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'სათაური აუცილებელია' : null,
                      ),
                      const SizedBox(height: 14),

                      // Authors & Year Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _authorsController,
                              decoration: InputDecoration(
                                labelText: I18n.t('literatureAuthorsField'),
                                hintText: 'e.g. Smith, J., Doe, A. / CDC',
                                prefixIcon: const Icon(Icons.person_outline_rounded),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'ავტორები აუცილებელია' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: I18n.t('literatureYearField'),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) =>
                                  v == null || v.trim().isEmpty ? 'წელი' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Journal & Publisher
                      TextFormField(
                        controller: _journalController,
                        decoration: InputDecoration(
                          labelText: I18n.t('literatureJournalField'),
                          hintText: 'e.g. PLOS Neglected Tropical Diseases / Nature',
                          prefixIcon: const Icon(Icons.menu_book_outlined),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'ჟურნალი/წყარო აუცილებელია' : null,
                      ),
                      const SizedBox(height: 14),

                      // DOI or URL
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: I18n.t('literatureUrlField'),
                          hintText: 'https://doi.org/... ან https://example.org/paper.pdf',
                          prefixIcon: const Icon(Icons.link_rounded),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Focus & Abstract
                      TextFormField(
                        controller: _focusController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: I18n.t('literatureFocusField'),
                          hintText:
                              'მოკლე სამეცნიერო რეზიუმე და კვლევის ძირითადი მიგნებები...',
                          alignLabelWithHint: true,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'რეზიუმე აუცილებელია' : null,
                      ),
                      const SizedBox(height: 14),

                      // Relevance & Differences
                      TextFormField(
                        controller: _differencesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: I18n.t('literatureDifferencesField'),
                          hintText:
                              'როგორ უკავშირდება კლიმატს და რით განსხვავდება სხვა წყაროებისგან...',
                          alignLabelWithHint: true,
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'განსხვავება აუცილებელია' : null,
                      ),
                      const SizedBox(height: 16),

                      // File upload section
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isPickingFile ? null : _pickFile,
                              icon: _isPickingFile
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.upload_file_rounded, size: 18),
                              label: Text(I18n.t('attachFile')),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _attachedFileName != null
                                  ? Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded,
                                            size: 16, color: Colors.greenAccent),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '${I18n.t('fileAttached')} $_attachedFileName',
                                            style: const TextStyle(
                                                fontSize: 12, fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16),
                                          onPressed: () => setState(() {
                                            _attachedFileName = null;
                                            _attachedFileContent = null;
                                          }),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      'PDF, TXT, MD ან CSV დოკუმენტი (არასავალდებულო)',
                                      style: TextStyle(fontSize: 11.5, color: Colors.grey[400]),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text(I18n.t('close')),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: Text(I18n.t('saveLiterature')),
                    style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
