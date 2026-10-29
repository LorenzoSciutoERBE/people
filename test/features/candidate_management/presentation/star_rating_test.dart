import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/presentation/widgets/star_rating.dart';

void main() {
  testWidgets('selects half and full stars and clears on repeat tap', (
    tester,
  ) async {
    double? value;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => StarRating(
              value: value,
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );
    final first = tester.getTopLeft(find.byType(Icon).first);
    await tester.tapAt(first + const Offset(4, 16));
    await tester.pump();
    expect(value, 0.5);
    await tester.tapAt(first + const Offset(28, 16));
    await tester.pump();
    expect(value, 1);
    await tester.tapAt(first + const Offset(32 * 2 + 28, 16));
    await tester.pump();
    expect(value, 3);
    await tester.tapAt(first + const Offset(32 * 2 + 28, 16));
    await tester.pump();
    expect(value, isNull);
  });

  testWidgets('shows all five visible stars for an average rating', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AverageRatingBadge(rating: 3.5))),
    );

    final stars = tester.widgetList<Icon>(
      find.descendant(
        of: find.byType(AverageRatingBadge),
        matching: find.byType(Icon),
      ),
    );
    expect(stars, hasLength(5));
    expect(stars.map((star) => star.icon), [
      Icons.star_rounded,
      Icons.star_rounded,
      Icons.star_rounded,
      Icons.star_half_rounded,
      Icons.star_border_rounded,
    ]);
    expect(find.text('3.5'), findsOneWidget);
  });
}
