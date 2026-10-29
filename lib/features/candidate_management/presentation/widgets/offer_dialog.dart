import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_dialog_support.dart';

class OfferDialog extends ConsumerStatefulWidget {
  const OfferDialog({super.key, required this.candidate});

  final Candidate candidate;

  @override
  ConsumerState<OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends ConsumerState<OfferDialog> {
  late final TextEditingController _position;
  late final TextEditingController _salary;
  late final TextEditingController _currency;
  late final TextEditingController _contractType;
  late final TextEditingController _notes;
  late OfferStatus _status;
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    final offer = widget.candidate.offer;
    _position = TextEditingController(text: offer?.position ?? '');
    _salary = TextEditingController(text: offer?.salary ?? '');
    _currency = TextEditingController(text: offer?.currency ?? 'EUR');
    _contractType = TextEditingController(text: offer?.contractType ?? '');
    _notes = TextEditingController(text: offer?.notes ?? '');
    _status = offer?.status ?? OfferStatus.draft;
    _startDate = offer?.proposedStartDate;
  }

  @override
  void dispose() {
    _position.dispose();
    _salary.dispose();
    _currency.dispose();
    _contractType.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(localization.candidateOffer),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _position,
                decoration: InputDecoration(
                  labelText: localization.candidateOfferPosition,
                ),
              ),
              TextField(
                controller: _salary,
                decoration: InputDecoration(
                  labelText: localization.candidateOfferSalary,
                ),
              ),
              TextField(
                controller: _currency,
                decoration: InputDecoration(
                  labelText: localization.candidateOfferCurrency,
                ),
              ),
              TextField(
                controller: _contractType,
                decoration: InputDecoration(
                  labelText: localization.candidateOfferContractType,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OfferStatus>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: localization.candidateOfferStatus,
                ),
                items: OfferStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(localizedOfferStatus(localization, status)),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    _startDate == null
                        ? localization.candidateOfferStartDate
                        : MaterialLocalizations.of(context)
                              .formatMediumDate(_startDate!),
                  ),
                ),
              ),
              TextField(
                controller: _notes,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: localization.candidateOfferNotes,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(localization.candidateCancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(localization.candidateOfferSave),
        ),
      ],
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _save() async {
    try {
      await ref
          .read(candidateManagementControllerProvider.notifier)
          .saveOffer(
            widget.candidate.id,
            CandidateOffer(
              status: _status,
              position: _position.text.trim(),
              salary: _salary.text.trim(),
              currency: _currency.text.trim(),
              contractType: _contractType.text.trim(),
              proposedStartDate: _startDate,
              notes: _notes.text.trim(),
            ),
          );
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) showCandidateActionError(context);
    }
  }
}
