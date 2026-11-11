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
import 'candidate_communication_toggle.dart';
import 'pipeline_status.dart';
import 'interview_feedback_form.dart';
import 'offer_dialog.dart';
import 'star_rating.dart';
import 'employment_plan_dialog.dart';

/// Near-full-screen candidate record focused on the hiring process, with an
/// on-demand personal details editor.
class CandidateDetailsPage extends ConsumerStatefulWidget {
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
  ConsumerState<CandidateDetailsPage> createState() =>
      _CandidateDetailsPageState();
}

class _CandidateDetailsPageState extends ConsumerState<CandidateDetailsPage> {
  bool _showPersonalDetails = false;
  final _profileKey = GlobalKey<_InlineProfileState>();

  Future<void> _togglePersonalDetails() async {
    final profile = _profileKey.currentState;
    if (_showPersonalDetails &&
        profile != null &&
        !(await profile.confirmLeave())) {
      return;
    }
    if (mounted) {
      setState(() => _showPersonalDetails = !_showPersonalDetails);
    }
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
    return Dialog(
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
              showPersonalDetails: _showPersonalDetails,
              onTogglePersonalDetails: _togglePersonalDetails,
              onClose: () => Navigator.of(context).maybePop(),
            ),
            const Divider(height: 1),
            Expanded(
              child: data == null || candidate == null
                  ? const Center(child: CircularProgressIndicator())
                  : _CandidateContent(
                      profileKey: _profileKey,
                      data: data,
                      candidate: candidate,
                      startWithFeedback: widget.startWithFeedback,
                      showPersonalDetails: _showPersonalDetails,
                    ),
            ),
          ],
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
    required this.showPersonalDetails,
    required this.onTogglePersonalDetails,
    required this.onClose,
  });

  final RecruitingData? data;
  final Candidate? candidate;
  final HiringStage? stage;
  final bool showPersonalDetails;
  final VoidCallback onTogglePersonalDetails;
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
    } on Object {
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
                  if (showPersonalDetails)
                    FilledButton.tonalIcon(
                      key: const Key('toggle-candidate-profile'),
                      onPressed: onTogglePersonalDetails,
                      icon: const Icon(Icons.badge, size: 18),
                      label: Text(localization.candidatePersonalDetails),
                    )
                  else
                    OutlinedButton.icon(
                      key: const Key('toggle-candidate-profile'),
                      onPressed: onTogglePersonalDetails,
                      icon: const Icon(Icons.badge_outlined, size: 18),
                      label: Text(localization.candidatePersonalDetails),
                    ),
                  const SizedBox(width: 4),
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
    required this.data,
    required this.candidate,
    required this.startWithFeedback,
    required this.showPersonalDetails,
  });

  final RecruitingData data;
  final GlobalKey<_InlineProfileState> profileKey;
  final Candidate candidate;
  final bool startWithFeedback;
  final bool showPersonalDetails;

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
          if (!showPersonalDetails) {
            return _RightPanel(
              data: data,
              candidate: candidate,
              stage: stage,
              stages: data.stages,
              startWithFeedback: startWithFeedback,
              feedbackEnabled: data.requiresFeedback(stage.id),
            );
          }
          if (constraints.maxWidth < 850) {
            return ListView(
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
                    data: data,
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
                  data: data,
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
    required this.data,
    required this.candidate,
    required this.stage,
    required this.stages,
    required this.startWithFeedback,
    required this.feedbackEnabled,
  });

  final RecruitingData data;
  final Candidate candidate;
  final HiringStage stage;
  final List<HiringStage> stages;
  final bool startWithFeedback;
  final bool feedbackEnabled;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final timeline = _PipelineOverviewCard(
        data: data,
        candidate: candidate,
        stage: stage,
      );
      final activity = _InterviewHistory(
        candidate: candidate,
        stage: stage,
        stages: stages,
        startWithFeedback: startWithFeedback,
        feedbackEnabled: feedbackEnabled,
      );
      if (constraints.maxWidth < 850) {
        return ListView(
          children: [
            activity,
            const SizedBox(height: 24),
            timeline,
            const SizedBox(height: 20),
            _RatingsCard(candidate: candidate),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 270,
            child: ListView(
              children: [
                timeline,
                const SizedBox(height: 20),
                _RatingsCard(candidate: candidate),
              ],
            ),
          ),
          const SizedBox(width: 28),
          Expanded(child: ListView(children: [activity])),
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
  });
  final RecruitingData data;
  final Candidate candidate;
  final HiringStage stage;

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
          IntrinsicHeight(
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
                              : index < currentIndex ||
                                    stage.terminalOutcome ==
                                        TerminalOutcome.hired
                              ? const Color(0xFFE4EFE8)
                              : theme.colorScheme.surfaceContainerHighest,
                        ),
                        child:
                            index < currentIndex ||
                                stage.terminalOutcome == TerminalOutcome.hired
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
                      if (index < steps.length - 1)
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
                    padding: const EdgeInsets.only(top: 5, bottom: 22),
                    child: Text(
                      localizedStageName(localization, steps[index]),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: index == currentIndex
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: index == currentIndex
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
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
    if (!ref.watch(evaluationsVisibleProvider)) return const SizedBox.shrink();
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
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                spacing: 32,
                runSpacing: 4,
                children: [
                  for (final aspect in RatingAspect.values)
                    SizedBox(
                      width: constraints.maxWidth < 340
                          ? constraints.maxWidth
                          : 340,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(localizedRatingAspect(localization, aspect)),
                          StarRating(
                            value: candidate.ratings[aspect],
                            size: 22,
                            onChanged: (value) =>
                                _update(context, ref, aspect, value),
                          ),
                        ],
                      ),
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
  bool _allowClose = false;
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

  Future<void> _requestClose() async {
    if (!await confirmLeave() || !mounted) return;
    setState(() => _allowClose = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
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
        ..sort((first, second) => first.createdAt.compareTo(second.createdAt));

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
    final theme = Theme.of(context);
    final data = RecruitingData(
      candidates: [widget.candidate],
      sources: const [],
      stages: widget.stages,
    );
    final destinations = data.availableDestinationsFor(
      widget.candidate,
      widget.stage,
    );
    final current = widget.candidate.latestFeedbackFor(widget.stage.id);
    final history = _history
        .where((record) => record.stageId != widget.stage.id)
        .toList()
        .reversed
        .toList();
    final active = widget.stage.terminalOutcome == TerminalOutcome.active;
    final actionLabel = widget.stage.id == 'new'
        ? localization.pipelineReviewCv
        : current?.scheduledAt == null
        ? localization.pipelineSchedule
        : current?.decision == FeedbackDecision.pending
        ? localization.pipelineAwaitingFeedback
        : localization.pipelineEditFeedback;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: ValueKey('feedback-step-${widget.stage.id}'),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                active
                    ? localization.pipelineCurrentStep
                    : localization.pipelineOutcome,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                localizedStageName(localization, widget.stage),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (active) ...[
                const SizedBox(height: 10),
                Text(
                  widget.stage.id == 'new'
                      ? localization.pipelineCvDescription
                      : widget.stage.isOfferStage
                      ? localization.pipelineOfferDescription
                      : localization.pipelineInterviewDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                PipelineStatus(candidate: widget.candidate),
              ],
              if (current != null) ...[
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                if (current.scheduledAt case final appointment?) ...[
                  Text(
                    '${MaterialLocalizations.of(context).formatMediumDate(appointment.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(appointment.toLocal()))}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(current.interviewer, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 12),
                ],
                if (current.notes.isNotEmpty)
                  Text(
                    current.notes,
                    maxLines: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (widget.stage.isInterview &&
                    current.decision != FeedbackDecision.pending) ...[
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, _) => Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (ref.watch(evaluationsVisibleProvider))
                          FeedbackBadge(decision: current.decision),
                        CandidateCommunicationToggle(
                          candidateId: widget.candidate.id,
                          record: current,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              if (active) ...[
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, _) => Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      if (widget.feedbackEnabled)
                        FilledButton.tonalIcon(
                          key: const Key('selection-edit-step'),
                          onPressed: () => _open(widget.stage),
                          icon: Icon(
                            widget.stage.id == 'new'
                                ? Icons.description_outlined
                                : Icons.edit_calendar_outlined,
                            size: 18,
                          ),
                          label: Text(actionLabel),
                        ),
                      if (widget.stage.isOfferStage)
                        OutlinedButton.icon(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) =>
                                OfferDialog(candidate: widget.candidate),
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
                            destination.terminalOutcome ==
                                    TerminalOutcome.rejected
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
                ),
              ],
            ],
          ),
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 24),
          ExpansionTile(
            key: const Key('selection-history'),
            tilePadding: EdgeInsets.zero,
            initiallyExpanded: false,
            title: Text(
              localization.pipelineCompletedSteps,
              style: theme.textTheme.titleMedium,
            ),
            children: [
              for (final record in history)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: _InterviewCard(
                      candidateId: widget.candidate.id,
                      record: record,
                      stage: _stageFor(record.stageId),
                      onTap: () => _open(_stageFor(record.stageId)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A saved step's notes, appointment, and feedback in the compact history.
class _InterviewCard extends ConsumerWidget {
  const _InterviewCard({
    required this.candidateId,
    required this.record,
    required this.stage,
    required this.onTap,
  });

  final String candidateId;
  final InterviewRecord? record;
  final HiringStage stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final evaluationsVisible = ref.watch(evaluationsVisibleProvider);
    final record = this.record;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('feedback-step-${stage.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _content(
            context,
            ref,
            localization,
            theme,
            record,
            evaluationsVisible,
          ),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations localization,
    ThemeData theme,
    InterviewRecord? record,
    bool evaluationsVisible,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              localizedStageName(localization, stage),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(
            Icons.edit_outlined,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      if (record != null) ...[
        const SizedBox(height: 6),
        Text(
          record.scheduledAt == null
              ? MaterialLocalizations.of(context)
                    .formatMediumDate(record.createdAt.toLocal())
              : '${MaterialLocalizations.of(context).formatMediumDate(record.scheduledAt!.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(record.scheduledAt!.toLocal()))} · ${record.interviewer}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (record.notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(record.notes, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
        if (stage.isInterview) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (evaluationsVisible) FeedbackBadge(decision: record.decision),
              if (record.decision != FeedbackDecision.pending)
                CandidateCommunicationToggle(
                  candidateId: candidateId,
                  record: record,
                ),
            ],
          ),
        ],
      ],
    ],
  );
}
