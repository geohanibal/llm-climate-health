/// Lists the academic/scientific citations for every data source used in
/// this integration run.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import 'section_card.dart';

class SourcesCard extends StatelessWidget {
  final List<String> sources;

  const SourcesCard({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Sources',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sources.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('•  $s'),
            )).toList(),
      ),
    );
  }
}
