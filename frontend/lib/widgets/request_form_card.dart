/// The "describe what you need" request form: disease, region, climate
/// variables, date range, temporal aggregation, and scientific
/// data-source selection.
///
/// Author: Sergi Koniashvili (LLM-Climate-Health, bachelor thesis)
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/responsive.dart';
import '../models/data_source_info.dart';
import '../models/integration_request_params.dart';
import '../models/discovered_source.dart';
import '../models/parsed_request.dart';
import '../models/platform_options.dart';
import 'section_card.dart';
import 'source_search_dialog.dart';
import 'world_map_dialog.dart';

/// Stateful form card that collects an [IntegrationRequestParams] from the
/// user and hands it to [onSubmit] once "Run integration" is pressed. All
/// dropdown choices come from [options], which is fetched from the backend
/// at startup so nothing here is hardcoded.
class RequestFormCard extends StatefulWidget {
  final PlatformOptions options;
  final bool isSubmitting;
  final ValueChanged<IntegrationRequestParams> onSubmit;

  const RequestFormCard({
    super.key,
    required this.options,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  State<RequestFormCard> createState() => RequestFormCardState();
}

/// Public so [HomePage] can reach [applyPrefill] through a `GlobalKey` when
/// the natural-language card returns a parsed request.
class RequestFormCardState extends State<RequestFormCard> {
  static final DateTime _minDate = DateTime(1990, 1, 1);
  static final DateTime _maxDate = DateTime.now();

  late String _disease = widget.options.diseases.keys.first;
  late String? _region = _initialRegion();
  final Set<String> _variables = {'temperature', 'precipitation'};
  DateTime _startDate = DateTime(2015, 1, 1);
  DateTime _endDate = DateTime(2023, 12, 1);
  late String _aggregation = widget.options.aggregations.first;

  // Seeded from the region-filtered lists (not the raw, unfiltered options)
  // so the very first build can never hand a DropdownButtonFormField a
  // value that isn't among its own filtered items — that mismatch throws
  // an assertion. Both filters only need `widget.options` and `_region`,
  // already initialized above.
  late String _climateSource = _climateSourceOptions().first.id;
  late String _caseDataSource = _caseDataSourceOptions().first.id;
  late String _populationSource = _initialPopulationSource();
  String? _whoIndicatorCode;
  String? _whoIndicatorName;
  // Disease the currently-picked WHO indicator was searched/selected for —
  // used by [_reconcileSources] to drop a stale pick (see its doc).
  String? _whoIndicatorDisease;
  final TextEditingController _customUrlController = TextEditingController();
  Uint8List? _uploadedBytes;
  String? _uploadedFileName;
  Uint8List? _climateUploadBytes;
  String? _climateUploadFileName;

  String? _validationError;

  String _initialPopulationSource() {
    return widget.options.populationSources.isNotEmpty
        ? widget.options.populationSources.first.id
        : 'worldbank';
  }

  @override
  void dispose() {
    _customUrlController.dispose();
    super.dispose();
  }

  /// Every region the platform knows about, regardless of disease or
  /// source: the region is chosen first, and the source dropdowns below
  /// filter themselves to what's actually available for it (see
  /// [_climateSourceOptions] and [_caseDataSourceOptions]) — this is what
  /// keeps an incompatible region/source pair from ever being selectable
  /// in the first place, rather than only failing at submit time.
  List<String> _allRegionNames() => widget.options.regions.keys.toList()..sort();

  /// Picks a sensible default region at first load: prefer one the default
  /// disease actually has built-in data for, so the initial form is a
  /// valid, runnable combination out of the box.
  String? _initialRegion() {
    final diseaseRegions = widget.options.diseases[_disease]?.regions;
    if (diseaseRegions != null && diseaseRegions.isNotEmpty) {
      final sorted = List<String>.from(diseaseRegions)..sort();
      return sorted.first;
    }
    return _allRegionNames().firstOrNull;
  }

  /// Whether the built-in source has real case data for [_disease] in
  /// [_region] — the only case-data source whose availability depends on
  /// the region, since who_gho/custom_url/custom_upload work anywhere.
  bool _builtinAvailableForCurrentRegion() {
    return widget.options.diseases[_disease]?.regions.contains(_region) ?? false;
  }

  /// Climate sources compatible with [_region] (e.g. TMD only covers
  /// Thailand). A source with no entry in `climateSourceRegions` is global.
  List<DataSourceInfo> _climateSourceOptions() {
    return widget.options.climateSources.where((s) {
      final restriction = widget.options.climateSourceRegions[s.id];
      return restriction == null || restriction.contains(_region);
    }).toList();
  }

  /// Case-data sources compatible with [_region]: every source except
  /// "builtin" works for any region (the user supplies the data), so only
  /// "builtin" needs filtering.
  List<DataSourceInfo> _caseDataSourceOptions() {
    return widget.options.caseDataSources
        .where((s) => s.id != 'builtin' || _builtinAvailableForCurrentRegion())
        .toList();
  }

  /// Re-validates the selected climate/case-data sources against
  /// [_region]/[_disease] whenever either changes, and swaps away from
  /// whatever became invalid — so an incompatible combination can never
  /// linger in the form waiting to fail at submit time.
  void _reconcileSources() {
    final validClimate = _climateSourceOptions();
    // validClimate can't currently be empty (at least one configured
    // climate source is always region-unrestricted — see
    // test_config.py's invariant test), but guard defensively rather than
    // let a future config change throw a StateError here.
    if (validClimate.isNotEmpty && !validClimate.any((s) => s.id == _climateSource)) {
      _climateSource = validClimate.first.id;
    }
    if (_caseDataSource == 'builtin' && !_builtinAvailableForCurrentRegion()) {
      _caseDataSource = 'custom_url';
    }
    // A WHO indicator is disease-specific (e.g. "estimated malaria cases"
    // means nothing for cholera) — carrying a stale one over would submit
    // the new disease's label with the old disease's numbers. Dropping it
    // forces a fresh search; the submit-time check ("Search and pick a WHO
    // indicator first") keeps it from being submitted empty in the
    // meantime.
    if (_whoIndicatorCode != null && _whoIndicatorDisease != _disease) {
      _whoIndicatorCode = null;
      _whoIndicatorName = null;
      _whoIndicatorDisease = null;
    }
  }

  void _onDiseaseChanged(String disease) {
    setState(() {
      _disease = disease;
      _reconcileSources();
    });
  }

  void _onRegionChanged(String? region) {
    setState(() {
      _region = region;
      _reconcileSources();
    });
  }

  void _onCaseDataSourceChanged(String source) {
    final previous = _caseDataSource;
    setState(() => _caseDataSource = source);
    if (source == 'who_gho') {
      _openSourceSearch(revertTo: previous);
    }
  }

  /// Opens the WHO GHO / HDX search dialog. If the user cancels without
  /// picking a result, [revertTo] restores the previously selected
  /// case-data source instead of leaving `who_gho` selected with no
  /// indicator chosen (which would fail validation on submit).
  Future<void> _openSourceSearch({String? revertTo}) async {
    if (_region == null) {
      setState(() => _validationError = 'Pick a region first, then search for sources.');
      if (revertTo != null) setState(() => _caseDataSource = revertTo);
      return;
    }
    final diseaseLabel = widget.options.diseases[_disease]?.label ?? _disease;
    final picked = await showDialog<DiscoveredSource>(
      context: context,
      builder: (context) => SourceSearchDialog(
        diseaseKey: _disease,
        diseaseLabel: diseaseLabel,
        region: _region!,
      ),
    );
    if (picked == null) {
      if (revertTo != null) setState(() => _caseDataSource = revertTo);
      return;
    }
    setState(() {
      if (picked.isWhoGho) {
        _caseDataSource = 'who_gho';
        _whoIndicatorCode = picked.indicatorCode;
        _whoIndicatorName = picked.title;
        _whoIndicatorDisease = _disease;
      } else {
        _caseDataSource = 'custom_url';
        _customUrlController.text = picked.resourceUrl ?? picked.datasetUrl;
      }
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: _minDate,
      lastDate: _maxDate,
      helpText: isStart ? 'Select start month' : 'Select end month',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, 1);
      } else {
        _endDate = DateTime(picked.year, picked.month, 1);
      }
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _uploadedBytes = result.files.single.bytes;
      _uploadedFileName = result.files.single.name;
    });
  }

