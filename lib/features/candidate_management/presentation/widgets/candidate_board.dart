import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_actions_menu.dart';
import 'candidate_details_page.dart';
import 'candidate_dialog_support.dart';
import 'candidate_editor_dialog.dart';
import 'candidate_status_widgets.dart';
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
        final stages = [...data.stages]
          ..sort((first, second) => first.order.compareTo(second.order));
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

class _BoardHeader extends StatelessWidget {
  const _BoardHeader({required this.data, required this.stages});

  final RecruitingData data;
  final List<HiringStage> stages;

  int get _pendingFeedback {
    return data.candidates.where((candidate) {
      if (!data.requiresFeedback(candidate.stageId)) return false;
      final decision = candidate.latestFeedbackFor(candidate.stageId)?.decision;
      return decision == null || decision == FeedbackDecision.pending;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              localization.candidateBoardTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _Stat(
            label: localization.candidateStatTotal,
            value: '${data.candidates.length}',
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          _Stat(
            label: localization.candidateStatPending,
            value: '$_pendingFeedback',
            color: const Color(0xFFE37400),
          ),
          const SizedBox(width: 20),
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
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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

  Color _accent(BuildContext context) => switch (stage.terminalOutcome) {
    TerminalOutcome.hired => const Color(0xFF1E8E3E),
    TerminalOutcome.rejected => const Color(0xFFD93025),
    TerminalOutcome.active =>
      stage.isOfferStage
          ? const Color(0xFF8E4EC6)
          : Theme.of(context).colorScheme.primary,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final accent = _accent(context);
    return DragTarget<String>(
      onAcceptWithDetails: (details) => performCandidateAction(
        context,
        localization,
        () => ref
            .read(candidateManagementControllerProvider.notifier)
            .moveCandidate(details.data, stage.id),
      ),
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
                  Text(
                    '${candidates.length}',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: accent),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
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

class _CandidateCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
              if (candidate.skills.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final skill in candidate.skills.take(3))
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
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 8),
                child: Row(
                  children: [
                    if (feedbackRequired)
                      Flexible(
                        child: FeedbackBadge(
                          decision: candidate
                              .latestFeedbackFor(stage.id)
                              ?.decision,
                        ),
                      ),
                    const Spacer(),
                    if (candidate.averageRating case final rating?)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Tooltip(
                          message: localization.candidateAverageRating,
                          child: AverageRatingBadge(rating: rating),
                        ),
                      ),
                    if (source != null)
                      Tooltip(
                        message: localizedSourceName(localization, source),
                        child: const Icon(Icons.source_outlined, size: 16),
                      ),
                    if (candidate.hasResume)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.description_outlined, size: 16),
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
