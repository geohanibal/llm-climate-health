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

  static const _roleIcons = {
    'Climate data': Icons.thermostat_outlined,
    'Case counts': Icons.local_hospital_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Sources',
      leading: Icons.menu_book_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sources.map(_buildEntry).toList(),
      ),
    );
  }

  Widget _buildEntry(String source) {
    final separatorIndex = source.indexOf(': ');
    final role = separatorIndex == -1 ? null : source.substring(0, separatorIndex);
    final detail = separatorIndex == -1 ? source : source.substring(separatorIndex + 2);
    final icon = _roleIcons[role] ?? Icons.link;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (role != null)
                  Text(
                    role,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.3),
                  ),
                Text(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
