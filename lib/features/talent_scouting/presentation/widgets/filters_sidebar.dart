import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/widgets/auth_status_panel.dart';
import '../providers/scouting_providers.dart';
import '../providers/talent_search_controller.dart';

class FiltersSidebar extends ConsumerStatefulWidget {
  const FiltersSidebar({super.key});

  @override
  ConsumerState<FiltersSidebar> createState() => _FiltersSidebarState();
}

class _FiltersSidebarState extends ConsumerState<FiltersSidebar> {
  late final TextEditingController _keywordsController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    // Restore the visible text from the stored filters when returning here.
    final filters = ref.read(scoutingFiltersProvider);
    _keywordsController = TextEditingController(text: filters.keywords);
    _locationController = TextEditingController(text: filters.location);
  }

  @override
  void dispose() {
    _keywordsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _search() {
    final session = ref.read(authNotifierProvider).asData?.value;
    final filters = ref.read(scoutingFiltersProvider);
    final isSearching = ref.read(talentSearchControllerProvider).isLoading;
    if (session == null || isSearching || !filters.toQuery().hasCriteria) {
      return;
    }
    ref
        .read(talentSearchControllerProvider.notifier)
        .search(filters.toQuery(), session.accessToken);
  }

  void _reset() {
    _keywordsController.clear();
    _locationController.clear();
    ref.read(scoutingFiltersProvider.notifier).reset();
    ref.read(talentSearchControllerProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final filters = ref.watch(scoutingFiltersProvider);
    final session = ref.watch(authNotifierProvider).asData?.value;
    final isSearching = ref.watch(talentSearchControllerProvider).isLoading;
    final hasCriteria = filters.toQuery().hasCriteria;
    final searchEnabled = session != null && !isSearching && hasCriteria;
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                localization.scoutingFiltersTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              const AuthStatusPanel(),
              const Divider(height: 32),
              TextField(
                controller: _keywordsController,
                decoration: InputDecoration(
                  labelText: localization.scoutingKeywordLabel,
                  hintText: localization.scoutingKeywordHint,
                  helperText: localization.scoutingKeywordHelper,
                  helperMaxLines: 2,
                  prefixIcon: const Icon(Icons.code),
                ),
                textInputAction: TextInputAction.search,
                onChanged: ref
                    .read(scoutingFiltersProvider.notifier)
                    .updateKeywords,
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: searchEnabled ? _search : null,
                icon: isSearching
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.travel_explore),
                label: Text(
                  isSearching
                      ? localization.scoutingInProgress
                      : localization.scoutingStartButton,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: localization.scoutingLocationLabel,
                  hintText: localization.scoutingLocationHint,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
                textInputAction: TextInputAction.search,
                onChanged: ref
                    .read(scoutingFiltersProvider.notifier)
                    .updateLocation,
                onSubmitted: (_) => _search(),
              ),
              const SizedBox(height: 20),
              _MinimumFilter(
                label: localization.scoutingMinimumRepositories,
                value: filters.minimumRepositories,
                onChanged: ref
                    .read(scoutingFiltersProvider.notifier)
                    .updateMinimumRepositories,
                maximum: 500,
              ),
              const SizedBox(height: 16),
              _MinimumFilter(
                label: localization.scoutingMinimumFollowers,
                value: filters.minimumFollowers,
                onChanged: ref
                    .read(scoutingFiltersProvider.notifier)
                    .updateMinimumFollowers,
                maximum: 10000,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: hasCriteria ? _reset : null,
                  icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                  label: Text(localization.scoutingClearFilters),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinimumFilter extends StatefulWidget {
  const _MinimumFilter({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.maximum,
  });

  final String label;
  final int value;
  final int maximum;
  final ValueChanged<int> onChanged;

  @override
  State<_MinimumFilter> createState() => _MinimumFilterState();
}

class _MinimumFilterState extends State<_MinimumFilter> {
  late final TextEditingController _controller = TextEditingController(
    text: '${widget.value}',
  );

  @override
  void didUpdateWidget(covariant _MinimumFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != '${widget.value}') {
      _controller.value = TextEditingValue(
        text: '${widget.value}',
        selection: TextSelection.collapsed(offset: '${widget.value}'.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            SizedBox(
              width: 76,
              child: TextFormField(
                controller: _controller,
                textAlign: TextAlign.end,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                onChanged: (text) {
                  final parsedValue = int.tryParse(text);
                  if (parsedValue != null) {
                    widget.onChanged(parsedValue.clamp(0, widget.maximum));
                  }
                },
              ),
            ),
          ],
        ),
        Slider(
          value: widget.value.clamp(0, widget.maximum).toDouble(),
          min: 0,
          max: widget.maximum.toDouble(),
          onChanged: (nextValue) => widget.onChanged(nextValue.round()),
        ),
      ],
    );
  }
}
