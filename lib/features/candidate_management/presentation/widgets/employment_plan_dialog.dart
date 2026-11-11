import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/employment_plan.dart';
import '../../domain/entities/recruiting_data.dart';
import '../../domain/failures/candidate_repository_exception.dart';
import '../../domain/usecases/build_follow_up_calendar.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_dialog_support.dart';
import 'offer_dialog.dart';

Future<void> moveCandidateWithHiringPlan(
  BuildContext context,
  WidgetRef ref,
  String candidateId,
  String stageId,
) async {
  final data = ref.read(candidateManagementControllerProvider).asData?.value;
  if (data == null) return;
  final stage = data.stages.where((stage) => stage.id == stageId).firstOrNull;
  if (stage?.terminalOutcome == TerminalOutcome.hired) {
    final candidate = data.candidates
        .where((candidate) => candidate.id == candidateId)
        .firstOrNull;
    if (candidate == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EmploymentPlanDialog(
        candidate: candidate,
        destinationStageId: stageId,
      ),
    );
    return;
  }
  await performCandidateAction(
    context,
    AppLocalizations.of(context),
    () => ref
        .read(candidateManagementControllerProvider.notifier)
        .moveCandidate(candidateId, stageId),
  );
}

Future<void> exportEmploymentCalendar(
  BuildContext context,
  Candidate person,
) async {
  final localization = AppLocalizations.of(context);
  try {
    final calendar = const BuildFollowUpCalendar()(
      person: person,
      generatedAt: DateTime.now(),
      milestoneLabel: localization.employmentMilestone,
    );
    final uri = await FilePicker.saveFile(
      fileName: 'follow-up-meetings.ics',
      bytes: Uint8List.fromList(utf8.encode(calendar)),
      mimeType: 'text/calendar',
    );
    if (uri != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localization.employmentCalendarSaved,
            key: const Key('employment-calendar-saved'),
          ),
        ),
      );
    }
  } on Exception {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localization.employmentCalendarExportFailed)),
      );
    }
  }
}

class EmploymentPlanDialog extends ConsumerStatefulWidget {
  const EmploymentPlanDialog({
    super.key,
    required this.candidate,
    this.destinationStageId,
  });

  final Candidate candidate;
  final String? destinationStageId;

  @override
  ConsumerState<EmploymentPlanDialog> createState() =>
      _EmploymentPlanDialogState();
}

