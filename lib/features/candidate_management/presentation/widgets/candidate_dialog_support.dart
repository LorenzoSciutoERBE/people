import 'package:flutter/material.dart';

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
    final message = switch (error.code) {
      'positive_feedback_required' => localization.candidateMoveForwardBlocked,
      'negative_feedback_required' => localization.candidateRejectBlocked,
      'accepted_offer_required' => localization.candidateHireBlocked,
      'invalid_stage_transition' => localization.candidateTransitionBlocked,
      _ => localization.candidateActionFailed,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  } on Object {
    if (context.mounted) showCandidateActionError(context);
  }
}

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
  FeedbackDecision.neutral => localization.candidateFeedbackNeutral,
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
) => source.name == _defaultSourceName(source.id)
    ? switch (source.id) {
        'grafton' => localization.candidateDefaultGrafton,
        'poli' => localization.candidateDefaultPoli,
        'github' => localization.candidateDefaultGithub,
        'other' => localization.candidateDefaultOther,
        _ => source.name,
      }
    : source.name;

String localizedStageName(AppLocalizations localization, HiringStage stage) =>
    stage.name == _defaultStageName(stage.id)
    ? switch (stage.id) {
        'new' => localization.candidateDefaultNew,
        'cv_review' => localization.candidateDefaultCvReview,
        'screening' => localization.candidateDefaultScreening,
        'technical' => localization.candidateDefaultTechnical,
        'final' => localization.candidateDefaultFinal,
        'offer' => localization.candidateDefaultOffer,
        'hired' => localization.candidateDefaultHired,
        'rejected' => localization.candidateDefaultRejected,
        _ => stage.name,
      }
    : stage.name;

String? _defaultSourceName(String id) => switch (id) {
  'grafton' => 'Grafton',
  'poli' => 'Poli',
  'github' => 'GitHub',
  'other' => 'Other',
  _ => null,
};

String? _defaultStageName(String id) => switch (id) {
  'new' => 'New',
  'cv_review' => 'CV review',
  'screening' => 'Screening interview',
  'technical' => 'Technical interview',
  'final' => 'Final interview',
  'offer' => 'Offer / pre-contract',
  'hired' => 'Hired',
  'rejected' => 'Rejected',
  _ => null,
};
