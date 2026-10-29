import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Five-star control supporting half-star steps (0.5 to 5).
///
/// Tapping the left half of a star selects a half value; tapping the current
/// value again clears the rating. A null [value] means "not rated".
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 32,
  });

  static const int starCount = 5;

  final double? value;
  final ValueChanged<double?>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Colors.amber.shade800;
    final current = value ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < starCount; index++)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: onChanged == null
                ? null
                : (details) => _select(index, details.localPosition.dx),
            child: MouseRegion(
              cursor: onChanged == null
                  ? MouseCursor.defer
                  : SystemMouseCursors.click,
              child: Icon(
                _iconFor(current, index),
                size: size,
                color: current >= index + 0.5
                    ? color
                    : color.withValues(alpha: 0.48),
              ),
            ),
          ),
      ],
    );
  }

  void _select(int index, double dx) {
    final selected = index + (dx < size / 2 ? 0.5 : 1.0);
    onChanged?.call(selected == value ? null : selected);
  }

  static IconData _iconFor(double current, int index) {
    if (current >= index + 1) return Icons.star_rounded;
    if (current >= index + 0.5) return Icons.star_half_rounded;
    return Icons.star_border_rounded;
  }
}

/// Compact star icon with the average rating, e.g. "4.3".
class AverageRatingBadge extends StatelessWidget {
  const AverageRatingBadge({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final displayRating = (rating * 2).round() / 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < StarRating.starCount; index++)
          Icon(
            _iconFor(displayRating, index),
            size: 16,
            color: displayRating >= index + 0.5
                ? Colors.amber.shade800
                : Colors.amber.shade800.withValues(alpha: 0.48),
          ),
        const SizedBox(width: 4),
        Text(
          NumberFormat.decimalPatternDigits(
            locale: Localizations.localeOf(context).toString(),
            decimalDigits: 1,
          ).format(rating),
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  static IconData _iconFor(double rating, int index) {
    if (rating >= index + 1) return Icons.star_rounded;
    if (rating >= index + 0.5) return Icons.star_half_rounded;
    return Icons.star_border_rounded;
  }
}