class _EmploymentPlanDialogState extends ConsumerState<EmploymentPlanDialog> {
  late EmploymentPlan _plan;
  bool _saving = false;
  bool _allowClose = false;
  bool _dirty = false;
  bool _confirming = false;
  bool _exportCalendar = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _plan =
        widget.candidate.employmentPlan ??
        EmploymentPlan.propose(
          widget.candidate.offer?.proposedStartDate ?? DateTime.now(),
        );
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(1900),
    lastDate: DateTime(2200),
  );

  Future<void> _pickHiringDate() async {
    final date = await _pickDate(_plan.hiredAt);
    if (date == null || !mounted) return;
    final proposed = EmploymentPlan.propose(date);
    setState(() {
      _plan = EmploymentPlan(
        hiredAt: proposed.hiredAt,
        followUps: [
          for (final meeting in proposed.followUps)
            meeting.copyWith(
              completed: _plan.followUps
                  .firstWhere(
                    (item) =>
                        item.monthsAfterHiring == meeting.monthsAfterHiring,
                  )
                  .completed,
            ),
        ],
      );
      _dirty = true;
    });
  }

  Future<void> _pickMeeting(EmploymentFollowUp meeting) async {
    final date = await _pickDate(meeting.scheduledAt);
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(meeting.scheduledAt),
    );
    if (time == null || !mounted) return;
    _replaceMeeting(
      meeting.copyWith(
        scheduledAt: DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      ),
    );
  }

  void _replaceMeeting(EmploymentFollowUp updated) => setState(() {
    _plan = EmploymentPlan(
      hiredAt: _plan.hiredAt,
      followUps: [
        for (final meeting in _plan.followUps)
          meeting.monthsAfterHiring == updated.monthsAfterHiring
              ? updated
              : meeting,
      ],
    );
    _dirty = true;
  });

  Future<void> _close() async {
    if (_saving || _confirming) return;
    if (_dirty) {
      _confirming = true;
      final discard = await confirmDiscardChanges(context);
      _confirming = false;
      if (!discard || !mounted) return;
    }
    setState(() => _allowClose = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  Future<void> _editOffer(Candidate candidate) async {
    await showDialog<void>(
      context: context,
      builder: (_) => OfferDialog(candidate: candidate),
    );
    if (mounted) setState(() => _error = null);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_plan.isValid) {
      setState(
        () => _error = AppLocalizations.of(context).employmentPlanInvalid,
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final controller = ref.read(
        candidateManagementControllerProvider.notifier,
      );
      if (widget.destinationStageId case final stageId?) {
        await controller.moveCandidate(
          widget.candidate.id,
          stageId,
          employmentPlan: _plan,
        );
      } else {
        await controller.saveEmploymentPlan(widget.candidate.id, _plan);
      }
      if (!mounted) return;
      final localization = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.destinationStageId == null
                ? localization.employmentPlanSaved
                : localization.employmentHireSaved,
          ),
        ),
      );
      if (_exportCalendar) {
        await exportEmploymentCalendar(
          context,
          widget.candidate.copyWith(employmentPlan: _plan),
        );
        if (!mounted) return;
      }
      setState(() => _allowClose = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.pop(context);
    } on CandidateRepositoryException catch (error) {
      if (mounted) {
        setState(
          () => _error = candidateRepositoryErrorMessage(
            AppLocalizations.of(context),
            error,
          ),
        );
      }
    } on Exception {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).candidateActionFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final data = ref.watch(candidateManagementControllerProvider).asData?.value;
    final candidate =
        data?.candidates
            .where((candidate) => candidate.id == widget.candidate.id)
            .firstOrNull ??
        widget.candidate;
    return PopScope<void>(
      canPop: _allowClose || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: AlertDialog(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localization.employmentPlanTitle),
            if (_error case final error?) ...[
              const SizedBox(height: 12),
              Text(
                error,
                key: const Key('employment-plan-error'),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.candidate.fullName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(localization.employmentPlanDescription),
                const SizedBox(height: 12),
                Text(
                  widget.destinationStageId == null
                      ? localization.employmentSaveExplanation
                      : localization.employmentHireExplanation,
                ),
                if (widget.destinationStageId != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${localization.candidateOfferStatus}: ${candidate.offer == null ? localization.candidateOfferMissing : localizedOfferStatus(localization, candidate.offer!.status)}',
                    key: const Key('employment-offer-status'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('employment-edit-offer'),
                    onPressed: _saving ? null : () => _editOffer(candidate),
                    icon: const Icon(Icons.handshake_outlined),
                    label: Text(localization.candidateOffer),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('employment-hiring-date'),
                  onPressed: _saving ? null : _pickHiringDate,
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    '${localization.employmentHiringDate}: ${material.formatMediumDate(_plan.hiredAt)}',
                  ),
                ),
                for (final meeting in _plan.followUps)
                  ListTile(
                    title: Text(
                      localization.employmentMilestone(
                        meeting.monthsAfterHiring,
                      ),
                    ),
                    subtitle: Text(
                      '${material.formatMediumDate(meeting.scheduledAt)} · ${material.formatTimeOfDay(TimeOfDay.fromDateTime(meeting.scheduledAt))}',
                    ),
                    trailing: widget.destinationStageId == null
                        ? Checkbox(
                            key: ValueKey(
                              'employment-completed-${meeting.monthsAfterHiring}',
                            ),
                            semanticLabel:
                                localization.employmentMeetingCompleted,
                            value: meeting.completed,
                            onChanged: _saving
                                ? null
                                : (value) => _replaceMeeting(
                                    meeting.copyWith(completed: value),
                                  ),
                          )
                        : const Icon(Icons.edit_calendar_outlined),
                    key: ValueKey(
                      'employment-meeting-${meeting.monthsAfterHiring}',
                    ),
                    onTap: _saving ? null : () => _pickMeeting(meeting),
                  ),
                const SizedBox(height: 12),
                Text(
                  localization.employmentRemindersInfo,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                CheckboxListTile(
                  key: const Key('employment-save-export'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(localization.employmentExportOnSave),
                  subtitle: Text(localization.employmentExportExplanation),
                  value: _exportCalendar,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          _exportCalendar = value ?? false;
                        }),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _close,
            child: Text(localization.candidateCancel),
          ),
          FilledButton(
            key: const Key('employment-plan-save'),
            onPressed: _saving ? null : _save,
            child: Text(
              widget.destinationStageId == null
                  ? localization.employmentPlanSave
                  : localization.employmentHireAndPlan,
            ),
          ),
        ],
      ),
    );
  }
}
