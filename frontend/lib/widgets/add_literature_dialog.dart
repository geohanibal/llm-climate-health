/// Dialog allowing researchers and users to input custom scientific literature
/// and publications to ground the platform's AI Copilot and comparative evaluations.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis, University of Bremen)
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../models/literature_item.dart';
import '../services/api_client.dart';

class AddLiteratureDialog extends StatefulWidget {
  final ValueChanged<LiteratureItem>? onLiteratureAdded;
  final ApiClient? apiClient;

  const AddLiteratureDialog({
    super.key,
    this.onLiteratureAdded,
    this.apiClient,
  });

  static Future<LiteratureItem?> show(
    BuildContext context, {
    ValueChanged<LiteratureItem>? onLiteratureAdded,
    ApiClient? apiClient,
  }) {
    return showDialog<LiteratureItem>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AddLiteratureDialog(
        onLiteratureAdded: onLiteratureAdded,
        apiClient: apiClient,
      ),
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
  final _urlFocusNode = FocusNode();

  String? _attachedFileName;
  Uint8List? _attachedFileBytes;
  String? _attachedFileContent;
  bool _isPickingFile = false;
  bool _isExtracting = false;
  String? _lastExtractedUrl;

  ApiClient get _api => widget.apiClient ?? const ApiClient();

  @override
  void initState() {
    super.initState();
    _urlFocusNode.addListener(_onUrlFocusChanged);
  }

  void _onUrlFocusChanged() {
    if (!_urlFocusNode.hasFocus) {
      final url = _urlController.text.trim();
      if ((url.startsWith('http://') || url.startsWith('https://')) &&
          url != _lastExtractedUrl) {
        _lastExtractedUrl = url;
        _triggerAiExtraction(url: url);
      }
    }
  }

  @override
  void dispose() {
    _urlFocusNode.removeListener(_onUrlFocusChanged);
    _urlFocusNode.dispose();
    _titleController.dispose();
    _authorsController.dispose();
    _yearController.dispose();
    _journalController.dispose();
    _urlController.dispose();
    _focusController.dispose();
    _differencesController.dispose();
    super.dispose();
  }

  bool _areFieldsFilled() {
    return _titleController.text.trim().isNotEmpty ||
        _authorsController.text.trim().isNotEmpty ||
        _journalController.text.trim().isNotEmpty ||
        _focusController.text.trim().isNotEmpty ||
        _differencesController.text.trim().isNotEmpty;
  }

  void _populateFieldsWithAi(LiteratureExtractionResult result) {
    setState(() {
      if (result.title.isNotEmpty) _titleController.text = result.title;
      if (result.authors.isNotEmpty) _authorsController.text = result.authors;
      if (result.year.isNotEmpty) _yearController.text = result.year;
      if (result.journal.isNotEmpty) _journalController.text = result.journal;
      if (result.url != null && result.url!.isNotEmpty) {
        _urlController.text = result.url!;
      }
      if (result.abstract.isNotEmpty) _focusController.text = result.abstract;
      if (result.differences.isNotEmpty) _differencesController.text = result.differences;
    });
  }

  Future<void> _triggerAiExtraction({
    Uint8List? fileBytes,
    String? fileName,
    String? url,
  }) async {
    final effectiveUrl = url?.trim();
    if (fileBytes == null && (effectiveUrl == null || effectiveUrl.isEmpty)) {
      return;
    }

    setState(() => _isExtracting = true);

    try {
      final result = await _api.extractLiterature(
        fileBytes: fileBytes,
        fileName: fileName,
        url: effectiveUrl,
      );

      if (!mounted) return;
      setState(() => _isExtracting = false);

      if (_areFieldsFilled()) {
        final shouldOverwrite = await _showOverwriteConfirmationDialog(result);
        if (shouldOverwrite == true && mounted) {
          _populateFieldsWithAi(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(I18n.t('aiExtractSuccess'))),
                ],
              ),
              backgroundColor: const Color(0xFF1B4D3E),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        _populateFieldsWithAi(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(I18n.t('aiExtractSuccess'))),
                ],
              ),
              backgroundColor: const Color(0xFF1B4D3E),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${I18n.t('aiExtractError')}$e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExtracting = false);
      }
    }
  }

  Future<bool?> _showOverwriteConfirmationDialog(LiteratureExtractionResult result) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                I18n.t('aiOverwritePromptTitle'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  I18n.t('aiOverwritePromptBody'),
                  style: TextStyle(fontSize: 13, color: Colors.grey[300], height: 1.4),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 14, color: Colors.amberAccent),
                          const SizedBox(width: 6),
                          Text(
                            I18n.t('aiExtractPreviewTitle'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amberAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (result.title.isNotEmpty) ...[
                        Text(
                          '${I18n.t('literatureTitleField')}:',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        Text(result.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                      ],
                      if (result.authors.isNotEmpty) ...[
                        Text(
                          '${I18n.t('literatureAuthorsField')}:',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        Text('${result.authors} (${result.year})', style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 6),
                      ],
                      if (result.journal.isNotEmpty) ...[
                        Text(
                          '${I18n.t('literatureJournalField')}:',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        Text(result.journal, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 6),
                      ],
                      if (result.abstract.isNotEmpty) ...[
                        Text(
                          '${I18n.t('literatureFocusField')}:',
                          style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          result.abstract,
                          style: const TextStyle(fontSize: 11.5, height: 1.3),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
            child: Text(I18n.t('aiOverwriteKeepMine')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text(I18n.t('aiOverwriteAccept')),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              backgroundColor: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
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
          _attachedFileBytes = file.bytes;
          _attachedFileContent = content;
        });

        if (file.bytes != null) {
          await _triggerAiExtraction(fileBytes: file.bytes, fileName: file.name);
        }
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
      originalPdfUrl: url,
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
      attachedFileBytes: _attachedFileBytes,
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
                      // AI Auto-Extraction Hint Banner
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, size: 15, color: Colors.amberAccent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                I18n.t('aiExtractHint'),
                                style: TextStyle(fontSize: 11.5, color: Colors.grey[400]),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_isExtracting)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amberAccent.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.amberAccent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    I18n.t('aiExtracting'),
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amberAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

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
                        focusNode: _urlFocusNode,
                        decoration: InputDecoration(
                          labelText: I18n.t('literatureUrlField'),
                          hintText: 'https://doi.org/... ან https://example.org/paper.pdf',
                          prefixIcon: const Icon(Icons.link_rounded),
                          suffixIcon: Tooltip(
                            message: I18n.t('aiExtractButton'),
                            child: IconButton(
                              icon: _isExtracting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(
                                      Icons.auto_awesome,
                                      color: Colors.amberAccent,
                                      size: 20,
                                    ),
                              onPressed: _isExtracting
                                  ? null
                                  : () {
                                      final url = _urlController.text.trim();
                                      if (url.isNotEmpty) {
                                        _lastExtractedUrl = url;
                                        _triggerAiExtraction(url: url);
                                      } else if (_attachedFileBytes != null) {
                                        _triggerAiExtraction(
                                          fileBytes: _attachedFileBytes,
                                          fileName: _attachedFileName,
                                        );
                                      }
                                    },
                            ),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (val) {
                          final url = val.trim();
                          if (url.isNotEmpty && url != _lastExtractedUrl) {
                            _lastExtractedUrl = url;
                            _triggerAiExtraction(url: url);
                          }
                        },
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
                              onPressed: (_isPickingFile || _isExtracting) ? null : _pickFile,
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
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 16,
                                          color: Colors.greenAccent,
                                        ),
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
                                          tooltip: I18n.t('aiExtractButton'),
                                          icon: const Icon(
                                            Icons.auto_awesome,
                                            size: 16,
                                            color: Colors.amberAccent,
                                          ),
                                          onPressed: _isExtracting
                                              ? null
                                              : () => _triggerAiExtraction(
                                                    fileBytes: _attachedFileBytes,
                                                    fileName: _attachedFileName,
                                                  ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, size: 16),
                                          onPressed: () => setState(() {
                                            _attachedFileName = null;
                                            _attachedFileBytes = null;
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
