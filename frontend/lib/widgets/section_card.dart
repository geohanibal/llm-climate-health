/// Shared card shell used by every results section, so headings and
/// padding stay consistent without repeating the same boilerplate.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final IconData? leading;

  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (leading != null) ...[
                      Icon(leading, size: 20, color: colors.primary),
                      const SizedBox(width: 8),
                    ],
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
