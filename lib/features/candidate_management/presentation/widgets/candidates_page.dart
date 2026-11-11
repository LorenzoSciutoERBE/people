import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/candidate_list_filter.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_list_filter_provider.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_details_page.dart';
import 'candidate_dialog_support.dart';
import 'candidate_editor_dialog.dart';
import 'candidate_status_widgets.dart';
import 'pipeline_status.dart';
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
    final stages = data.orderedStages;
    final visible = filter.apply(data.candidates, stages);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          const SizedBox(height: 10),
          _StageFilterPills(
            stages: stages,
            candidates: data.candidates,
            selectedStageId: filter.stageId,
          ),
          const SizedBox(height: 8),
          _FilterBar(
            controller: _search,
            filter: filter,
            sources: data.sources,
            onClear: _clear,
          ),
          const SizedBox(height: 10),
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
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: visible.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
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
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.6,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            subtitle,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1, size: 17),
          label: Text(localization.candidateAdd),
        ),
      ],
    );
  }
}

class _StageFilterPills extends ConsumerWidget {
  const _StageFilterPills({
    required this.stages,
    required this.candidates,
    required this.selectedStageId,
  });

  final List<HiringStage> stages;
  final List<Candidate> candidates;
  final String? selectedStageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final notifier = ref.read(candidateListFilterProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _CompactStagePill(
          label: '${localization.candidatesAllStages} (${candidates.length})',
          color: primary,
          selected: selectedStageId == null,
          showDot: false,
          onTap: () =>
              notifier.update((current) => current.copyWith(clearStage: true)),
        ),
        for (final stage in stages)
          Builder(
            builder: (context) {
              final count = candidates
                  .where((c) => c.stageId == stage.id)
                  .length;
              final color = stageAccentColor(context, stage);
              final selected = selectedStageId == stage.id;
              return _CompactStagePill(
                label: '${localizedStageName(localization, stage)} ($count)',
                color: color,
                selected: selected,
                onTap: () => notifier.update(
                  (current) => selected
                      ? current.copyWith(clearStage: true)
                      : current.copyWith(stageId: stage.id),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CompactStagePill extends StatelessWidget {
  const _CompactStagePill({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.showDot = true,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? color.withValues(alpha: 0.14)
          : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected
              ? color.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDot) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected ? color : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.controller,
    required this.filter,
    required this.sources,
    required this.onClear,
  });

  final TextEditingController controller;
  final CandidateListFilter filter;
  final List<CandidateSource> sources;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final notifier = ref.read(candidateListFilterProvider.notifier);
    final searchField = SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        style: theme.textTheme.bodySmall,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          hintText: localization.candidatesSearchHint,
          hintStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          prefixIcon: const Icon(Icons.search, size: 16),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          suffixIcon: filter.text.isEmpty
              ? null
              : IconButton(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  tooltip: localization.candidatesClearFilters,
                  icon: const Icon(Icons.close, size: 15),
                  onPressed: () {
                    controller.clear();
                    notifier.update((value) => value.copyWith(text: ''));
                  },
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 28,
            minHeight: 28,
          ),
        ),
        onChanged: (value) =>
            notifier.update((current) => current.copyWith(text: value)),
      ),
    );
    final sourceDropdown = _Dropdown<String>(
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
    );
    final feedbackDropdown = _Dropdown<CandidateFeedbackFilter>(
      key: ValueKey('feedback-${filter.feedback.name}'),
      label: localization.candidatesFilterFeedback,
      selected: filter.feedback,
      entries: {
        CandidateFeedbackFilter.any: localization.candidatesFeedbackAny,
        CandidateFeedbackFilter.missing:
            localization.candidatesFeedbackMissingOption,
        CandidateFeedbackFilter.positive:
            localization.candidateFeedbackPositive,
        CandidateFeedbackFilter.communicationPending:
            localization.pipelineFeedbackPending,
        CandidateFeedbackFilter.negative:
            localization.candidateFeedbackNegative,
      },
      onChanged: (value) =>
          notifier.update((current) => current.copyWith(feedback: value)),
    );
    final sortDropdown = _Dropdown<CandidateSort>(
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
    );
    final resumeChip = _CompactStagePill(
      label: localization.candidatesWithResume,
      color: theme.colorScheme.primary,
      selected: filter.withResumeOnly,
      showDot: false,
      onTap: () => notifier.update(
        (current) => current.copyWith(withResumeOnly: !filter.withResumeOnly),
      ),
    );
    final clearButton = filter.hasActiveFilters
        ? TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              textStyle: theme.textTheme.labelSmall,
            ),
            onPressed: onClear,
            icon: const Icon(Icons.filter_alt_off_outlined, size: 15),
            label: Text(localization.candidatesClearFilters),
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 860) {
          return Row(
            children: [
              Expanded(flex: 4, child: searchField),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: sourceDropdown),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: feedbackDropdown),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: sortDropdown),
              const SizedBox(width: 8),
              resumeChip,
              if (clearButton != null) ...[
                const SizedBox(width: 6),
                clearButton,
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 8),
                resumeChip,
                if (clearButton != null) ...[
                  const SizedBox(width: 6),
                  clearButton,
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: sourceDropdown),
                const SizedBox(width: 8),
                Expanded(child: feedbackDropdown),
                const SizedBox(width: 8),
                Expanded(child: sortDropdown),
              ],
            ),
          ],
        );
      },
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: DropdownButtonFormField<T>(
        initialValue: selected,
        isExpanded: true,
        isDense: true,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          labelStyle: theme.textTheme.labelSmall,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
        ),
        items: [
          for (final entry in entries.entries)
            DropdownMenuItem<T>(
              value: entry.key,
              child: Text(
                entry.value,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
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
    final evaluationsVisible = ref.watch(evaluationsVisibleProvider);
    final stage = stages.firstWhere(
      (value) => value.id == candidate.stageId,
      orElse: () => stages.first,
    );
    final accent = stageAccentColor(context, stage);
    final source = data.sources
        .where((value) => value.id == candidate.sourceId)
        .firstOrNull;
    final feedback = candidate.latestFeedbackFor(stage.id)?.decision;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .format(candidate.updatedAt.toLocal());
    final subtitleParts = <String>[
      if (candidate.headline.isNotEmpty) candidate.headline,
      if (candidate.location.isNotEmpty) candidate.location,
      if (candidate.yearsOfExperience != null)
        '${candidate.yearsOfExperience}y',
    ];
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => CandidateDetailsPage.open(context, candidate.id),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: accent, width: 3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              CandidateAvatar(name: candidate.fullName, radius: 15),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            candidate.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (candidate.hasResume) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: localization.candidateResume,
                            child: Icon(
                              Icons.description_outlined,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    PipelineStatus(candidate: candidate),
                    if (subtitleParts.isNotEmpty)
                      Text(
                        subtitleParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (candidate.skills.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final skill in candidate.skills.take(3))
                        CandidateSkillChip(skill: skill),
                      if (candidate.skills.length > 3)
                        CandidateSkillChip(
                          skill: '+${candidate.skills.length - 3}',
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Flexible(
                flex: 5,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StageBadge(stage: stage),
                    if (source != null) SourceBadge(source: source),
                    if (evaluationsVisible) ...[
                      if (stage.isInterview) FeedbackBadge(decision: feedback),
                      if (candidate.averageRating case final rating?)
                        Tooltip(
                          message: localization.candidateAverageRating,
                          child: AverageRatingBadge(rating: rating),
                        ),
                    ],
                    Text(
                      date,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
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
