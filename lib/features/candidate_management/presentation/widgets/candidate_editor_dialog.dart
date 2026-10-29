import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../di/candidate_management_dependencies.dart';
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
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _location;
  late final TextEditingController _headline;
  late final TextEditingController _skills;
  late final TextEditingController _experience;
  late final TextEditingController _github;
  late final TextEditingController _linkedin;
  late String _sourceId;
  List<int>? _cvBytes;
  String? _cvFileName;
  bool _ocrFound = false;
  bool _ocrRunning = false;
  String? _ocrMessage;
  bool _saving = false;
  bool _nameIsRequired = false;

  @override
  void initState() {
    super.initState();
    final candidate = widget.candidate;
    _firstName = TextEditingController(text: candidate?.firstName ?? '');
    _lastName = TextEditingController(text: candidate?.lastName ?? '');
    _email = TextEditingController(text: candidate?.email ?? '');
    _phone = TextEditingController(text: candidate?.phone ?? '');
    _location = TextEditingController(text: candidate?.location ?? '');
    _headline = TextEditingController(text: candidate?.headline ?? '');
    _skills = TextEditingController(text: candidate?.skills.join(', ') ?? '');
    _experience = TextEditingController(
      text: candidate?.yearsOfExperience?.toString() ?? '',
    );
    _github = TextEditingController(text: candidate?.githubUrl ?? '');
    _linkedin = TextEditingController(text: candidate?.linkedinUrl ?? '');
    _sourceId =
        candidate?.sourceId ??
        widget.data.sources.firstWhere((source) => source.isActive).id;
    _cvFileName = candidate?.cvFileName;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _location.dispose();
    _headline.dispose();
    _skills.dispose();
    _experience.dispose();
    _github.dispose();
    _linkedin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final candidate = widget.candidate;
    final activeSources = widget.data.sources
        .where((source) => source.isActive || source.id == _sourceId)
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
            runSpacing: 10,
            children: [
              _field(_firstName, localization.candidateFirstName, width: 350),
              _field(_lastName, localization.candidateLastName, width: 350),
              _field(_email, localization.candidateEmail, width: 350),
              _field(_phone, localization.candidatePhone, width: 350),
              _field(_location, localization.candidateLocation, width: 350),
              _field(_headline, localization.candidateHeadline, width: 350),
              _field(_skills, localization.candidateSkills, width: 350),
              _field(
                _experience,
                localization.candidateExperience,
                width: 350,
                keyboardType: TextInputType.number,
              ),
              _field(_github, localization.candidateGithubUrl, width: 350),
              _field(_linkedin, localization.candidateLinkedinUrl, width: 350),
              if (_nameIsRequired)
                SizedBox(
                  width: 720,
                  child: Text(
                    localization.candidateNameRequired,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              SizedBox(
                width: 350,
                child: DropdownButtonFormField<String>(
                  initialValue: _sourceId,
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
                    if (value != null) setState(() => _sourceId = value);
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
  }) => SizedBox(
    width: width,
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
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
    });
    try {
      final text = await ref
          .read(resumeTextExtractorProvider)
          .extractText(bytes, file.name);
      if (!mounted) return;
      final found = _applyContact(text);
      setState(() {
        _ocrFound = found;
        _ocrMessage = text.trim().isEmpty
            ? localization.candidateOcrNoText
            : localization.candidateOcrApplied;
      });
    } on PlatformException {
      if (mounted) setState(() => _ocrMessage = localization.candidateOcrError);
    } on Object {
      if (mounted) setState(() => _ocrMessage = localization.candidateOcrError);
    } finally {
      if (mounted) setState(() => _ocrRunning = false);
    }
  }

  /// Fills only the name and email from the CV; the rest is discarded.
  bool _applyContact(String text) {
    final contact = const ParseResumeContact()(text);
    if (_firstName.text.isEmpty) _firstName.text = contact.firstName;
    if (_lastName.text.isEmpty) _lastName.text = contact.lastName;
    if (_email.text.isEmpty) _email.text = contact.email;
    return contact.firstName.isNotEmpty ||
        contact.lastName.isNotEmpty ||
        contact.email.isNotEmpty;
  }

  Future<void> _save() async {
    if (_firstName.text.trim().isEmpty) {
      setState(() => _nameIsRequired = true);
      return;
    }
    setState(() => _nameIsRequired = false);
    setState(() => _saving = true);
    final now = DateTime.now().toUtc();
    final old = widget.candidate;
    final candidate = Candidate(
      id: old?.id ?? const Uuid().v4(),
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      location: _location.text.trim(),
      headline: _headline.text.trim(),
      skills: _skills.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toSet()
          .toList(growable: false),
      yearsOfExperience: int.tryParse(_experience.text.trim()),
      githubUrl: _github.text.trim(),
      linkedinUrl: _linkedin.text.trim(),
      stageId: old?.stageId ?? '',
      sourceId: _sourceId,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
      cvFileName: _cvFileName ?? old?.cvFileName,
      cvStorageKey: old?.cvStorageKey,
      cvExtractedText: '',
      interviews: old?.interviews ?? const <InterviewRecord>[],
      ratings: old?.ratings ?? const <RatingAspect, double>{},
      offer: old?.offer,
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
