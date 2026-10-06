/// "Describe your request in your own words" card: free text that an LLM
/// turns into a best-effort request plan, which only ever prefills the form
/// below — it never runs the pipeline itself.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../core/localization.dart';
import 'section_card.dart';

class NaturalLanguageCard extends StatefulWidget {
  final bool isParsing;
  final String? error;
  final String? notes;
  final ValueChanged<String> onParse;

  const NaturalLanguageCard({
    super.key,
    required this.isParsing,
    required this.error,
    required this.notes,
    required this.onParse,
  });

  @override
  State<NaturalLanguageCard> createState() => _NaturalLanguageCardState();
}

class _NaturalLanguageCardState extends State<NaturalLanguageCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onParse(text);
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: I18n.t('naturalLanguageTitle'),
      leading: Icons.auto_awesome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            I18n.t('naturalLanguageSubtitle'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: I18n.t('naturalLanguageHint'),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.isParsing ? null : _submit,
            icon: widget.isParsing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(widget.isParsing ? I18n.t('parsing') : I18n.t('fillForm')),
          ),
          if (widget.error != null) ...[
            const SizedBox(height: 8),
            Text(widget.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (widget.notes != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.notes!,
                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
