import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../../domain/failures/candidate_repository_exception.dart';

Future<bool> confirmDiscardChanges(BuildContext context) async {
  final localization = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(localization.unsavedChangesTitle),
          content: Text(localization.unsavedChangesMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localization.keepEditing),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(localization.discardChanges),
            ),
          ],
        ),
      ) ??
      false;
}

class CandidateErrorPanel extends StatelessWidget {
  const CandidateErrorPanel({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: onRetry,
          child: Text(AppLocalizations.of(context).scoutingRetry),
        ),
      ],
    ),
  );
}

Future<void> performCandidateAction(
  BuildContext context,
  AppLocalizations localization,
  Future<void> Function() action,
) async {
  try {
    await action();
  } on CandidateRepositoryException catch (error) {
    if (!context.mounted) return;
    final message = candidateRepositoryErrorMessage(localization, error);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  } on Object {
    if (context.mounted) showCandidateActionError(context);
  }
}

String candidateRepositoryErrorMessage(
  AppLocalizations localization,
  CandidateRepositoryException error,
) => switch (error.code) {
  'interview_schedule_required' => localization.pipelineScheduleRequired,
  'cv_review_required' => localization.pipelineCvRequired,
  'candidate_feedback_required' => localization.pipelineCommunicationRequired,
  'positive_feedback_required' => localization.candidateMoveForwardBlocked,
  'negative_feedback_required' => localization.candidateRejectBlocked,
  'accepted_offer_required' => localization.candidateAcceptedOfferRequired,
  'offer_stage_required' => localization.candidateOfferStageRequired,
  'invalid_stage_transition' => localization.candidateTransitionBlocked,
  'employee_review_invalid' => localization.employeeReviewRequired,
  'employment_plan_invalid' => localization.employmentPlanInvalid,
  _ => localization.candidateActionFailed,
};

void showCandidateActionError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(AppLocalizations.of(context).candidateActionFailed)),
  );
}

String localizedDecision(
  AppLocalizations localization,
  FeedbackDecision value,
) => switch (value) {
  FeedbackDecision.positive => localization.candidateFeedbackPositive,
  FeedbackDecision.negative => localization.candidateFeedbackNegative,
  FeedbackDecision.pending => localization.candidateFeedbackMissing,
};

String localizedRatingAspect(
  AppLocalizations localization,
  RatingAspect value,
) => switch (value) {
  RatingAspect.technicalSkills => localization.ratingTechnicalSkills,
  RatingAspect.problemSolving => localization.ratingProblemSolving,
  RatingAspect.communication => localization.ratingCommunication,
  RatingAspect.teamFit => localization.ratingTeamFit,
  RatingAspect.motivation => localization.ratingMotivation,
};

String localizedOfferStatus(AppLocalizations localization, OfferStatus value) =>
    switch (value) {
      OfferStatus.draft => localization.candidateOfferDraft,
      OfferStatus.sent => localization.candidateOfferSent,
      OfferStatus.accepted => localization.candidateOfferAccepted,
      OfferStatus.declined => localization.candidateOfferDeclined,
    };

String localizedSourceName(
  AppLocalizations localization,
  CandidateSource source,
) => source.name == defaultSourceName(source.id)
    ? localizedSourceDefault(localization, source.id)
    : source.name;

String localizedStageName(AppLocalizations localization, HiringStage stage) =>
    stage.name == defaultStageName(stage.id)
    ? localizedStageDefault(localization, stage.id)
    : stage.name;

String storedSourceName(
  String id,
  String editedName,
  AppLocalizations localization,
) => editedName == localizedSourceDefault(localization, id)
    ? defaultSourceName(id) ?? editedName
    : editedName;

String storedStageName(
  String id,
  String editedName,
  AppLocalizations localization,
) => editedName == localizedStageDefault(localization, id)
    ? defaultStageName(id) ?? editedName
    : editedName;

String localizedSourceDefault(AppLocalizations localization, String id) =>
    switch (id) {
      'grafton' => localization.candidateDefaultGrafton,
      'poli' => localization.candidateDefaultPoli,
      'github' => localization.candidateDefaultGithub,
      'other' => localization.candidateDefaultOther,
      _ => '',
    };

String localizedStageDefault(AppLocalizations localization, String id) =>
    switch (id) {
      'new' => localization.candidateDefaultNew,
      'screening' => localization.candidateDefaultScreening,
      'technical' => localization.candidateDefaultTechnical,
      'final' => localization.candidateDefaultFinal,
      'offer' => localization.candidateDefaultOffer,
      'hired' => localization.candidateDefaultHired,
      'rejected' => localization.candidateDefaultRejected,
      _ => '',
    };

String? defaultSourceName(String id) => switch (id) {
  'grafton' => 'Grafton',
  'poli' => 'Poli',
  'github' => 'GitHub',
  'other' => 'Other',
  _ => null,
};

String? defaultStageName(String id) => switch (id) {
  'new' => 'CV review',
  'screening' => 'Introductory interview',
  'technical' => 'Technical interview',
  'final' => 'Germany interview',
  'offer' => 'Offer',
  'hired' => 'Hired',
  'rejected' => 'Rejected',
  _ => null,
};

