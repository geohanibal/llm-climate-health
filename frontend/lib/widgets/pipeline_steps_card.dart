/// Shows every step the backend performed, numbered in execution order, so
/// the user can verify their request was carried out correctly.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import 'section_card.dart';

class PipelineStepsCard extends StatelessWidget {
  final List<String> steps;
  final bool cached;
  final String lastVerified;

  const PipelineStepsCard({
    super.key,
    required this.steps,
    required this.cached,
    required this.lastVerified,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'What the pipeline did',
      trailing: Chip(
        avatar: Icon(cached ? Icons.cached : Icons.bolt, size: 16),
        label: Text(
          cached ? 'Cached · verified $lastVerified' : 'Freshly fetched · $lastVerified',
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('${i + 1}. ${steps[i]}'),
            ),
        ],
      ),
    );
  }
}
