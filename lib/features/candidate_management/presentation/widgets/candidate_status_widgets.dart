import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';
import 'candidate_dialog_support.dart';

/// Semantic accent color for a [HiringStage] across board columns and badges.
Color stageAccentColor(BuildContext context, HiringStage stage) =>
    switch (stage.terminalOutcome) {
      TerminalOutcome.hired => const Color(0xFF1E8E3E),
      TerminalOutcome.rejected => const Color(0xFFD93025),
      TerminalOutcome.active =>
        stage.isOfferStage
            ? const Color(0xFF8E4EC6)
            : Theme.of(context).colorScheme.primary,
    };

/// Colored pill displaying a pipeline stage name with its semantic accent.
class StageBadge extends StatelessWidget {
  const StageBadge({super.key, required this.stage});

  final HiringStage stage;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final color = stageAccentColor(context, stage);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                localizedStageName(localization, stage),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle pill displaying the candidate's acquisition source.
class SourceBadge extends StatelessWidget {
  const SourceBadge({super.key, required this.source});

  final CandidateSource source;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.source_outlined,
              size: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                localizedSourceName(localization, source),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colored pill that shows whether feedback was given for the current stage.
class FeedbackBadge extends StatelessWidget {
  const FeedbackBadge({super.key, required this.decision});

  final FeedbackDecision? decision;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    final (IconData icon, Color color, String label) = switch (decision) {
      FeedbackDecision.positive => (
        Icons.check_circle,
        const Color(0xFF1E8E3E),
        localization.candidateFeedbackPositive,
      ),
      FeedbackDecision.negative => (
        Icons.cancel,
        const Color(0xFFD93025),
        localization.candidateFeedbackNegative,
      ),
      _ => (
        Icons.schedule,
        const Color(0xFFE37400),
        localization.candidateFeedbackRequired,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Initial-based avatar with a stable color derived from the name.
class CandidateAvatar extends StatelessWidget {
  const CandidateAvatar({super.key, required this.name, this.radius = 20});

  final String name;
  final double radius;

  static const List<Color> _palette = <Color>[
    Color(0xFF2155CD),
    Color(0xFF0B8A83),
    Color(0xFF8E4EC6),
    Color(0xFFD9480F),
    Color(0xFF3B7D23),
    Color(0xFFB0285E),
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[name.hashCode.abs() % _palette.length];
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.14),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Compact pill chip displaying a candidate skill in boards and lists.
class CandidateSkillChip extends StatelessWidget {
  const CandidateSkillChip({super.key, required this.skill});

  final String skill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          skill,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
