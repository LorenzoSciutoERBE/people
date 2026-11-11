import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import 'candidate_dialog_support.dart';

/// Operational status stays visible even when evaluation scores are hidden.
class PipelineStatus extends StatelessWidget {
  const PipelineStatus({super.key, required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final current = candidate.latestFeedbackFor(candidate.stageId);
    final pending = candidate.interviews.where(
      (record) =>
          record.stageId != 'new' &&
          record.decision != FeedbackDecision.pending &&
          !record.feedbackSharedWithCandidate,
    );
    final String label;
    final IconData icon;
    final Color color;
    if (pending.isNotEmpty) {
      label = localization.pipelineFeedbackPending;
      icon = Icons.mark_email_unread_outlined;
      color = const Color(0xFFB06000);
    } else if (candidate.stageId == 'new') {
      label = current == null || current.notes.isEmpty
          ? localization.pipelineReviewCv
          : localization.pipelineReady;
      icon = Icons.description_outlined;
      color = Theme.of(context).colorScheme.primary;
    } else if (const {
      'screening',
      'technical',
      'final',
    }.contains(candidate.stageId)) {
      if (current?.scheduledAt == null) {
        label = localization.pipelineSchedule;
        icon = Icons.event_outlined;
      } else if (current?.decision == FeedbackDecision.pending) {
        final appointment = current!.scheduledAt!.toLocal();
        final date = MaterialLocalizations.of(context)
            .formatMediumDate(appointment);
        final time = MaterialLocalizations.of(context)
            .formatTimeOfDay(TimeOfDay.fromDateTime(appointment));
        label =
            '${localization.pipelineAwaitingFeedback} · $date $time · ${current.interviewer}';
        icon = Icons.event_available_outlined;
      } else {
        label = localization.pipelineFeedbackShared;
        icon = Icons.mark_email_read_outlined;
      }
      color = Theme.of(context).colorScheme.primary;
    } else if (candidate.stageId == 'offer') {
      label = current == null
          ? localizedOfferStatus(
              localization,
              candidate.offer?.status ?? OfferStatus.draft,
            )
          : localization.pipelineReady;
      icon = Icons.handshake_outlined;
      color = Theme.of(context).colorScheme.primary;
    } else {
      return const SizedBox.shrink();
    }
    return Row(
      key: ValueKey('pipeline-status-${candidate.id}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
