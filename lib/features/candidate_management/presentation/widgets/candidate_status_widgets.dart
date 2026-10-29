import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/recruiting_data.dart';

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
      FeedbackDecision.neutral => (
        Icons.remove_circle,
        const Color(0xFF5F6B7A),
        localization.candidateFeedbackNeutral,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
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
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
