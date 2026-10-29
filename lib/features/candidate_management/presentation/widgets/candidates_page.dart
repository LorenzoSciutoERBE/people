import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/candidate_list_filter.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_list_filter_provider.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_actions_menu.dart';
import 'candidate_details_page.dart';
import 'candidate_dialog_support.dart';
import 'candidate_editor_dialog.dart';
import 'candidate_status_widgets.dart';
import 'star_rating.dart';

/// Searchable, filterable and sortable list of every candidate.
class CandidatesPage extends ConsumerStatefulWidget {
  const CandidatesPage({super.key});

  @override
  ConsumerState<CandidatesPage> createState() => _CandidatesPageState();
}

class _CandidatesPageState extends ConsumerState<CandidatesPage> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(candidateListFilterProvider).text,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clear() {
    _search.clear();
    ref.read(candidateListFilterProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final state = ref.watch(candidateManagementControllerProvider);
    return state.when(
      data: (data) => _buildContent(context, localization, data),
      error: (error, stackTrace) => CandidateErrorPanel(
        message: localization.candidateActionFailed,
        onRetry: () => ref.invalidate(candidateManagementControllerProvider),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations localization,
    RecruitingData data,
  ) {
    final filter = ref.watch(candidateListFilterProvider);
    final stages = [...data.stages]
      ..sort((first, second) => first.order.compareTo(second.order));
    final visible = filter.apply(data.candidates, stages);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            title: localization.candidatesListTitle,
            subtitle: localization.candidatesCount(
              visible.length,
              data.candidates.length,
            ),
            onAdd: () => showDialog<void>(
              context: context,
              builder: (_) => CandidateEditorDialog(data: data),
            ),
          ),
          const SizedBox(height: 20),
          _FilterBar(
            controller: _search,
            filter: filter,
            stages: stages,
            sources: data.sources,
            onClear: _clear,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: visible.isEmpty
                  ? _EmptyState(
                      key: ValueKey(data.candidates.isEmpty),
                      message: data.candidates.isEmpty
                          ? localization.candidateEmpty
                          : localization.candidatesNoResults,
                      onClear:
                          data.candidates.isEmpty || !filter.hasActiveFilters
                          ? null
                          : _clear,
                    )
                  : ListView.separated(
                      key: const ValueKey('candidate-list'),
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: visible.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) => _CandidateRow(
                        candidate: visible[index],
                        data: data,
                        stages: stages,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1),
          label: Text(localization.candidateAdd),
        ),
      ],
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.controller,
    required this.filter,
    required this.stages,
    required this.sources,
    required this.onClear,
  });

  final TextEditingController controller;
  final CandidateListFilter filter;
  final List<HiringStage> stages;
  final List<CandidateSource> sources;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final notifier = ref.read(candidateListFilterProvider.notifier);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: localization.candidatesSearchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: filter.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: localization.candidatesClearFilters,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        controller.clear();
                        notifier.update((value) => value.copyWith(text: ''));
                      },
                    ),
            ),
            onChanged: (value) =>
                notifier.update((current) => current.copyWith(text: value)),
          ),
        ),
        _Dropdown<String>(
          key: ValueKey('stage-${filter.stageId}'),
          label: localization.candidatesFilterStage,
          selected: filter.stageId ?? '',
          entries: {
            '': localization.candidatesAllStages,
            for (final stage in stages)
              stage.id: localizedStageName(localization, stage),
          },
          onChanged: (value) => notifier.update(
            (current) => value.isEmpty
                ? current.copyWith(clearStage: true)
                : current.copyWith(stageId: value),
          ),
        ),
        _Dropdown<String>(
          key: ValueKey('source-${filter.sourceId}'),
          label: localization.candidatesFilterSource,
          selected: filter.sourceId ?? '',
          entries: {
            '': localization.candidatesAllSources,
            for (final source in sources)
              source.id: localizedSourceName(localization, source),
          },
          onChanged: (value) => notifier.update(
            (current) => value.isEmpty
                ? current.copyWith(clearSource: true)
                : current.copyWith(sourceId: value),
          ),
        ),
        _Dropdown<CandidateFeedbackFilter>(
          key: ValueKey('feedback-${filter.feedback.name}'),
          label: localization.candidatesFilterFeedback,
          selected: filter.feedback,
          entries: {
            CandidateFeedbackFilter.any: localization.candidatesFeedbackAny,
            CandidateFeedbackFilter.missing:
                localization.candidatesFeedbackMissingOption,
            CandidateFeedbackFilter.positive:
                localization.candidateFeedbackPositive,
            CandidateFeedbackFilter.neutral:
                localization.candidateFeedbackNeutral,
            CandidateFeedbackFilter.negative:
                localization.candidateFeedbackNegative,
          },
          onChanged: (value) =>
              notifier.update((current) => current.copyWith(feedback: value)),
        ),
        _Dropdown<CandidateSort>(
          key: ValueKey('sort-${filter.sort.name}'),
          label: localization.candidatesSortLabel,
          selected: filter.sort,
          entries: {
            CandidateSort.recentlyUpdated: localization.candidatesSortRecent,
            CandidateSort.name: localization.candidatesSortName,
            CandidateSort.stage: localization.candidatesSortStage,
          },
          onChanged: (value) =>
              notifier.update((current) => current.copyWith(sort: value)),
        ),
        FilterChip(
          avatar: const Icon(Icons.description_outlined, size: 18),
          label: Text(localization.candidatesWithResume),
          selected: filter.withResumeOnly,
          onSelected: (value) => notifier.update(
            (current) => current.copyWith(withResumeOnly: value),
          ),
        ),
        if (filter.hasActiveFilters)
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
            label: Text(localization.candidatesClearFilters),
          ),
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    super.key,
    required this.label,
    required this.selected,
    required this.entries,
    required this.onChanged,
  });

  final String label;
  final T selected;
  final Map<T, String> entries;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DropdownMenu<T>(
    initialSelection: selected,
    label: Text(label),
    width: 200,
    requestFocusOnTap: false,
    onSelected: (value) {
      if (value != null) onChanged(value);
    },
    dropdownMenuEntries: [
      for (final entry in entries.entries)
        DropdownMenuEntry<T>(value: entry.key, label: entry.value),
    ],
  );
}