Candidate? createCandidateFromGithubProfile({
  required RecruitingData data,
  required String username,
  required String profileUrl,
  String? displayName,
  String? location,
  String? biography,
  List<String> languages = const [],
}) {
  final activeSources = data.sources
      .where((source) => source.isActive)
      .toList(growable: false);
  if (activeSources.isEmpty || data.stages.isEmpty) return null;
  final source =
      activeSources.where((item) => item.id == 'github').firstOrNull ??
      activeSources.first;
  final stage =
      data.stages.where((item) => item.id == 'new').firstOrNull ??
      data.activeStages.firstOrNull ??
      data.stages.first;
  final trimmedName = displayName?.trim() ?? '';
  final nameParts = (trimmedName.isEmpty ? username : trimmedName).split(
    RegExp(r'\s+'),
  );
  final now = DateTime.now().toUtc();
  return Candidate(
    id: const Uuid().v4(),
    firstName: nameParts.first,
    lastName: nameParts.length > 1 ? nameParts.skip(1).join(' ') : '',
    location: location ?? '',
    headline: biography ?? '',
    skills: languages,
    githubUrl: profileUrl,
    sourceId: source.id,
    stageId: stage.id,
    createdAt: now,
    updatedAt: now,
  );
}

/// Shared form controller bundle for creating and editing candidate profiles.
class CandidateProfileControllers {
  CandidateProfileControllers({
    Candidate? candidate,
    required String defaultSourceId,
  }) : firstName = TextEditingController(text: candidate?.firstName ?? ''),
       lastName = TextEditingController(text: candidate?.lastName ?? ''),
       email = TextEditingController(text: candidate?.email ?? ''),
       phone = TextEditingController(text: candidate?.phone ?? ''),
       location = TextEditingController(text: candidate?.location ?? ''),
       headline = TextEditingController(text: candidate?.headline ?? ''),
       skills = TextEditingController(text: candidate?.skills.join(', ') ?? ''),
       experience = TextEditingController(
         text: candidate?.yearsOfExperience?.toString() ?? '',
       ),
       github = TextEditingController(text: candidate?.githubUrl ?? ''),
       linkedin = TextEditingController(text: candidate?.linkedinUrl ?? ''),
       sourceId = candidate?.sourceId ?? defaultSourceId;

  final TextEditingController firstName;
  final TextEditingController lastName;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController location;
  final TextEditingController headline;
  final TextEditingController skills;
  final TextEditingController experience;
  final TextEditingController github;
  final TextEditingController linkedin;
  String sourceId;
  String? firstNameError;
  String? experienceError;

  List<TextEditingController> get all => [
    firstName,
    lastName,
    email,
    phone,
    location,
    headline,
    skills,
    experience,
    github,
    linkedin,
  ];

  List<String> get snapshot => [
    for (final controller in all) controller.text,
    sourceId,
  ];

  void addListener(VoidCallback listener) {
    for (final controller in all) {
      controller.addListener(listener);
    }
  }

  void dispose() {
    for (final controller in all) {
      controller.dispose();
    }
  }

  int? get parsedExperience => int.tryParse(experience.text.trim());

  List<String> get parsedSkills => skills.text
      .split(',')
      .map((skill) => skill.trim())
      .where((skill) => skill.isNotEmpty)
      .toSet()
      .toList(growable: false);

  bool validate(AppLocalizations localization) {
    final experienceText = experience.text.trim();
    final parsed = parsedExperience;
    firstNameError = firstName.text.trim().isEmpty
        ? localization.candidateNameRequired
        : null;
    experienceError =
        experienceText.isNotEmpty && (parsed == null || parsed < 0)
        ? localization.candidateExperienceInvalid
        : null;
    return firstNameError == null && experienceError == null;
  }

  Candidate toCandidate({Candidate? existing, String? cvFileName}) {
    final now = DateTime.now().toUtc();
    final experienceText = experience.text.trim();
    if (existing != null) {
      return existing.copyWith(
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        email: email.text.trim(),
        phone: phone.text.trim(),
        location: location.text.trim(),
        headline: headline.text.trim(),
        skills: parsedSkills,
        yearsOfExperience: parsedExperience,
        clearYearsOfExperience: experienceText.isEmpty,
        githubUrl: github.text.trim(),
        linkedinUrl: linkedin.text.trim(),
        sourceId: sourceId,
        cvFileName: cvFileName ?? existing.cvFileName,
        updatedAt: now,
      );
    }
    return Candidate(
      id: const Uuid().v4(),
      firstName: firstName.text.trim(),
      lastName: lastName.text.trim(),
      email: email.text.trim(),
      phone: phone.text.trim(),
      location: location.text.trim(),
      headline: headline.text.trim(),
      skills: parsedSkills,
      yearsOfExperience: parsedExperience,
      githubUrl: github.text.trim(),
      linkedinUrl: linkedin.text.trim(),
      stageId: '',
      sourceId: sourceId,
      createdAt: now,
      updatedAt: now,
      cvFileName: cvFileName,
    );
  }
}
