/// Displays the LLM-generated, plain-language explanation of the pipeline
/// for users without a programming or climate-science background.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import 'section_card.dart';

class ExplanationCard extends StatelessWidget {
  final String explanation;

  const ExplanationCard({super.key, required this.explanation});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Explanation for a non-expert user',
      child: Text(explanation, style: const TextStyle(height: 1.4)),
    );
  }
}
