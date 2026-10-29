import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
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
  bool _saving = false;
  bool _allowClose = false;
  bool _confirmingClose = false;

  bool get _dirty =>
      _notes.text != (widget.existing?.notes ?? '') ||
      _decision != widget.existing?.decision;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _decision = widget.existing?.decision;
    _notes.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return PopScope<bool>(
      canPop: _allowClose || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) requestClose();
      },
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: SizedBox(
            height: math.max(440, constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedStageName(localization, widget.stage),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.candidate.fullName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: _notes,
                    readOnly: _saving,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      labelText: localization.candidateFeedbackNotes,
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      localization.candidateOverallDecision,
                      style: theme.textTheme.titleSmall,
                    ),
                    for (final decision in [
                      FeedbackDecision.positive,
                      FeedbackDecision.neutral,
                      FeedbackDecision.negative,
                    ])
                      ChoiceChip(
                        label: Text(localizedDecision(localization, decision)),
                        selected: _decision == decision,
                        onSelected: _saving
                            ? null
                            : (_) => setState(() => _decision = decision),
                      ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: _saving || _decision == null || !_dirty
                          ? null
                          : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(localization.candidateFeedbackSave),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          );
      if (!mounted) return;
      setState(() => _allowClose = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) widget.onSaved();
    } on Object {
      if (mounted) showCandidateActionError(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
