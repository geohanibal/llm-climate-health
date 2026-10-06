/// Modal dialog to search and select official demographic indicators (World Bank Open Data,
/// HDX) or population datasets for the selected region.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../models/discovered_source.dart';
import '../services/api_client.dart';

class PopulationSearchDialog extends StatefulWidget {
  final String region;

  const PopulationSearchDialog({
    super.key,
    required this.region,
  });

  @override
  State<PopulationSearchDialog> createState() => _PopulationSearchDialogState();
}

class _PopulationSearchDialogState extends State<PopulationSearchDialog> {
  final ApiClient _api = const ApiClient();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<DiscoveredSource>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.searchPopulationSources(widget.region);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    setState(() {
      _future = _api.searchPopulationSources(
        widget.region,
        _searchController.text.trim(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final dialogWidth = size.width < 700 ? size.width * 0.95 : 680.0;
    final dialogHeight = (size.height * 0.75).clamp(400.0, 620.0);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.people_alt_outlined, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${I18n.t('searchPopulationTitle')} — ${widget.region}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: I18n.t('searchPopulationHint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: I18n.t('search'),
                  onPressed: _triggerSearch,
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _triggerSearch(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<DiscoveredSource>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '${I18n.t('searchFailed')}: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  final results = snapshot.data ?? [];
                  if (results.isEmpty) {
                    return Center(
                      child: Text(
                        I18n.t('noPopulationSourcesFound'),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => _PopulationSourceTile(
                      source: results[i],
                      onPick: () => Navigator.of(context).pop(results[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(I18n.t('cancel')),
        ),
      ],
    );
  }
}

class _PopulationSourceTile extends StatelessWidget {
  final DiscoveredSource source;
  final VoidCallback onPick;

  const _PopulationSourceTile({
    required this.source,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isWorldBank = source.isWorldBank;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      leading: CircleAvatar(
        backgroundColor: isWorldBank ? Colors.indigo.shade50 : Colors.teal.shade50,
        child: Icon(
          isWorldBank ? Icons.analytics_outlined : Icons.public_outlined,
          color: isWorldBank ? Colors.indigo : Colors.teal,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              source.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (source.indicatorCode != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                color: Colors.indigo.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.indigo.withAlpha(50)),
              ),
              child: Text(
                source.indicatorCode!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.indigo,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Text(
            source.organization,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.primary),
          ),
          if (source.description.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              source.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
      trailing: FilledButton.tonal(
        onPressed: onPick,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(I18n.t('useThis')),
      ),
      isThreeLine: source.description.isNotEmpty,
    );
  }
}
