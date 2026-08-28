/// Card and dialog presenting the AI-driven data transformation and audit trail.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../models/integration_result.dart';

class DataAuditCard extends StatelessWidget {
  final DataTransformationAudit audit;

  const DataAuditCard({super.key, required this.audit});

  void _showAuditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AuditDetailDialog(audit: audit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.primary.withAlpha(50)),
      ),
      color: colors.primaryContainer.withAlpha(30),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI Data Transformation & Audit Log',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => _showAuditDialog(context),
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('View Full Log'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (audit.humanExplanation.isNotEmpty)
              Text(
                audit.humanExplanation,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Badge(
                  label: 'Date Column: ${audit.selectedDateColumn ?? "auto"}',
                  icon: Icons.calendar_today_outlined,
                  color: Colors.blue,
                ),
                _Badge(
                  label: 'Case Column: ${audit.selectedValueColumn ?? "auto"}',
                  icon: Icons.bar_chart_outlined,
                  color: Colors.teal,
                ),
                _Badge(
                  label: 'Retained: ${audit.validRowsRetained}/${audit.totalRowsReceived} rows',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                if (audit.droppedRowsCount > 0)
                  _Badge(
                    label: '${audit.droppedRowsCount} dropped (invalid dates)',
                    icon: Icons.filter_alt_outlined,
                    color: Colors.amber[800]!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditDetailDialog extends StatelessWidget {
  final DataTransformationAudit audit;

  const _AuditDetailDialog({required this.audit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final width = (size.width * 0.9).clamp(320.0, 650.0);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.fact_check_outlined, color: colors.primary),
          const SizedBox(width: 10),
          const Text('Data Processing Audit Trail'),
        ],
      ),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (audit.humanExplanation.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.primary.withAlpha(40)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.psychology_outlined, color: colors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          audit.humanExplanation,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _AuditSection(
                title: '📥 Raw Input Received',
                children: [
                  Text('Total rows received: ${audit.totalRowsReceived}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('Original Columns: [${audit.originalColumns.join(", ")}]',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
              const Divider(height: 24),
              _AuditSection(
                title: '🔄 Column Mapping & Harmonization',
                children: [
                  Text('• Date Index Column: "${audit.selectedDateColumn ?? "Auto-detected"}"',
                      style: const TextStyle(fontSize: 13)),
                  Text('• Case Metric Column: "${audit.selectedValueColumn ?? "Auto-detected"}"',
                      style: const TextStyle(fontSize: 13)),
                  if (audit.transformationsApplied.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    const Text('Applied Transformations:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ...audit.transformationsApplied.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Text('→ $t', style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 24),
              _AuditSection(
                title: '🗑️ Data Filtering & Quality',
                children: [
                  Text('• Valid records retained: ${audit.validRowsRetained}',
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                  if (audit.droppedRowsCount > 0)
                    Text('• Dropped unparseable rows: ${audit.droppedRowsCount}',
                        style: TextStyle(color: Colors.amber[800], fontWeight: FontWeight.w600))
                  else
                    const Text('• Clean dataset: 0 rows dropped',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _AuditSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _AuditSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }
}
