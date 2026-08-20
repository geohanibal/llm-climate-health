/// Modal dialog that searches WHO GHO and HDX for real, citable case-data
/// sources for the selected disease/region, and lets the user pick one —
/// instead of being limited to the single hardcoded built-in source.
///
/// Every result shown here is real metadata from the source's own API
/// (nothing is generated); picking one returns it via [Navigator.pop] for
/// the caller to wire into the request.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../models/discovered_source.dart';
import '../services/api_client.dart';

class SourceSearchDialog extends StatefulWidget {
  /// Internal disease key (e.g. "dengue") the backend's `/api/*` routes
  /// expect — not the human-readable label.
  final String diseaseKey;
  final String diseaseLabel;
  final String region;

  const SourceSearchDialog({
    super.key,
    required this.diseaseKey,
    required this.diseaseLabel,
    required this.region,
  });

  @override
  State<SourceSearchDialog> createState() => _SourceSearchDialogState();
}

class _SourceSearchDialogState extends State<SourceSearchDialog> {
  final ApiClient _api = const ApiClient();
  late final Future<List<DiscoveredSource>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.searchCaseSources(widget.diseaseKey, widget.region);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width < 700 ? size.width * 0.95 : 640.0;
    final dialogHeight = (size.height * 0.7).clamp(360.0, 560.0);

    return AlertDialog(
      title: Text('Search official sources — ${widget.diseaseLabel} in ${widget.region}'),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: FutureBuilder<List<DiscoveredSource>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Search failed: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              );
            }
            final results = snapshot.data!;
            if (results.isEmpty) {
              return const Center(
                child: Text(
                  'No matching sources found on WHO GHO or HDX for this '
                  'disease/region. Try a custom URL or file upload instead.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _SourceTile(
                source: results[i],
                onPick: () => Navigator.of(context).pop(results[i]),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final DiscoveredSource source;
  final VoidCallback onPick;

  const _SourceTile({required this.source, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Icon(
        source.isWhoGho ? Icons.verified_outlined : Icons.dataset_outlined,
        color: colors.primary,
      ),
      title: Text(source.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(source.organization, style: TextStyle(fontSize: 12, color: colors.primary)),
          if (source.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(source.description, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
      trailing: FilledButton(onPressed: onPick, child: const Text('Use this')),
      isThreeLine: source.description.isNotEmpty,
    );
  }
}
