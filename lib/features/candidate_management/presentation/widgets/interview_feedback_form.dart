import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../../domain/failures/candidate_repository_exception.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_dialog_support.dart';

/// Large dialog hosting [InterviewFeedbackForm]; pops `true` once saved.
class InterviewFeedbackDialog extends StatefulWidget {
  const InterviewFeedbackDialog({
    super.key,
    required this.candidate,
    required this.stage,
    this.existing,
  });

  final Candidate candidate;
  final HiringStage stage;
  final InterviewRecord? existing;

  @override
  State<InterviewFeedbackDialog> createState() =>
      _InterviewFeedbackDialogState();
}

class _InterviewFeedbackDialogState extends State<InterviewFeedbackDialog> {
  final _formKey = GlobalKey<_InterviewFeedbackFormState>();

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: math.min(860, screen.width - 48),
        height: math.min(680, screen.height - 48),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  key: const Key('feedback-close'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => _formKey.currentState?.requestClose(),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InterviewFeedbackForm(
                    key: _formKey,
                    candidate: widget.candidate,
                    stage: widget.stage,
                    existing: widget.existing,
                    onSaved: () => Navigator.of(context).pop(true),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Feedback editor for one stage; it creates the stage's single feedback or
/// edits the one already saved.
class InterviewFeedbackForm extends ConsumerStatefulWidget {
  const InterviewFeedbackForm({
    super.key,
    required this.candidate,
    required this.stage,
    required this.onSaved,
    this.existing,
  });

  final Candidate candidate;
  final HiringStage stage;
  final InterviewRecord? existing;
  final VoidCallback onSaved;

  @override
  ConsumerState<InterviewFeedbackForm> createState() =>
      _InterviewFeedbackFormState();
}

class _InterviewFeedbackFormState extends ConsumerState<InterviewFeedbackForm> {
  late final TextEditingController _notes;
  late FeedbackDecision? _decision;
  late final TextEditingController _interviewer;
  DateTime? _scheduledAt;
  late bool _feedbackSharedWithCandidate;
  late final DateTime _initialDate;
  late DateTime _recordedAt;
  bool _saving = false;
  bool _allowClose = false;
  bool _confirmingClose = false;

  bool get _effectiveShared =>
      _decision != null &&
      _decision != FeedbackDecision.pending &&
      _feedbackSharedWithCandidate;

  bool get _dirty =>
      _scheduledAt != widget.existing?.scheduledAt?.toLocal() ||
      _interviewer.text != (widget.existing?.interviewer ?? '') ||
      _notes.text != (widget.existing?.notes ?? '') ||
      _decision != (widget.existing?.decision ?? FeedbackDecision.pending) ||
      _effectiveShared !=
          (widget.existing?.feedbackSharedWithCandidate ?? false) ||
      !DateUtils.isSameDay(_recordedAt, _initialDate);

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _decision = widget.existing?.decision ?? FeedbackDecision.pending;
    _interviewer = TextEditingController(
      text: widget.existing?.interviewer ?? '',
    );
    _interviewer.addListener(_onChanged);
    _scheduledAt = widget.existing?.scheduledAt?.toLocal();
    _feedbackSharedWithCandidate =
        widget.existing?.feedbackSharedWithCandidate ?? false;
    final baseDate = (widget.existing?.createdAt ?? DateTime.now()).toLocal();
    _initialDate = DateUtils.dateOnly(baseDate);
    _recordedAt = _initialDate;
    _notes.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  Future<void> _pickDate() async {
    if (_saving) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
      helpText: AppLocalizations.of(context).candidateFeedbackDate,
    );
    if (picked != null && mounted) {
      setState(() => _recordedAt = DateUtils.dateOnly(picked));
    }
  }

  Future<void> requestClose() async {
    if (_saving || _confirmingClose) return;
    if (_dirty) {
      _confirmingClose = true;
      final discard = await confirmDiscardChanges(context);
      _confirmingClose = false;
      if (!discard || !mounted) return;
    }
    setState(() => _allowClose = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  void dispose() {
    _notes.dispose();
    _interviewer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isInterview = widget.stage.isInterview;
    final formattedDate = MaterialLocalizations.of(context)
        .formatMediumDate(_recordedAt);
    final dateLabel = isInterview
        ? localization.candidateFeedbackDate
        : localization.candidateEvaluationDate;
    final categoryLabel = isInterview
        ? localization.candidateInterviewStep
        : localization.candidateStageEvaluation;
    final categoryIcon = isInterview
        ? Icons.record_voice_over_outlined
        : Icons.fact_check_outlined;
    return PopScope<bool>(
      canPop: _allowClose || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) requestClose();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                categoryIcon,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                categoryLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            localizedStageName(localization, widget.stage),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.candidate.fullName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        key: const Key('feedback-date'),
                        onPressed: _saving ? null : _pickDate,
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                        ),
                        label: Text('$dateLabel: $formattedDate'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isInterview) ...[
                    TextField(
                      key: const Key('interview-interviewer'),
                      controller: _interviewer,
                      enabled: !_saving,
                      decoration: InputDecoration(
                        labelText: localization.pipelineInterviewer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const Key('interview-schedule'),
                      onPressed: _saving ? null : _schedule,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        _scheduledAt == null
                            ? localization.pipelineSchedule
                            : '${MaterialLocalizations.of(context).formatMediumDate(_scheduledAt!)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_scheduledAt!))}',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (isInterview)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              localization.candidateOverallDecision,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            for (final (decision, icon, color) in const [
                              (
                                FeedbackDecision.positive,
                                Icons.check_circle_outline,
                                Color(0xFF1E8E3E),
                              ),
                              (
                                FeedbackDecision.pending,
                                Icons.schedule,
                                Color(0xFF5F6B7A),
                              ),
                              (
                                FeedbackDecision.negative,
                                Icons.cancel_outlined,
                                Color(0xFFD93025),
                              ),
                            ])
                              ChoiceChip(
                                key: ValueKey(
                                  'feedback-decision-${decision.name}',
                                ),
                                avatar: Icon(
                                  icon,
                                  size: 18,
                                  color: _decision == decision
                                      ? color
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                selectedColor: color.withValues(alpha: 0.16),
                                label: Text(
                                  localizedDecision(localization, decision),
                                  style: TextStyle(
                                    color: _decision == decision ? color : null,
                                    fontWeight: _decision == decision
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                selected: _decision == decision,
                                onSelected: _saving
                                    ? null
                                    : (_) => setState(() {
                                        if (_decision != decision) {
                                          _feedbackSharedWithCandidate = false;
                                        }
                                        _decision = decision;
                                      }),
                              ),
                            if (_decision != FeedbackDecision.pending)
                              FilterChip(
                                key: const Key(
                                  'feedback-shared-with-candidate',
                                ),
                                selected: _feedbackSharedWithCandidate,
                                onSelected: _saving
                                    ? null
                                    : (value) => setState(
                                        () => _feedbackSharedWithCandidate =
                                            value,
                                      ),
                                label: Text(
                                  localization.candidateFeedbackSentToCandidate,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 240,
                    child: TextField(
                      key: const Key('feedback-notes'),
                      controller: _notes,
                      readOnly: _saving,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        labelText: localization.candidateFeedbackNotes,
                        hintText: isInterview
                            ? localization.candidateFeedbackNotes
                            : localization.candidateEvaluationNotes,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _saving ? null : requestClose,
                child: Text(localization.candidateCancel),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                key: const Key('feedback-save'),
                onPressed: _saving || !_dirty ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(localization.candidateFeedbackSave),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _schedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );
    if (time != null && mounted) {
      setState(
        () => _scheduledAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    final decision = _decision;
    if (decision == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(candidateManagementControllerProvider.notifier)
          .saveFeedback(
            widget.candidate.id,
            stageId: widget.stage.id,
            decision: decision,
            notes: _notes.text.trim(),
            recordedAt: DateTime.utc(
              _recordedAt.year,
              _recordedAt.month,
              _recordedAt.day,
              12,
            ),
            feedbackSharedWithCandidate: _effectiveShared,
            scheduledAt: _scheduledAt,
            interviewer: _interviewer.text,
          );
      if (!mounted) return;
      setState(() => _allowClose = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) widget.onSaved();
    } on CandidateRepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              candidateRepositoryErrorMessage(
                AppLocalizations.of(context),
                error,
              ),
            ),
          ),
        );
      }
    } on Exception {
      if (mounted) showCandidateActionError(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
