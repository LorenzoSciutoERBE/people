import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_dialog_support.dart';

class EmployeeReviewDialog extends ConsumerStatefulWidget {
  const EmployeeReviewDialog({
    super.key,
    required this.candidate,
    this.existing,
  });

  final Candidate candidate;
  final EmployeeReview? existing;

  @override
  ConsumerState<EmployeeReviewDialog> createState() =>
      _EmployeeReviewDialogState();
}

class _EmployeeReviewDialogState extends ConsumerState<EmployeeReviewDialog> {
  late final TextEditingController _title;
  late final TextEditingController _reviewer;
  late final TextEditingController _notes;
  late final TextEditingController _goals;
  late final DateTime _initialDate;
  late final String _id;
  late DateTime _date;
  bool _saving = false;
  bool _allowClose = false;
  bool _confirming = false;
  bool _invalid = false;

  bool get _dirty =>
      _title.text != (widget.existing?.title ?? '') ||
      _reviewer.text != (widget.existing?.reviewer ?? '') ||
      _notes.text != (widget.existing?.notes ?? '') ||
      _goals.text != (widget.existing?.goals ?? '') ||
      !DateUtils.isSameDay(_date, _initialDate);

  @override
  void initState() {
    super.initState();
    final review = widget.existing;
    _id = review?.id ?? const Uuid().v4();
    _title = TextEditingController(text: review?.title ?? '');
    _reviewer = TextEditingController(text: review?.reviewer ?? '');
    _notes = TextEditingController(text: review?.notes ?? '');
    _goals = TextEditingController(text: review?.goals ?? '');
    _initialDate = DateUtils.dateOnly(
      (review?.reviewedAt ?? DateTime.now()).toLocal(),
    );
    _date = _initialDate;
    for (final controller in [_title, _reviewer, _notes, _goals]) {
      controller.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    for (final controller in [_title, _reviewer, _notes, _goals]) {
      controller.dispose();
    }
    super.dispose();
  }

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if ([
      _title,
      _reviewer,
      _notes,
    ].any((controller) => controller.text.trim().isEmpty)) {
      setState(() => _invalid = true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(candidateManagementControllerProvider.notifier)
          .saveEmployeeReview(
            widget.candidate.id,
            EmployeeReview(
              id: _id,
              reviewedAt: DateTime(
                _date.year,
                _date.month,
                _date.day,
                12,
              ).toUtc(),
              reviewer: _reviewer.text,
              title: _title.text,
              notes: _notes.text,
              goals: _goals.text,
            ),
          );
      if (!mounted) return;
      setState(() => _allowClose = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).employeeReviewSaved),
        ),
      );
      Navigator.pop(context);
    } on Exception {
      if (mounted) showCandidateActionError(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return PopScope<void>(
      canPop: _allowClose || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _close();
      },
      child: AlertDialog(
        title: Text(
          widget.existing == null
              ? localization.employeeAddReview
              : localization.employeeEditReview,
        ),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.candidate.fullName),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('employee-review-date'),
                  onPressed: _saving ? null : _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${localization.employeeReviewDate}: ${MaterialLocalizations.of(context).formatMediumDate(_date)}',
                  ),
                ),
                const SizedBox(height: 12),
                _field(
                  _title,
                  localization.employeeReviewTitle,
                  'employee-review-title',
                ),
                _field(
                  _reviewer,
                  localization.employeeReviewer,
                  'employee-review-reviewer',
                ),
                _field(
                  _notes,
                  localization.employeeReviewNotes,
                  'employee-review-notes',
                  lines: 5,
                ),
                _field(
                  _goals,
                  localization.employeeReviewGoals,
                  'employee-review-goals',
                  lines: 3,
                ),
                if (_invalid)
                  Text(
                    localization.employeeReviewRequired,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
            key: const Key('employee-review-save'),
            onPressed: _saving || !_dirty ? null : _save,
            child: Text(localization.candidateSave),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String key, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      key: Key(key),
      controller: controller,
      readOnly: _saving,
      minLines: lines,
      maxLines: lines + 4,
      decoration: InputDecoration(labelText: label, alignLabelWithHint: true),
    ),
  );
}
