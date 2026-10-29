import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import '../providers/candidate_management_providers.dart';
import 'candidate_dialog_support.dart';
import 'candidate_editor_dialog.dart';
import 'candidate_details_page.dart';
import 'offer_dialog.dart';

/// Overflow menu with the edit, feedback, offer and delete actions of a
/// candidate, shared by the pipeline board and the candidate list.
class CandidateActionsMenu extends ConsumerWidget {
  const CandidateActionsMenu({
    super.key,
    required this.candidate,
    required this.stage,
    required this.feedbackEnabled,
  });

  final Candidate candidate;
  final HiringStage stage;
  final bool feedbackEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: localization.candidateEdit,
      onSelected: (value) => _handle(context, ref, value),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'edit', child: Text(localization.candidateEdit)),
        if (feedbackEnabled)
          PopupMenuItem(
            value: 'feedback',
            child: Text(localization.candidateFeedback),
          ),
        if (stage.isOfferStage)
          PopupMenuItem(
            value: 'offer',
            child: Text(localization.candidateOffer),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Text(localization.candidateDelete),
        ),
      ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    final localization = AppLocalizations.of(context);
    switch (value) {
      case 'edit':
        final data = ref
            .read(candidateManagementControllerProvider)
            .asData
            ?.value;
        if (data == null) return;
        await showDialog<void>(
          context: context,
          builder: (_) =>
              CandidateEditorDialog(data: data, candidate: candidate),
        );
      case 'feedback':
        await CandidateDetailsPage.open(
          context,
          candidate.id,
          startWithFeedback: true,
        );
      case 'offer':
        await showDialog<void>(
          context: context,
          builder: (_) => OfferDialog(candidate: candidate),
        );
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
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
        if (confirmed == true && context.mounted) {
          await performCandidateAction(
            context,
            localization,
            () => ref
                .read(candidateManagementControllerProvider.notifier)
                .deleteCandidate(candidate.id),
          );
        }
    }
  }
}
