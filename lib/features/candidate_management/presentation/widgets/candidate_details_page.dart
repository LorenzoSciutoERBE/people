import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_dialog_support.dart';
import 'candidate_status_widgets.dart';
import 'candidate_communication_toggle.dart';
import 'pipeline_status.dart';
import 'interview_feedback_form.dart';
import 'offer_dialog.dart';
import 'star_rating.dart';
import 'employment_plan_dialog.dart';

/// Candidate recap with permanent profile details and explicitly opened steps.
class CandidateDetailsPage extends ConsumerStatefulWidget {
  const CandidateDetailsPage({super.key, required this.candidateId});

  final String candidateId;

  static Future<void> open(BuildContext context, String candidateId) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => CandidateDetailsPage(candidateId: candidateId),
      );

  @override
  ConsumerState<CandidateDetailsPage> createState() =>
      _CandidateDetailsPageState();
}

class _CandidateDetailsPageState extends ConsumerState<CandidateDetailsPage> {
  final _profileKey = GlobalKey<_InlineProfileState>();
  final _panelKey = GlobalKey<_RightPanelState>();
  bool _allowClose = false;
  bool _confirmingClose = false;

  Future<void> _requestClose() async {
    if (_confirmingClose) return;
    _confirmingClose = true;
    final profileAllows =
        await _profileKey.currentState?.confirmLeave() ?? true;
    final feedbackAllows =
        profileAllows && (await _panelKey.currentState?.confirmLeave() ?? true);
    _confirmingClose = false;
    if (!feedbackAllows || !mounted) return;
    setState(() => _allowClose = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(candidateManagementControllerProvider).asData?.value;
    final candidate = data?.candidates
        .where((value) => value.id == widget.candidateId)
        .firstOrNull;
    final stage = data?.stages
        .where((value) => value.id == candidate?.stageId)
        .firstOrNull;
    final screen = MediaQuery.sizeOf(context);
    return PopScope<void>(
      canPop: _allowClose,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestClose();
      },
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: screen.width * 0.96,
          height: screen.height * 0.94,
          child: Column(
            children: [
              _DialogHeader(
                data: data,
                candidate: candidate,
                stage: stage,
                onClose: _requestClose,
              ),
              const Divider(height: 1),
              Expanded(
                child: data == null || candidate == null
                    ? const Center(child: CircularProgressIndicator())
                    : _CandidateContent(
                        profileKey: _profileKey,
                        panelKey: _panelKey,
                        data: data,
                        candidate: candidate,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogHeader extends ConsumerWidget {
  const _DialogHeader({
    required this.data,
    required this.candidate,
    required this.stage,
    required this.onClose,
  });

  final RecruitingData? data;
  final Candidate? candidate;
  final HiringStage? stage;
  final VoidCallback onClose;

  Future<void> _deleteCandidate(
    BuildContext context,
    WidgetRef ref,
    Candidate candidate,
  ) async {
    final localization = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localization.candidateDelete),
        content: Text(localization.candidateDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localization.candidateCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localization.candidateDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await performCandidateAction(context, localization, () async {
      await ref
          .read(candidateManagementControllerProvider.notifier)
          .deleteCandidate(candidate.id);
      if (context.mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _openResume(
    BuildContext context,
    WidgetRef ref,
    Candidate candidate,
  ) async {
    final localization = AppLocalizations.of(context);
    try {
      final bytes = await ref
          .read(candidateManagementControllerProvider.notifier)
          .readResume(candidate.id);
      if (bytes == null || !context.mounted) return;
      final resume = Uint8List.fromList(bytes);
      final isPdf =
          candidate.cvFileName?.toLowerCase().endsWith('.pdf') ?? false;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(localization.candidateResume)),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SizedBox(
            width: 900,
            height: 700,
            child: isPdf
                ? PdfViewer.data(
                    resume,
                    sourceName: candidate.cvFileName ?? candidate.id,
                  )
                : Image.memory(resume, fit: BoxFit.contain),
          ),
        ),
      );
    } on Exception {
      if (context.mounted) showCandidateActionError(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final evaluationsVisible = ref.watch(evaluationsVisibleProvider);
    final candidate = this.candidate;
    final stage = this.stage;
    final data = this.data;
    final average = evaluationsVisible ? candidate?.averageRating : null;
    final source = data?.sources
        .where((item) => item.id == candidate?.sourceId)
        .firstOrNull;
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (candidate != null) ...[
                  CandidateAvatar(name: candidate.fullName, radius: 24),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate?.fullName ?? '',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (candidate != null &&
                          (candidate.headline.isNotEmpty ||
                              candidate.location.isNotEmpty ||
                              candidate.yearsOfExperience != null))
                        Text(
                          [
                            if (candidate.headline.isNotEmpty)
                              candidate.headline,
                            if (candidate.location.isNotEmpty)
                              candidate.location,
                            if (candidate.yearsOfExperience != null)
                              '${candidate.yearsOfExperience}y',
                          ].join(' · '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (candidate != null) ...[
                  if (candidate.hasResume) ...[
                    OutlinedButton.icon(
                      onPressed: () => _openResume(context, ref, candidate),
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: Text(localization.candidateOpenResume),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (stage != null && stage.isOfferStage) ...[
                    OutlinedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => OfferDialog(candidate: candidate),
                      ),
                      icon: const Icon(Icons.handshake_outlined, size: 18),
                      label: Text(localization.candidateOffer),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    key: const Key('delete-candidate'),
                    tooltip: localization.candidateDelete,
                    onPressed: () => _deleteCandidate(context, ref, candidate),
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  key: const Key('candidate-details-close'),
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (stage != null || average != null || source != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (stage != null) StageBadge(stage: stage),
                  if (candidate != null) PipelineStatus(candidate: candidate),
                  if (source != null) SourceBadge(source: source),
                  if (average != null) AverageRatingBadge(rating: average),
                  if (candidate != null)
                    for (final skill in candidate.skills.take(5))
                      CandidateSkillChip(skill: skill),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CandidateContent extends StatelessWidget {
  const _CandidateContent({
    required this.profileKey,
    required this.panelKey,
    required this.data,
    required this.candidate,
  });

  final RecruitingData data;
  final GlobalKey<_InlineProfileState> profileKey;
  final GlobalKey<_RightPanelState> panelKey;
  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final stage = data.stages.firstWhere(
      (value) => value.id == candidate.stageId,
      orElse: () => data.stages.first,
    );
    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 850) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 640,
                    child: _InlineProfile(
                      key: profileKey,
                      data: data,
                      candidate: candidate,
                      stage: stage,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 800,
                    child: _RightPanel(
                      key: panelKey,
                      data: data,
                      candidate: candidate,
                      stage: stage,
                    ),
                  ),
                ],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 460,
                child: _InlineProfile(
                  key: profileKey,
                  data: data,
                  candidate: candidate,
                  stage: stage,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _RightPanel(
                  key: panelKey,
                  data: data,
                  candidate: candidate,
                  stage: stage,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RightPanel extends StatefulWidget {
  const _RightPanel({
    super.key,
    required this.data,
    required this.candidate,
    required this.stage,
  });

  final RecruitingData data;
  final Candidate candidate;
  final HiringStage stage;

  @override
  State<_RightPanel> createState() => _RightPanelState();
}

class _RightPanelState extends State<_RightPanel> {
  String? _selectedStageId;
  final _stepKey = GlobalKey<_StepFeedbackState>();
  final _scrollController = ScrollController();
  final _sidebarScrollController = ScrollController();

  Future<bool> confirmLeave() async =>
      await _stepKey.currentState?.confirmLeave() ?? true;

  Future<void> _select(HiringStage stage) async {
    if (stage.id == _selectedStageId) return;
    if (!(await _stepKey.currentState?.confirmLeave() ?? true) || !mounted) {
      return;
    }
    setState(() => _selectedStageId = stage.id);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _closeStep() async {
    if (!(await confirmLeave()) || !mounted) return;
    setState(() => _selectedStageId = null);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Widget _scrollContent(
    Widget child, {
    ScrollController? controller,
    String name = 'candidate-overview-scrollbar',
  }) {
    final scroll = controller ?? _scrollController;
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: Scrollbar(
        key: ValueKey(name),
        controller: scroll,
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(8),
        child: SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.only(right: 18),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _sidebarScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _RightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage.id != widget.stage.id) _selectedStageId = null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final selected = widget.data.stages.firstWhere(
        (stage) => stage.id == (_selectedStageId ?? widget.stage.id),
        orElse: () => widget.stage,
      );
      final timeline = _PipelineOverviewCard(
        data: widget.data,
        candidate: widget.candidate,
        stage: widget.stage,
        selectedStageId: _selectedStageId,
        onSelect: _select,
      );
      if (_selectedStageId == null) {
        return _scrollContent(
          constraints.maxWidth >= 600
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: timeline),
                    const SizedBox(width: 24),
                    Expanded(child: _RatingsCard(candidate: widget.candidate)),
                  ],
                )
              : Column(
                  children: [
                    timeline,
                    const SizedBox(height: 24),
                    _RatingsCard(candidate: widget.candidate),
                  ],
                ),
        );
      }
      final activity = _StepFeedback(
        key: _stepKey,
        candidate: widget.candidate,
        stage: selected,
        data: widget.data,
        onClose: _closeStep,
      );
      if (constraints.maxWidth < 850) {
        return _scrollContent(
          Column(
            children: [
              activity,
              const SizedBox(height: 24),
              timeline,
              const SizedBox(height: 20),
              _RatingsCard(candidate: widget.candidate),
            ],
          ),
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 270,
            child: _scrollContent(
              Column(
                children: [
                  timeline,
                  const SizedBox(height: 20),
                  _RatingsCard(candidate: widget.candidate),
                ],
              ),
              controller: _sidebarScrollController,
              name: 'candidate-pipeline-scrollbar',
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: _scrollContent(activity, name: 'candidate-step-scrollbar'),
          ),
        ],
      );
    },
  );
}

/// A quiet, ordered timeline keeps the current step distinct from its history.
class _PipelineOverviewCard extends StatelessWidget {
  const _PipelineOverviewCard({
    required this.data,
    required this.candidate,
    required this.stage,
    required this.selectedStageId,
    required this.onSelect,
  });
  final RecruitingData data;
  final Candidate candidate;
  final HiringStage stage;
  final String? selectedStageId;
  final ValueChanged<HiringStage> onSelect;

  bool _completed(HiringStage step, int index, int currentIndex) =>
      index < currentIndex ||
      stage.terminalOutcome == TerminalOutcome.hired ||
      (stage.terminalOutcome == TerminalOutcome.rejected &&
          candidate.latestFeedbackFor(step.id) != null);

  DateTime? _eventDate(HiringStage step) {
    if (step.isOfferStage) {
      return candidate.offer?.recordedAt ?? candidate.offer?.proposedStartDate;
    }
    final record = candidate.latestFeedbackFor(step.id);
    return record?.scheduledAt ?? record?.createdAt;
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final steps = data.activeStages;
    final currentIndex = steps.indexWhere((item) => item.id == stage.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localization.candidateHiringProcess,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        for (var index = 0; index < steps.length; index++)
          _PipelineStepLink(
            stage: steps[index],
            selected: steps[index].id == selectedStageId,
            onOpen: () => onSelect(steps[index]),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 32,
                    child: Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index == currentIndex
                                ? theme.colorScheme.primary
                                : _completed(steps[index], index, currentIndex)
                                ? const Color(0xFFE4EFE8)
                                : theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: _completed(steps[index], index, currentIndex)
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Color(0xFF247243),
                                )
                              : Text(
                                  '${index + 1}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: index == currentIndex
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                        ),
                        if (index < steps.length)
                          Expanded(
                            child: Container(
                              width: 1,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: 5,
                        bottom: _eventDate(steps[index]) == null ? 22 : 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizedStageName(localization, steps[index]),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: steps[index].id == selectedStageId
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: steps[index].id == selectedStageId
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (_eventDate(steps[index]) case final date?)
                            _PipelineEventDate(
                              key: ValueKey('pipeline-date-${steps[index].id}'),
                              date: date,
                              isStartDate:
                                  steps[index].isOfferStage &&
                                  candidate.offer?.recordedAt == null,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        _PipelineOutcome(
          candidate: candidate,
          stage: stage,
          selectedStageId: selectedStageId,
          onSelect: onSelect,
        ),
      ],
    );
  }
}

class _PipelineEventDate extends StatelessWidget {
  const _PipelineEventDate({
    super.key,
    required this.date,
    this.isStartDate = false,
  });

  final DateTime date;
  final bool isStartDate;

  @override
  Widget build(BuildContext context) {
    final formatted = MaterialLocalizations.of(context)
        .formatShortDate(date.toLocal());
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        isStartDate
            ? AppLocalizations.of(context).pipelineStartDate(formatted)
            : formatted,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11,
          height: 1.2,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PipelineOutcome extends StatelessWidget {
  const _PipelineOutcome({
    required this.candidate,
    required this.stage,
    required this.selectedStageId,
    required this.onSelect,
  });

  final Candidate candidate;
  final HiringStage stage;
  final String? selectedStageId;
  final ValueChanged<HiringStage> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localization = AppLocalizations.of(context);
    final resolved = stage.terminalOutcome != TerminalOutcome.active;
    final color = resolved
        ? stageAccentColor(context, stage)
        : theme.colorScheme.onSurfaceVariant;
    return _PipelineStepLink(
      stage: stage,
      selected: resolved && selectedStageId == stage.id,
      onOpen: resolved ? () => onSelect(stage) : null,
      child: Row(
        key: ValueKey('pipeline-outcome-${resolved ? stage.id : 'pending'}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(
              !resolved
                  ? Icons.flag_outlined
                  : stage.terminalOutcome == TerminalOutcome.hired
                  ? Icons.check_rounded
                  : Icons.close_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resolved
                        ? localizedStageName(localization, stage)
                        : localization.pipelineOutcome,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: resolved ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (stage.terminalOutcome == TerminalOutcome.hired)
                    if (candidate.employmentPlan?.hiredAt case final date?)
                      _PipelineEventDate(
                        key: ValueKey('pipeline-date-${stage.id}'),
                        date: date,
                      ),
                  if (!resolved) ...[
                    const SizedBox(height: 4),
                    Text(
                      localization.pipelineOutcomeOptions,
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The full pipeline row is a single, accessible step action.
class _PipelineStepLink extends StatelessWidget {
  const _PipelineStepLink({
    required this.stage,
    required this.selected,
    required this.onOpen,
    required this.child,
  });
  final HiringStage stage;
  final bool selected;
  final VoidCallback? onOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: onOpen != null,
    child: Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        key: ValueKey(
          selected || onOpen == null
              ? 'pipeline-step-${stage.id}'
              : 'view-step-${stage.id}',
        ),
        borderRadius: BorderRadius.circular(10),
        onTap: selected ? null : onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: child,
        ),
      ),
    ),
  );
}

/// The candidate's single rating; every change is saved immediately.
class _RatingsCard extends ConsumerWidget {
  const _RatingsCard({required this.candidate});

  final Candidate candidate;

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    RatingAspect aspect,
    double? value,
  ) async {
    final ratings = Map<RatingAspect, double>.of(candidate.ratings);
    if (value == null) {
      ratings.remove(aspect);
    } else {
      ratings[aspect] = value;
    }
    try {
      await ref
          .read(candidateManagementControllerProvider.notifier)
          .saveCandidate(
            candidate.copyWith(
              ratings: ratings,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
    } on Exception {
      if (context.mounted) showCandidateActionError(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (!ref.watch(evaluationsVisibleProvider)) return const SizedBox.shrink();
    final format = NumberFormat.decimalPatternDigits(
      locale: Localizations.localeOf(context).toString(),
      decimalDigits: 1,
    );
    final average = candidate.averageRating;
    return Card(
      key: const Key('candidate-ratings-card'),
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              key: const Key('candidate-rating-summary'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      localization.candidateRatings,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Semantics(
                      label: localization.candidateAverageRating,
                      child: Text(
                        average == null
                            ? localization.candidateRatingNotRated
                            : localization.candidateRatingScore(
                                format.format(average),
                              ),
                        key: const Key('candidate-rating-average'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  localization.candidateRatedCriteria(
                    candidate.ratings.length,
                    RatingAspect.values.length,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Divider(
              height: 28,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            for (final aspect in RatingAspect.values)
              Padding(
                padding: EdgeInsets.only(
                  bottom: aspect == RatingAspect.values.last ? 0 : 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      localizedRatingAspect(localization, aspect),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StarRating(
                          key: ValueKey('candidate-rating-${aspect.name}'),
                          value: candidate.ratings[aspect],
                          size: 26,
                          onChanged: (value) =>
                              _update(context, ref, aspect, value),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            candidate.ratings[aspect] == null
                                ? localization.candidateRatingNotRated
                                : format.format(candidate.ratings[aspect]!),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InlineProfile extends ConsumerStatefulWidget {
  const _InlineProfile({
    super.key,
    required this.data,
    required this.candidate,
    required this.stage,
  });

  final RecruitingData data;
  final Candidate candidate;
  final HiringStage stage;

  @override
  ConsumerState<_InlineProfile> createState() => _InlineProfileState();
}

class _InlineProfileState extends ConsumerState<_InlineProfile> {
  late final CandidateProfileControllers _form;
  bool _saving = false;
  final _firstNameKey = GlobalKey();
  final _experienceKey = GlobalKey();
  late List<String> _savedValues;
  bool _confirmingClose = false;

  bool get _dirty {
    final values = _form.snapshot;
    for (var index = 0; index < values.length; index++) {
      if (values[index] != _savedValues[index]) return true;
    }
    return false;
  }

  void _onProfileChanged() => setState(() {});

  Future<bool> confirmLeave() async {
    if (_saving || _confirmingClose) return false;
    if (_dirty) {
      _confirmingClose = true;
      final discard = await confirmDiscardChanges(context);
      _confirmingClose = false;
      if (!discard || !mounted) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _form = CandidateProfileControllers(
      candidate: widget.candidate,
      defaultSourceId: widget.candidate.sourceId,
    );
    _savedValues = _form.snapshot;
    _form.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final sources = {
      for (final source in widget.data.sources)
        source.id: localizedSourceName(localization, source),
    };
    return Card(
      key: const Key('candidate-profile'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _actions(localization),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(
                      _form.firstName,
                      localization.candidateFirstName,
                      icon: Icons.badge_outlined,
                    ),
                    _field(
                      _form.lastName,
                      localization.candidateLastName,
                      icon: Icons.person_outline,
                    ),
                    _field(
                      _form.email,
                      localization.candidateEmail,
                      icon: Icons.email_outlined,
                    ),
                    _field(
                      _form.phone,
                      localization.candidatePhone,
                      icon: Icons.phone_outlined,
                    ),
                    _field(
                      _form.location,
                      localization.candidateLocation,
                      icon: Icons.location_on_outlined,
                    ),
                    _field(
                      _form.headline,
                      localization.candidateHeadline,
                      icon: Icons.work_outline,
                    ),
                    _field(
                      _form.skills,
                      localization.candidateSkills,
                      maxLines: 2,
                      icon: Icons.code,
                    ),
                    _field(
                      _form.experience,
                      localization.candidateExperience,
                      keyboardType: TextInputType.number,
                      icon: Icons.work_history_outlined,
                    ),
                    _sourceField(sources, localization),
                    _field(
                      _form.github,
                      localization.candidateGithubUrl,
                      icon: Icons.terminal,
                    ),
                    _field(
                      _form.linkedin,
                      localization.candidateLinkedinUrl,
                      icon: Icons.business_center_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(AppLocalizations localization) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      FilledButton.icon(
        onPressed: _saving || !_dirty ? null : _save,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save_outlined),
        label: Text(localization.candidateSave),
      ),
      if (widget.stage.isOfferStage)
        OutlinedButton.icon(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => OfferDialog(candidate: widget.candidate),
          ),
          icon: const Icon(Icons.handshake_outlined),
          label: Text(localization.candidateOffer),
        ),
      if (widget.candidate.hasResume)
        OutlinedButton.icon(
          onPressed: () => _openResume(context),
          icon: const Icon(Icons.description_outlined),
          label: Text(localization.candidateOpenResume),
        ),
      if (widget.candidate.githubUrl.isNotEmpty)
        OutlinedButton.icon(
          onPressed: () => launchUrl(
            Uri.parse(widget.candidate.githubUrl),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new),
          label: Text(localization.candidateOpenProfile),
        ),
      if (widget.candidate.linkedinUrl.isNotEmpty)
        OutlinedButton.icon(
          onPressed: () => launchUrl(
            Uri.parse(widget.candidate.linkedinUrl),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new),
          label: Text(localization.candidateLinkedinUrl),
        ),
    ],
  );

  Widget _sourceField(
    Map<String, String> sources,
    AppLocalizations localization,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: _form.sourceId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: localization.candidateSource,
        prefixIcon: const Icon(Icons.source_outlined, size: 20),
      ),
      items: sources.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: _saving
          ? null
          : (value) {
              if (value != null) setState(() => _form.sourceId = value);
            },
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? icon,
  }) => Padding(
    key: controller == _form.firstName
        ? _firstNameKey
        : controller == _form.experience
        ? _experienceKey
        : null,
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      readOnly: _saving,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) {
        if (controller == _form.firstName && _form.firstNameError != null) {
          setState(() => _form.firstNameError = null);
        }
        if (controller == _form.experience && _form.experienceError != null) {
          setState(() => _form.experienceError = null);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
        errorText: controller == _form.firstName
            ? _form.firstNameError
            : controller == _form.experience
            ? _form.experienceError
            : null,
      ),
    ),
  );

  Future<void> _save() async {
    final localization = AppLocalizations.of(context);
    var isValid = false;
    setState(() => isValid = _form.validate(localization));
    if (!isValid) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final fieldContext =
          (_form.firstNameError != null ? _firstNameKey : _experienceKey)
              .currentContext;
      if (fieldContext != null && fieldContext.mounted) {
        await Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 200),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(candidateManagementControllerProvider.notifier)
          .saveCandidate(_form.toCandidate(existing: widget.candidate));
      if (mounted) {
        setState(() => _savedValues = _form.snapshot);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.candidateProfileSaved)),
        );
      }
    } on Exception {
      if (mounted) showCandidateActionError(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openResume(BuildContext context) async {
    final localization = AppLocalizations.of(context);
    try {
      final bytes = await ref
          .read(candidateManagementControllerProvider.notifier)
          .readResume(widget.candidate.id);
      if (bytes == null || !context.mounted) return;
      final resume = Uint8List.fromList(bytes);
      final isPdf =
          widget.candidate.cvFileName?.toLowerCase().endsWith('.pdf') ?? false;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(localization.candidateResume)),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SizedBox(
            width: 900,
            height: 700,
            child: isPdf
                ? PdfViewer.data(
                    resume,
                    sourceName:
                        widget.candidate.cvFileName ?? widget.candidate.id,
                  )
                : Image.memory(resume, fit: BoxFit.contain),
          ),
        ),
      );
    } on Exception {
      if (context.mounted) showCandidateActionError(context);
    }
  }
}

/// Reads and edits the selected step in place.
class _StepFeedback extends ConsumerStatefulWidget {
  const _StepFeedback({
    super.key,
    required this.candidate,
    required this.stage,
    required this.data,
    required this.onClose,
  });
  final Candidate candidate;
  final HiringStage stage;
  final RecruitingData data;

  final VoidCallback onClose;

  @override
  ConsumerState<_StepFeedback> createState() => _StepFeedbackState();
}

class _StepFeedbackState extends ConsumerState<_StepFeedback> {
  var _formKey = GlobalKey<InterviewFeedbackFormState>();
  late bool _editing;
  bool _saved = false;

  InterviewRecord? get _record =>
      widget.candidate.latestFeedbackFor(widget.stage.id);

  @override
  void initState() {
    super.initState();
    _editing = _record == null || _record!.notes.trim().isEmpty;
  }

  @override
  void didUpdateWidget(covariant _StepFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage.id != widget.stage.id) {
      _formKey = GlobalKey<InterviewFeedbackFormState>();
      _editing = _record == null || _record!.notes.trim().isEmpty;
      _saved = false;
    }
  }

  Future<bool> confirmLeave() async =>
      await _formKey.currentState?.confirmLeave() ?? true;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final record = _record;
    final isCurrent = widget.stage.id == widget.candidate.stageId;
    final canEdit =
        widget.data.requiresFeedback(widget.stage.id) &&
        (isCurrent || record != null);
    final destinations = isCurrent
        ? widget.data.availableDestinationsFor(widget.candidate, widget.stage)
        : const <HiringStage>[];
    return Padding(
      key: ValueKey('feedback-step-${widget.stage.id}'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localizedStageName(localization, widget.stage),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              IconButton(
                key: const Key('close-step-notes'),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_saved) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                localization.candidateFeedbackSaved,
                key: const Key('feedback-save-success'),
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_editing && canEdit)
            SizedBox(
              height: widget.stage.isInterview ? 600 : 450,
              child: InterviewFeedbackForm(
                key: _formKey,
                candidate: widget.candidate,
                stage: widget.stage,
                existing: record,
                inline: true,
                onSaved: () => setState(() {
                  _editing = false;
                  _saved = true;
                }),
                onCancel: () => setState(() => _editing = false),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    localization.candidateFeedbackNotes,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (canEdit)
                  IconButton(
                    key: const Key('selection-edit-step'),
                    tooltip: localization.candidateEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => setState(() {
                      _editing = true;
                      _saved = false;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: ValueKey('feedback-readonly-${widget.stage.id}'),
              initialValue: record?.notes ?? '',
              readOnly: true,
              minLines: 6,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: localization.candidateFeedbackNone,
              ),
            ),
            if (record != null) ...[
              const SizedBox(height: 12),
              Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(record.createdAt.toLocal()),
              ),
              if (record.scheduledAt case final appointment?)
                Text(
                  '${MaterialLocalizations.of(context).formatMediumDate(appointment.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(appointment.toLocal()))}',
                ),
              if (record.interviewer.isNotEmpty) Text(record.interviewer),
              if (widget.stage.isInterview) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (ref.watch(evaluationsVisibleProvider))
                      FeedbackBadge(decision: record.decision),
                    if (record.decision != FeedbackDecision.pending)
                      CandidateCommunicationToggle(
                        candidateId: widget.candidate.id,
                        record: record,
                      ),
                  ],
                ),
              ],
            ],
          ],
          if (isCurrent && !_editing) ...[
            const SizedBox(height: 16),
            PipelineStatus(candidate: widget.candidate),
          ],
          if (isCurrent && !(_editing && canEdit)) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                if (widget.stage.isOfferStage)
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => OfferDialog(candidate: widget.candidate),
                    ),
                    icon: const Icon(Icons.handshake_outlined, size: 18),
                    label: Text(localization.candidateOffer),
                  ),
                for (final destination in destinations)
                  FilledButton.icon(
                    key: ValueKey('selection-advance-${destination.id}'),
                    onPressed: () => moveCandidateWithHiringPlan(
                      context,
                      ref,
                      widget.candidate.id,
                      destination.id,
                    ),
                    icon: Icon(
                      destination.terminalOutcome == TerminalOutcome.rejected
                          ? Icons.close
                          : Icons.arrow_forward,
                      size: 18,
                    ),
                    label: Text(
                      localization.candidateAdvanceStage(
                        localizedStageName(localization, destination),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
