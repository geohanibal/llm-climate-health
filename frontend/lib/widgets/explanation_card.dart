/// Displays the LLM-generated, plain-language explanation of the pipeline
/// for users without a programming or climate-science background.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import 'section_card.dart';

class ExplanationCard extends StatelessWidget {
  final String explanation;
  final String explanationSource;

  const ExplanationCard({
    super.key,
    required this.explanation,
    required this.explanationSource,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Explanation for a non-expert user',
      leading: Icons.chat_bubble_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (explanationSource == 'fallback') _buildFallbackWarning(),
          Text(explanation, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildFallbackWarning() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[800]),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Generic explanation — AI was unavailable for this run, so '
              'this is not model-generated text.',
              style: TextStyle(fontSize: 12, color: Colors.orange[800]),
            ),
          ),
        ],
      ),
    );
  }
}
