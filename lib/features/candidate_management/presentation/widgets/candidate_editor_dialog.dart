import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../../domain/failures/candidate_repository_exception.dart';
import '../../domain/usecases/parse_resume_contact.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_dialog_support.dart';

class CandidateEditorDialog extends ConsumerStatefulWidget {
  const CandidateEditorDialog({super.key, required this.data, this.candidate});

  final RecruitingData data;
  final Candidate? candidate;

  @override
  ConsumerState<CandidateEditorDialog> createState() =>
      _CandidateEditorDialogState();
}

class _CandidateEditorDialogState extends ConsumerState<CandidateEditorDialog> {
  late final CandidateProfileControllers _form;
  List<int>? _cvBytes;
  String? _cvFileName;
  bool _ocrFound = false;
  bool _ocrRunning = false;
  String? _ocrMessage;
  String _extractedText = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final candidate = widget.candidate;
    _form = CandidateProfileControllers(
      candidate: candidate,
      defaultSourceId: widget.data.sources
          .firstWhere((source) => source.isActive)
          .id,
    );
    _cvFileName = candidate?.cvFileName;
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final candidate = widget.candidate;
    final activeSources = widget.data.sources
        .where((source) => source.isActive || source.id == _form.sourceId)
        .toList(growable: false);
    final sourceNames = <String, String>{
      for (final source in activeSources)
        source.id: localizedSourceName(localization, source),
    };
    return AlertDialog(
      title: Text(
        candidate == null
            ? localization.candidateAdd
            : localization.candidateEdit,
      ),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _field(
                _form.firstName,
                localization.candidateFirstName,
                width: 350,
                errorText: _form.firstNameError,
                onChanged: (_) {
                  if (_form.firstNameError != null) {
                    setState(() => _form.firstNameError = null);
                  }
                },
              ),
              _field(
                _form.lastName,
                localization.candidateLastName,
                width: 350,
              ),
              _field(_form.email, localization.candidateEmail, width: 350),
              _field(_form.phone, localization.candidatePhone, width: 350),
              _field(
                _form.location,
                localization.candidateLocation,
                width: 350,
              ),
              _field(
                _form.headline,
                localization.candidateHeadline,
                width: 350,
              ),
              _field(_form.skills, localization.candidateSkills, width: 350),
              _field(
                _form.experience,
                localization.candidateExperience,
                width: 350,
                keyboardType: TextInputType.number,
                errorText: _form.experienceError,
                onChanged: (_) {
                  if (_form.experienceError != null) {
                    setState(() => _form.experienceError = null);
                  }
                },
              ),
              _field(_form.github, localization.candidateGithubUrl, width: 350),
              _field(
                _form.linkedin,
                localization.candidateLinkedinUrl,
                width: 350,
              ),
              SizedBox(
                width: 350,
                child: DropdownButtonFormField<String>(
                  initialValue: _form.sourceId,
                  decoration: InputDecoration(
                    labelText: localization.candidateSource,
                  ),
                  items: sourceNames.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) setState(() => _form.sourceId = value);
                  },
                ),
              ),
              SizedBox(
                width: 350,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: localization.candidateStage,
                  ),
                  child: Text(
                    localizedStageName(
                      localization,
                      widget.data.stages.firstWhere(
                        (stage) => stage.id == (candidate?.stageId ?? 'new'),
                        orElse: () => widget.data.stages.first,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 720,
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _ocrRunning ? null : _pickResume,
                      icon: const Icon(Icons.upload_file_outlined),
                      label: Text(
                        candidate?.hasResume == true || _cvBytes != null
                            ? localization.candidateReplaceResume
                            : localization.candidateImportResume,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _cvFileName ?? localization.candidateResumeEncrypted,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_ocrRunning)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              if (_ocrMessage != null)
                SizedBox(
                  width: 720,
                  child: Text(
                    _ocrMessage!,
                    style: TextStyle(
                      color: !_ocrFound
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              if (_extractedText.isNotEmpty)
                SizedBox(
                  width: 720,
                  child: ExpansionTile(
                    key: const Key('resume-extracted-text'),
                    title: Text(localization.candidateOcrTextPreview),
                    children: [
                      SizedBox(
                        height: 220,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(_extractedText),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(localization.candidateCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(localization.candidateSave),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required double width,
    TextInputType? keyboardType,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) => SizedBox(
    width: width,
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label, errorText: errorText),
    ),
  );

  Future<void> _pickResume() async {
    if (_ocrRunning) return;
    final localization = AppLocalizations.of(context);
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const <String>['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (file == null || !mounted) return;
    final fileSize = await file.length();
    if (fileSize == null || fileSize > maximumResumeBytes) {
      setState(() => _ocrMessage = localization.candidateResumeUnsupported);
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _cvBytes = bytes;
      _cvFileName = file.name;
      _ocrRunning = true;
      _ocrMessage = localization.candidateOcrRunning;
      _extractedText = '';
    });
    try {
      final text = await ref
          .read(resumeTextExtractorProvider)
          .extractText(bytes, file.name);
      if (!mounted) return;
      final found = _applyContact(text);
      setState(() {
        _ocrFound = found;
        _extractedText = text.trim();
        _ocrMessage = text.trim().isEmpty
            ? localization.candidateOcrNoText
            : found
            ? localization.candidateOcrApplied
            : localization.candidateOcrNoContacts;
      });
    } on Exception {
      if (mounted) {
        setState(() {
          _ocrFound = false;
          _ocrMessage = localization.candidateOcrError;
        });
      }
    } finally {
      if (mounted) setState(() => _ocrRunning = false);
    }
  }

  /// Fills empty contact fields only; extracted text is not persisted.
  bool _applyContact(String text) {
    final contact = const ParseResumeContact()(text);
    if (_form.firstName.text.isEmpty) _form.firstName.text = contact.firstName;
    if (_form.lastName.text.isEmpty) _form.lastName.text = contact.lastName;
    if (_form.email.text.isEmpty) _form.email.text = contact.email;
    return contact.firstName.isNotEmpty ||
        contact.lastName.isNotEmpty ||
        contact.email.isNotEmpty;
  }

  Future<void> _save() async {
    final localization = AppLocalizations.of(context);
    var isValid = false;
    setState(() => isValid = _form.validate(localization));
    if (!isValid) return;
    setState(() => _saving = true);
    final candidate = _form.toCandidate(
      existing: widget.candidate,
      cvFileName: _cvFileName,
    );
    try {
      await ref
          .read(candidateManagementControllerProvider.notifier)
          .saveCandidate(candidate, cvBytes: _cvBytes);
      if (mounted) Navigator.pop(context);
    } on Object {
      if (mounted) {
        setState(() => _saving = false);
        showCandidateActionError(context);
      }
    }
  }
}