class _CandidateRow extends ConsumerWidget {
  const _CandidateRow({
    required this.candidate,
    required this.data,
    required this.stages,
  });

  final Candidate candidate;
  final RecruitingData data;
  final List<HiringStage> stages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final stage = stages.firstWhere(
      (value) => value.id == candidate.stageId,
      orElse: () => stages.first,
    );
    final source = data.sources
        .where((value) => value.id == candidate.sourceId)
        .firstOrNull;
    final feedback = candidate.latestFeedbackFor(stage.id)?.decision;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(candidate.updatedAt.toLocal());
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => CandidateDetailsPage.open(context, candidate.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              CandidateAvatar(name: candidate.fullName, radius: 22),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (candidate.headline.isNotEmpty ||
                        candidate.location.isNotEmpty)
                      Text(
                        [
                          candidate.headline,
                          candidate.location,
                        ].where((value) => value.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final skill in candidate.skills.take(4))
                      Chip(
                        label: Text(skill),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                        backgroundColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizedStageName(localization, stage),
                      style: theme.textTheme.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (source != null)
                      Text(
                        localizedSourceName(localization, source),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      localization.candidatesUpdatedOn(date),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (data.requiresFeedback(stage.id))
                        FeedbackBadge(decision: feedback),
                      if (candidate.averageRating case final rating?)
                        Tooltip(
                          message: localization.candidateAverageRating,
                          child: AverageRatingBadge(rating: rating),
                        ),
                    ],
                  ),
                ),
              ),
              if (candidate.hasResume)
                Tooltip(
                  message: localization.candidateResume,
                  child: Icon(
                    Icons.description_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
              CandidateActionsMenu(
                candidate: candidate,
                stage: stage,
                feedbackEnabled: data.requiresFeedback(stage.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({super.key, required this.message, this.onClear});

  final String message;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people_outline,
            size: 56,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          if (onClear != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onClear,
              child: Text(localization.candidatesClearFilters),
            ),
          ],
        ],
      ),
    );
  }
}
