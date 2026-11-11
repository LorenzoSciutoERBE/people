import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_dialog_support.dart';

/// Candidate communication can be updated independently of internal feedback.
class CandidateCommunicationToggle extends ConsumerWidget {
  const CandidateCommunicationToggle({
    super.key,
    required this.candidateId,
    required this.record,
  });

  final String candidateId;
  final InterviewRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) => FilterChip(
    key: ValueKey('feedback-shared-${record.stageId}'),
    avatar: const Icon(Icons.outgoing_mail, size: 16),
    selected: record.feedbackSharedWithCandidate,
    label: Text(AppLocalizations.of(context).candidateFeedbackSentToCandidate),
    onSelected: (value) => performCandidateAction(
      context,
      AppLocalizations.of(context),
      () => ref
          .read(candidateManagementControllerProvider.notifier)
          .saveFeedback(
            candidateId,
            stageId: record.stageId,
            decision: record.decision,
            notes: record.notes,
            recordedAt: record.createdAt,
            feedbackSharedWithCandidate: value,
          ),
    ),
  );
}
