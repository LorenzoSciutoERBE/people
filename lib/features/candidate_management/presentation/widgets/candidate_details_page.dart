import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_dialog_support.dart';
import 'candidate_status_widgets.dart';
import 'interview_feedback_form.dart';
import 'offer_dialog.dart';
import 'star_rating.dart';

/// Near-full-screen candidate record with inline-editable profile data.
class CandidateDetailsPage extends ConsumerWidget {
  const CandidateDetailsPage({
    super.key,
    required this.candidateId,
    this.startWithFeedback = false,
  });

  final String candidateId;
  final bool startWithFeedback;

  static Future<void> open(
    BuildContext context,
    String candidateId, {
    bool startWithFeedback = false,
  }) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CandidateDetailsPage(
      candidateId: candidateId,
      startWithFeedback: startWithFeedback,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(candidateManagementControllerProvider).asData?.value;
    final candidate = data?.candidates
        .where((value) => value.id == candidateId)
        .firstOrNull;
    final stage = data?.stages
        .where((value) => value.id == candidate?.stageId)
        .firstOrNull;
    final screen = MediaQuery.sizeOf(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: screen.width * 0.96,
        height: screen.height * 0.94,
        child: Column(
          children: [
            _DialogHeader(
              candidate: candidate,
              stage: stage,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            const Divider(height: 1),
            Expanded(
              child: data == null || candidate == null
                  ? const Center(child: CircularProgressIndicator())
                  : _CandidateContent(
                      data: data,
                      candidate: candidate,
                      startWithFeedback: startWithFeedback,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.candidate,
    required this.stage,
    required this.onClose,
  });

  final Candidate? candidate;
  final HiringStage? stage;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final candidate = this.candidate;
    final stage = this.stage;
    final average = candidate?.averageRating;
    return Material(
      color: Colors.white,
      child: SizedBox(
        height: 88,
        child: Row(
          children: [
            const SizedBox(width: 24),
            if (candidate != null) ...[
              CandidateAvatar(name: candidate.fullName, radius: 26),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate?.fullName ?? '',
                    style: theme.textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (candidate != null && candidate.headline.isNotEmpty)
                    Text(
                      candidate.headline,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (stage != null)
              Chip(
                label: Text(localizedStageName(localization, stage)),
                visualDensity: VisualDensity.compact,
              ),
            if (average != null) ...[
              const SizedBox(width: 16),
              AverageRatingBadge(rating: average),
            ],
            const SizedBox(width: 8),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _CandidateContent extends StatelessWidget {
  const _CandidateContent({
    required this.data,
    required this.candidate,
    required this.startWithFeedback,
  });

  final RecruitingData data;
  final Candidate candidate;
  final bool startWithFeedback;

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
            return ListView(
              children: [
                SizedBox(
                  height: 640,
                  child: _InlineProfile(
                    data: data,
                    candidate: candidate,
                    stage: stage,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 800,
                  child: _RightPanel(
                    candidate: candidate,
                    stage: stage,
                    stages: data.stages,
                    startWithFeedback: startWithFeedback,
                    feedbackEnabled: data.requiresFeedback(stage.id),
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 480,
                child: _InlineProfile(
                  data: data,
                  candidate: candidate,
                  stage: stage,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _RightPanel(
                  candidate: candidate,
                  stage: stage,
                  stages: data.stages,
                  startWithFeedback: startWithFeedback,
                  feedbackEnabled: data.requiresFeedback(stage.id),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({
    required this.candidate,
    required this.stage,
    required this.stages,
    required this.startWithFeedback,
    required this.feedbackEnabled,
  });

  final Candidate candidate;
  final HiringStage stage;
  final List<HiringStage> stages;
  final bool startWithFeedback;
  final bool feedbackEnabled;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      _RatingsCard(candidate: candidate),
      const SizedBox(height: 24),
      _InterviewHistory(
        candidate: candidate,
        stage: stage,
        stages: stages,
        startWithFeedback: startWithFeedback,
        feedbackEnabled: feedbackEnabled,
      ),
    ],
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
    } on Object {
      if (context.mounted) showCandidateActionError(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localization.candidateRatings,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 32,
              runSpacing: 4,
              children: [
                for (final aspect in RatingAspect.values)
                  SizedBox(
                    width: 340,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            localizedRatingAspect(localization, aspect),
                          ),
                        ),
                        StarRating(
                          value: candidate.ratings[aspect],
                          size: 26,
                          onChanged: (value) =>
                              _update(context, ref, aspect, value),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineProfile extends ConsumerStatefulWidget {
  const _InlineProfile({
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
  bool _saving = false;
  String? _firstNameError;
  String? _experienceError;
  final _firstNameKey = GlobalKey();
  final _experienceKey = GlobalKey();
  late List<String> _savedValues;
  bool _allowClose = false;
  bool _confirmingClose = false;

  List<TextEditingController> get _controllers => [
    _firstName,
    _lastName,
    _email,
    _phone,
    _location,
    _headline,
    _skills,
    _experience,
    _github,
    _linkedin,
  ];

  List<String> get _values => [
    for (final controller in _controllers) controller.text,
    _sourceId,
  ];

  bool get _dirty {
    final values = _values;
    for (var index = 0; index < values.length; index++) {
      if (values[index] != _savedValues[index]) return true;
    }
    return false;
  }

  void _onProfileChanged() => setState(() {});

  Future<void> _requestClose() async {
    if (_saving || _confirmingClose) return;
    if (_dirty) {
      _confirmingClose = true;
      final discard = await confirmDiscardChanges(context);
      _confirmingClose = false;
      if (!discard || !mounted) return;
    }
    setState(() => _allowClose = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    final candidate = widget.candidate;
    _firstName = TextEditingController(text: candidate.firstName);
    _lastName = TextEditingController(text: candidate.lastName);
    _email = TextEditingController(text: candidate.email);
    _phone = TextEditingController(text: candidate.phone);
    _location = TextEditingController(text: candidate.location);
    _headline = TextEditingController(text: candidate.headline);
    _skills = TextEditingController(text: candidate.skills.join(', '));
    _experience = TextEditingController(
      text: candidate.yearsOfExperience?.toString() ?? '',
    );
    _github = TextEditingController(text: candidate.githubUrl);
    _linkedin = TextEditingController(text: candidate.linkedinUrl);
    _sourceId = candidate.sourceId;
    _savedValues = _values;
    for (final controller in _controllers) {
      controller.addListener(_onProfileChanged);
    }
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
    final sources = {
      for (final source in widget.data.sources)
        source.id: localizedSourceName(localization, source),
    };
    return PopScope<void>(
      canPop: _allowClose || (!_dirty && !_saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestClose();
      },
      child: Card(
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
                      _field(_firstName, localization.candidateFirstName),
                      _field(_lastName, localization.candidateLastName),
                      _field(_email, localization.candidateEmail),
                      _field(_phone, localization.candidatePhone),
                      _field(_location, localization.candidateLocation),
                      _field(_headline, localization.candidateHeadline),
                      _field(
                        _skills,
                        localization.candidateSkills,
                        maxLines: 2,
                      ),
                      _field(
                        _experience,
                        localization.candidateExperience,
                        keyboardType: TextInputType.number,
                      ),
                      _sourceField(sources, localization),
                      _field(_github, localization.candidateGithubUrl),
                      _field(_linkedin, localization.candidateLinkedinUrl),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
    ],
  );

  Widget _sourceField(
    Map<String, String> sources,
    AppLocalizations localization,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: _sourceId,
      isExpanded: true,
      decoration: InputDecoration(labelText: localization.candidateSource),
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
              if (value != null) setState(() => _sourceId = value);
            },
    ),
  );

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) => Padding(
    key: controller == _firstName
        ? _firstNameKey
        : controller == _experience
        ? _experienceKey
        : null,
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      readOnly: _saving,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) {
        if (controller == _firstName && _firstNameError != null) {
          setState(() => _firstNameError = null);
        }
        if (controller == _experience && _experienceError != null) {
          setState(() => _experienceError = null);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        errorText: controller == _firstName
            ? _firstNameError
            : controller == _experience
            ? _experienceError
            : null,
      ),
    ),
  );

  Future<void> _save() async {
    final localization = AppLocalizations.of(context);
    final experienceText = _experience.text.trim();
    final experience = int.tryParse(experienceText);
    setState(() {
      _firstNameError = _firstName.text.trim().isEmpty
          ? localization.candidateNameRequired
          : null;
      _experienceError =
          experienceText.isNotEmpty && (experience == null || experience < 0)
          ? localization.candidateExperienceInvalid
          : null;
    });
    if (_firstNameError != null || _experienceError != null) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final fieldContext =
          (_firstNameError != null ? _firstNameKey : _experienceKey)
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
          .saveCandidate(
            widget.candidate.copyWith(
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
                  .toList(growable: false),
              yearsOfExperience: experience,
              clearYearsOfExperience: experienceText.isEmpty,
              githubUrl: _github.text.trim(),
              linkedinUrl: _linkedin.text.trim(),
              sourceId: _sourceId,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
      if (mounted) {
        setState(() => _savedValues = _values);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localization.candidateProfileSaved)),
        );
      }
    } on Object {
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
          title: Text(localization.candidateResume),
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
    } on Object {
      if (context.mounted) showCandidateActionError(context);
    }
  }
}

class _InterviewHistory extends StatefulWidget {
  const _InterviewHistory({
    required this.candidate,
    required this.stage,
    required this.stages,
    required this.startWithFeedback,
    required this.feedbackEnabled,
  });

  final Candidate candidate;
  final HiringStage stage;
  final List<HiringStage> stages;
  final bool startWithFeedback;
  final bool feedbackEnabled;

  @override
  State<_InterviewHistory> createState() => _InterviewHistoryState();
}

class _InterviewHistoryState extends State<_InterviewHistory> {
  @override
  void initState() {
    super.initState();
    if (widget.startWithFeedback && widget.feedbackEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _open(widget.stage);
      });
    }
  }

  List<InterviewRecord> get _history =>
      [...widget.candidate.interviews]
        ..sort((first, second) => second.createdAt.compareTo(first.createdAt));

  HiringStage _stageFor(String stageId) =>
      widget.stages.where((item) => item.id == stageId).firstOrNull ??
      widget.stage;

  Future<void> _open(HiringStage stage) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => InterviewFeedbackDialog(
        candidate: widget.candidate,
        stage: stage,
        existing: widget.candidate.latestFeedbackFor(stage.id),
      ),
    );
    if (saved != true || !mounted) return;
    final localization = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localization.candidateFeedbackSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final history = _history;
    final awaitingCurrent =
        widget.feedbackEnabled &&
        widget.candidate.latestFeedbackFor(widget.stage.id) == null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                localization.candidateFeedbackHistory,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (widget.feedbackEnabled)
              FilledButton.icon(
                onPressed: () => _open(widget.stage),
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(localization.candidateFeedback),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (history.isEmpty && !awaitingCurrent)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(localization.candidateFeedbackNone)),
          ),
        if (awaitingCurrent)
          _InterviewCard(
            record: null,
            stage: widget.stage,
            onTap: () => _open(widget.stage),
          ),
        for (final record in history) ...[
          if (awaitingCurrent || record != history.first)
            const SizedBox(height: 12),
          _InterviewCard(
            record: record,
            stage: _stageFor(record.stageId),
            onTap: () => _open(_stageFor(record.stageId)),
          ),
        ],
      ],
    );
  }
}

/// One stage's feedback in the history list; [record] is null while the
/// current stage is still waiting for its feedback.
class _InterviewCard extends StatelessWidget {
  const _InterviewCard({
    required this.record,
    required this.stage,
    required this.onTap,
  });

  final InterviewRecord? record;
  final HiringStage stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final record = this.record;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _content(context, localization, theme, record)),
              const SizedBox(width: 12),
              Icon(
                Icons.edit_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations localization,
    ThemeData theme,
    InterviewRecord? record,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        localizedStageName(localization, stage),
        style: theme.textTheme.titleMedium,
      ),
      const SizedBox(height: 8),
      if (record == null)
        Text(
          localization.candidateFeedbackRequired,
          style: theme.textTheme.bodySmall,
        )
      else ...[
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FeedbackBadge(decision: record.decision),
            Text(
              MaterialLocalizations.of(context)
                  .formatMediumDate(record.createdAt.toLocal()),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        if (record.notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            record.notes,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ],
    ],
  );
}
