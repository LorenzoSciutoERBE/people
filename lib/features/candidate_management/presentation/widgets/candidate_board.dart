import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_actions_menu.dart';
import 'candidate_details_page.dart';
import 'candidate_dialog_support.dart';
import 'employment_plan_dialog.dart';
import 'candidate_editor_dialog.dart';
import 'candidate_status_widgets.dart';
import 'pipeline_status.dart';
import 'star_rating.dart';

/// Kanban view of the hiring pipeline; cards can be dragged between stages.
class CandidateBoard extends ConsumerWidget {
  const CandidateBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final recruitingState = ref.watch(candidateManagementControllerProvider);
    return recruitingState.when(
      data: (data) {
        final stages = data.orderedStages;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BoardHeader(data: data, stages: stages),
            if (data.candidates.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.view_kanban_outlined,
                        size: 56,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localization.candidateEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: _HorizontalStages(
                  itemCount: stages.length,
                  itemBuilder: (context, index) {
                    final stage = stages[index];
                    return _StageColumn(
                      stage: stage,
                      candidates: data.candidates
                          .where((candidate) => candidate.stageId == stage.id)
                          .toList(growable: false),
                      sources: data.sources,
                      stages: stages,
                      feedbackRequired: data.requiresFeedback(stage.id),
                    );
                  },
                ),
              ),
          ],
        );
      },
      error: (error, stackTrace) => CandidateErrorPanel(
        message: localization.candidateActionFailed,
        onRetry: () => ref.invalidate(candidateManagementControllerProvider),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _HorizontalStages extends StatefulWidget {
  const _HorizontalStages({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final NullableIndexedWidgetBuilder itemBuilder;

  @override
  State<_HorizontalStages> createState() => _HorizontalStagesState();
}

class _HorizontalStagesState extends State<_HorizontalStages> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Mouse wheel scrolls the board sideways; dragging stays reserved for cards.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final position = _controller.position;
    final delta = event.scrollDelta.dx != 0
        ? event.scrollDelta.dx
        : event.scrollDelta.dy;
    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      _controller.jumpTo(
        (position.pixels + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerSignal: _onPointerSignal,
    child: Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: ListView.separated(
        key: const Key('candidate-board-stages'),
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
        scrollDirection: Axis.horizontal,
        itemCount: widget.itemCount,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: widget.itemBuilder,
      ),
    ),
  );
}

class _BoardHeader extends ConsumerWidget {
  const _BoardHeader({required this.data, required this.stages});

  final RecruitingData data;
  final List<HiringStage> stages;

  int get _pendingFeedback {
    return data.candidates.where((candidate) {
      return candidate.interviews.any(
        (record) =>
            record.stageId != 'new' &&
            record.decision != FeedbackDecision.pending &&
            !record.feedbackSharedWithCandidate,
      );
    }).length;
  }

  int get _hiredCount {
    final hiredIds = stages
        .where((stage) => stage.terminalOutcome == TerminalOutcome.hired)
        .map((stage) => stage.id)
        .toSet();
    return data.candidates
        .where((candidate) => hiredIds.contains(candidate.stageId))
        .length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localization.candidateBoardTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Stat(
                icon: Icons.people_outline,
                label: localization.candidateStatTotal,
                value: '${data.candidates.length}',
                color: theme.colorScheme.primary,
              ),
              if (_pendingFeedback > 0)
                _Stat(
                  icon: Icons.schedule_outlined,
                  label: localization.candidateStatPending,
                  value: '$_pendingFeedback',
                  color: const Color(0xFFE37400),
                ),
              if (_hiredCount > 0)
                _Stat(
                  icon: Icons.verified_outlined,
                  label: localization.candidateDefaultHired,
                  value: '$_hiredCount',
                  color: const Color(0xFF1E8E3E),
                ),
              FilledButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => CandidateEditorDialog(data: data),
                ),
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(localization.candidateAdd),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    ),
  );
}

class _StageColumn extends ConsumerWidget {
  const _StageColumn({
    required this.stage,
    required this.candidates,
    required this.sources,
    required this.stages,
    required this.feedbackRequired,
  });

  final HiringStage stage;
  final List<Candidate> candidates;
  final List<CandidateSource> sources;
  final List<HiringStage> stages;
  final bool feedbackRequired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final accent = stageAccentColor(context, stage);
    return DragTarget<String>(
      onAcceptWithDetails: (details) =>
          moveCandidateWithHiringPlan(context, ref, details.data, stage.id),
      builder: (context, candidateData, rejectedData) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 300,
        decoration: BoxDecoration(
          color: candidateData.isNotEmpty
              ? accent.withValues(alpha: 0.12)
              : const Color(0xFFEEF2F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: candidateData.isNotEmpty ? accent : const Color(0xFFE1E7F0),
            width: candidateData.isNotEmpty ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      localizedStageName(localization, stage),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        '${candidates.length}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: candidates.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.inbox_outlined,
                        size: 28,
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.35),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                      itemCount: candidates.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) => _CandidateCard(
                        candidate: candidates[index],
                        stage: stage,
                        sources: sources,
                        stages: stages,
                        feedbackRequired: feedbackRequired,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends ConsumerWidget {
  const _CandidateCard({
    required this.candidate,
    required this.stage,
    required this.sources,
    required this.stages,
    required this.feedbackRequired,
  });

  final Candidate candidate;
  final HiringStage stage;
  final List<CandidateSource> sources;
  final List<HiringStage> stages;
  final bool feedbackRequired;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final evaluationsVisible = ref.watch(evaluationsVisibleProvider);
    final source = sources
        .where((value) => value.id == candidate.sourceId)
        .firstOrNull;
    final card = Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => CandidateDetailsPage.open(context, candidate.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CandidateAvatar(name: candidate.fullName),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      candidate.fullName.isEmpty
                          ? localization.candidateAdd
                          : candidate.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  CandidateActionsMenu(
                    candidate: candidate,
                    stage: stage,
                    feedbackEnabled: feedbackRequired,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 8),
                child: PipelineStatus(candidate: candidate),
              ),
              if (candidate.headline.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Text(
                    candidate.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              if (candidate.location.isNotEmpty ||
                  candidate.yearsOfExperience != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Row(
                    children: [
                      if (candidate.location.isNotEmpty) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            candidate.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      if (candidate.location.isNotEmpty &&
                          candidate.yearsOfExperience != null)
                        const SizedBox(width: 8),
                      if (candidate.yearsOfExperience != null) ...[
                        Icon(
                          Icons.work_history_outlined,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${candidate.yearsOfExperience}y',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              if (candidate.skills.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final skill in candidate.skills.take(3))
                        CandidateSkillChip(skill: skill),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (evaluationsVisible && stage.isInterview)
                      FeedbackBadge(
                        decision: candidate
                            .latestFeedbackFor(stage.id)
                            ?.decision,
                      ),
                    if (source != null) SourceBadge(source: source),
                    if (evaluationsVisible)
                      if (candidate.averageRating case final rating?)
                        Tooltip(
                          message: localization.candidateAverageRating,
                          child: AverageRatingBadge(rating: rating),
                        ),
                    if (candidate.hasResume)
                      Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Draggable<String>(
      data: candidate.id,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 280, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}