  Future<void> _pickClimateFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _climateUploadBytes = result.files.single.bytes;
      _climateUploadFileName = result.files.single.name;
    });
  }

  Future<void> _pickRegionOnMap() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => WorldMapDialog(
        regions: widget.options.regions,
        availableRegions: _allRegionNames().toSet(),
        initialRegion: _region,
      ),
    );
    if (selected != null) _onRegionChanged(selected);
  }

  /// Applies a best-effort [ParsedRequest] from the natural-language card.
  /// Only overwrites a field when the parsed value is present and valid;
  /// [_reconcileSources] runs last so an incompatible disease/region/source
  /// combination the model suggested is corrected the same way a manual
  /// pick would be.
  void applyPrefill(ParsedRequest r) {
    setState(() {
      if (r.disease != null && widget.options.diseases.containsKey(r.disease)) {
        _disease = r.disease!;
      }
      if (r.region != null && widget.options.regions.containsKey(r.region)) {
        _region = r.region;
      }
      if (r.variables != null && r.variables!.isNotEmpty) {
        _variables
          ..clear()
          ..addAll(r.variables!.where(widget.options.variables.contains));
      }
      if (r.startDate != null) {
        _startDate = DateTime(r.startDate!.year, r.startDate!.month, 1);
      }
      if (r.endDate != null) {
        _endDate = DateTime(r.endDate!.year, r.endDate!.month, 1);
      }
      if (r.aggregation != null && widget.options.aggregations.contains(r.aggregation)) {
        _aggregation = r.aggregation!;
      }
      if (r.climateSource != null &&
          widget.options.climateSources.any((s) => s.id == r.climateSource)) {
        _climateSource = r.climateSource!;
      }
      _reconcileSources();
    });
  }

  String get currentDisease => _disease;
  String? get currentRegion => _region;
  DateTime get currentStartDate => _startDate;
  DateTime get currentEndDate => _endDate;

  /// Public programmatic submission for callers like [HomePage] driving
  /// searches triggered directly from the Climate-Health Copilot drawer.
  void submitForm() => _submit();

  /// Applies a best-effort [ParsedRequest] and immediately triggers form submission.
  void applyPrefillAndSubmit(ParsedRequest r) {
    applyPrefill(r);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _submit();
      }
    });
  }

  void _submit() {
    if (_region == null) {
      setState(
        () => _validationError =
            'No built-in data is available for this disease yet — switch to a '
            'custom URL or file upload, or pick a different disease.',
      );
      return;
    }
    if (_variables.isEmpty) {
      setState(() => _validationError = 'Select at least one climate variable.');
      return;
    }
    if (_caseDataSource == 'custom_url' && _customUrlController.text.trim().isEmpty) {
      setState(() => _validationError = 'Enter a URL for the custom data source.');
      return;
    }
    if (_caseDataSource == 'custom_upload' && _uploadedBytes == null) {
      setState(() => _validationError = 'Upload a CSV file for the custom data source.');
      return;
    }
    if (_climateSource == 'custom_upload' && _climateUploadBytes == null && _uploadedBytes == null) {
      setState(() => _validationError = 'Upload a CSV file for the custom weather source.');
      return;
    }
    if (_caseDataSource == 'who_gho' && _whoIndicatorCode == null) {
      setState(() => _validationError = 'Search and pick a WHO indicator first.');
      return;
    }
    setState(() => _validationError = null);

    widget.onSubmit(
      IntegrationRequestParams(
        disease: _disease,
        region: _region!,
        variables: _variables.toList(),
        startDate: _startDate,
        endDate: _endDate,
        aggregation: _aggregation,
        climateSource: _climateSource,
        caseDataSource: _caseDataSource,
        populationSource: _populationSource,
        customSourceUrl:
            _caseDataSource == 'custom_url' ? _customUrlController.text.trim() : null,
        uploadedFileBytes: _caseDataSource == 'custom_upload' ? _uploadedBytes : null,
        uploadedFileName: _caseDataSource == 'custom_upload' ? _uploadedFileName : null,
        climateUploadBytes:
            _climateSource == 'custom_upload' ? (_climateUploadBytes ?? _uploadedBytes) : null,
        climateUploadFileName:
            _climateSource == 'custom_upload' ? (_climateUploadFileName ?? _uploadedFileName) : null,
        whoIndicatorCode: _caseDataSource == 'who_gho' ? _whoIndicatorCode : null,
        whoIndicatorName: _caseDataSource == 'who_gho' ? _whoIndicatorName : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Describe what you need',
      leading: Icons.tune,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose a disease, a region of the world, the time span and '
            'granularity, and the scientific data sources you want it built from.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ResponsiveFieldRow(
            columns: 2,
            children: [
              _buildDiseaseDropdown(),
              _buildRegionField(),
            ],
          ),
          const SizedBox(height: 16),
          Text('Climate variables', style: Theme.of(context).textTheme.labelLarge),
          _buildVariableChips(),
          const SizedBox(height: 16),
          ResponsiveFieldRow(
            columns: 3,
            children: [
              _buildDateButton('From', _startDate, () => _pickDate(isStart: true)),
              _buildDateButton('To', _endDate, () => _pickDate(isStart: false)),
              _buildAggregationDropdown(),
            ],
          ),
          const SizedBox(height: 16),
          _buildClimateSourceDropdown(),
          if (_climateSource == 'custom_upload') _buildClimateUploadPicker(),
          const SizedBox(height: 16),
          _buildPopulationSourceDropdown(),
          const SizedBox(height: 16),
          Text('Case-count data source', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            'Only scientific / official surveillance sources. Bring your own '
            'via a link or an uploaded file if you prefer.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          _buildCaseDataSourceDropdown(),
          const SizedBox(height: 8),
          _buildAvailabilityStatus(),
          if (_caseDataSource == 'custom_url') _buildCustomUrlField(),
          if (_caseDataSource == 'custom_upload') _buildUploadPicker(),
          const SizedBox(height: 20),
          if (_validationError != null) _buildValidationError(),
          FilledButton.icon(
            onPressed: widget.isSubmitting ? null : _submit,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run integration'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiseaseDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _disease,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Disease', border: OutlineInputBorder()),
      items: widget.options.diseases.values
          .map((d) => DropdownMenuItem(value: d.key, child: Text(d.label)))
          .toList(),
      onChanged: (v) => _onDiseaseChanged(v!),
    );
  }

  Widget _buildRegionField() {
    final regionNames = _allRegionNames();
    final countLabel = 'any of ${regionNames.length} countries — the sources below '
        'adapt to what has data here';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Autocomplete<String>(
            // Region can change from outside this field too (map picker,
            // AI prefill) — Autocomplete only reads `initialValue` once
            // when created, so the key must include `_region` or an
            // external change would update the app's state but leave this
            // text field showing the old country.
            key: ValueKey(_region),
            initialValue: TextEditingValue(text: _region ?? ''),
            optionsBuilder: (value) {
              if (value.text.isEmpty) return regionNames;
              return regionNames.where(
                (r) => r.toLowerCase().contains(value.text.toLowerCase()),
              );
            },
            onSelected: _onRegionChanged,
            fieldViewBuilder: (context, controller, focusNode, onSubmit) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Region (country)',
                  border: const OutlineInputBorder(),
                  helperText: 'Type to search — $countLabel',
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton.outlined(
            tooltip: 'Choose region on a world map',
            icon: const Icon(Icons.public),
            onPressed: _pickRegionOnMap,
          ),
        ),
      ],
    );
  }

  Widget _buildVariableChips() {
    return Wrap(
      spacing: 8,
      children: widget.options.variables.map((v) {
        final label = v[0].toUpperCase() + v.substring(1);
        return FilterChip(
          label: Text(label),
          selected: _variables.contains(v),
          onSelected: (sel) => setState(() {
            sel ? _variables.add(v) : _variables.remove(v);
          }),
        );
      }).toList(),
    );
  }

  Widget _buildDateButton(String label, DateTime date, VoidCallback onTap) {
    final formatted = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_month),
      label: Text('$label: $formatted'),
    );
  }

  Widget _buildAggregationDropdown() {
    // Mirrors the backend's own resolution rule (etl.py's run_integration):
    // WHO GHO indicators are always yearly regardless of the disease's
    // usual native resolution; otherwise it's the disease's own
    // (dengue = monthly, malaria/cholera = yearly) — spelling that out
    // here means "As reported" never leaves the user guessing what
    // resolution they're actually about to get.
    final nativeResolution = _caseDataSource == 'who_gho'
        ? 'year'
        : (widget.options.diseases[_disease]?.nativeResolution ?? 'year');
    final labels = {
      'native': nativeResolution == 'month' ? 'As reported (monthly)' : 'As reported (yearly)',
      'daily': 'Daily (day-by-day)',
      'yearly': 'Yearly',
      'decadal': 'Decadal',
    };
    return DropdownButtonFormField<String>(
      initialValue: _aggregation,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Time granularity', border: OutlineInputBorder()),
      items: widget.options.aggregations
          .map((a) => DropdownMenuItem(value: a, child: Text(labels[a] ?? a)))
          .toList(),
      onChanged: (v) => setState(() => _aggregation = v!),
    );
  }

  Widget _buildClimateSourceDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _climateSource,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Climate data source',
        border: OutlineInputBorder(),
      ),
      // Only sources that actually cover `_region` are offered — e.g. TMD
      // is hidden unless the region is Thailand — so an incompatible pair
      // can't be selected in the first place.
      items: _climateSourceOptions()
          .map((s) => DropdownMenuItem(
                value: s.id,
                child: Text(s.label, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) => setState(() => _climateSource = v!),
    );
  }

  Widget _buildPopulationSourceDropdown() {
    final popOptions = widget.options.populationSources;
    final items = popOptions.isNotEmpty
        ? popOptions
        : [
            const DataSourceInfo(
              id: 'worldbank',
              label: 'World Bank Open Data (SP.POP.TOTL)',
              citation: 'World Bank Group (2024), World Development Indicators: Population, total (SP.POP.TOTL), data.worldbank.org',
            ),
            const DataSourceInfo(
              id: 'un_wpp',
              label: 'United Nations Population Division (UN WPP 2024)',
              citation: 'United Nations, Department of Economic and Social Affairs, Population Division (2024). World Population Prospects 2024 (population.un.org)',
            ),
          ];

    return DropdownButtonFormField<String>(
      initialValue: _populationSource,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Population data source (demographics)',
        border: OutlineInputBorder(),
        helperText: 'Trusted international demographic source for incidence rate calculation',
      ),
      items: items
          .map((s) => DropdownMenuItem(
                value: s.id,
                child: Text(s.label, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) => setState(() => _populationSource = v!),
    );
  }

  Widget _buildCaseDataSourceDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _caseDataSource,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      // "builtin" only appears when the disease actually has case data for
      // `_region`; who_gho/custom_url/custom_upload always work.
      items: _caseDataSourceOptions()
          .map((s) => DropdownMenuItem(
                value: s.id,
                child: Text(s.label, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) => _onCaseDataSourceChanged(v!),
    );
  }

  /// Live "does this source actually have data for what I picked" readout,
  /// so the user never has to submit and hit an error to find out.
  Widget _buildAvailabilityStatus() {
    final diseaseLabel = widget.options.diseases[_disease]?.label ?? _disease;

    if (_caseDataSource == 'who_gho') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _whoIndicatorCode != null ? Icons.verified_outlined : Icons.cancel_outlined,
              size: 16,
              color: _whoIndicatorCode != null ? Colors.green[700] : Colors.red,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _whoIndicatorCode != null
                    ? 'WHO GHO indicator: $_whoIndicatorName ($_whoIndicatorCode)'
                    : 'No WHO indicator selected yet.',
                style: TextStyle(
                  fontSize: 12,
                  color: _whoIndicatorCode != null ? Colors.green[700] : Colors.red,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _openSourceSearch(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Change'),
            ),
          ],
        ),
      );
    }

    if (_caseDataSource != 'builtin') {
      return _statusChip(
        icon: Icons.info_outline,
        color: Colors.blueGrey,
        text: 'Using a source you provide — case counts come from your '
            'link/file; the region is only used to fetch climate data.',
      );
    }

    if (_region == null) {
      return _statusChip(
        icon: Icons.cancel_outlined,
        color: Colors.red,
        text: 'No built-in $diseaseLabel data for any region yet.',
      );
    }

    final available = _builtinAvailableForCurrentRegion();
    if (!available) {
      return _statusChip(
        icon: Icons.cancel_outlined,
        color: Colors.red,
        text: '$_region has no built-in $diseaseLabel data — pick another '
            'region, or switch to a custom URL/upload.',
      );
    }

    final coverage = widget.options.diseases[_disease]?.regionCoverage[_region];
    if (coverage != null && coverage.length == 2 && !_overlapsCoverage(coverage)) {
      return _statusChip(
        icon: Icons.warning_amber_outlined,
        color: Colors.orange[800]!,
        text: '$_region has built-in $diseaseLabel data, but only for '
            '${coverage[0]} to ${coverage[1]} — your selected period does not '
            'overlap that, so you will get climate data with no case counts. '
            'Adjust the dates or pick a different region.',
      );
    }

    return _statusChip(
      icon: Icons.check_circle_outline,
      color: Colors.green[700]!,
      text: coverage != null && coverage.length == 2
          ? '$_region has built-in $diseaseLabel data (${coverage[0]} to ${coverage[1]}).'
          : '$_region has built-in $diseaseLabel data.',
    );
  }

  /// Whether [_startDate]..[_endDate] overlaps a "YYYY-MM" or "YYYY"
  /// [earliest, latest] coverage span from the backend.
  bool _overlapsCoverage(List<String> coverage) {
    DateTime? parsePeriod(String period) {
      final parts = period.split('-');
      final year = int.tryParse(parts[0]);
      if (year == null) return null;
      final month = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
      return DateTime(year, month, 1);
    }

    final coverageStart = parsePeriod(coverage[0]);
    final coverageEnd = parsePeriod(coverage[1]);
    if (coverageStart == null || coverageEnd == null) return true;
    return !_endDate.isBefore(coverageStart) && !_startDate.isAfter(coverageEnd);
  }

  Widget _statusChip({required IconData icon, required Color color, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color))),
        ],
      ),
    );
  }

  Widget _buildCustomUrlField() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: _customUrlController,
        decoration: const InputDecoration(
          labelText: 'CSV URL (columns: date, cases)',
          border: OutlineInputBorder(),
          hintText: 'https://example.org/cases.csv',
        ),
      ),
    );
  }

  Widget _buildUploadPicker() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file),
            label: const Text('Choose CSV file'),
          ),
          const SizedBox(width: 12),
          if (_uploadedFileName != null) Text(_uploadedFileName!),
        ],
      ),
    );
  }

  Widget _buildClimateUploadPicker() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickClimateFile,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Choose Weather CSV'),
              ),
              const SizedBox(width: 12),
              if (_climateUploadFileName != null)
                Expanded(
                  child: Text(
                    _climateUploadFileName!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Upload local meteorological station observations with date, temperature, and/or precipitation columns.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationError() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(_validationError!, style: const TextStyle(color: Colors.red)),
    );
  }
}
