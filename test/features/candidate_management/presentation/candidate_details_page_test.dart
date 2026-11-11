import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/repositories/candidate_repository.dart';
import 'package:people/features/candidate_management/presentation/providers/candidate_management_providers.dart';
import 'package:people/features/candidate_management/presentation/widgets/candidate_details_page.dart';
import 'package:people/features/candidate_management/presentation/widgets/star_rating.dart';
import 'package:people/l10n/app_localizations.dart';

class _CandidateRepository implements CandidateRepository {
  _CandidateRepository(this.data);

  RecruitingData data;

  @override
  Future<RecruitingData> load() async => data;

  @override
  Future<Candidate> saveCandidate(
    Candidate candidate, {
    List<int>? cvBytes,
  }) async {
    data = RecruitingData(
      candidates: [candidate],
      sources: data.sources,
      stages: data.stages,
      favorites: data.favorites,
    );
    return candidate;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('opens a modal candidate record with inline editable fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final initial = RecruitingData.initial();
    final candidate = Candidate(
      id: 'candidate-1',
      firstName: 'Ada',
      lastName: 'Lovelace',
      stageId: initial.stages.first.id,
      sourceId: initial.sources.first.id,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final repository = _CandidateRepository(
      RecruitingData(
        candidates: [candidate],
        sources: initial.sources,
        stages: initial.stages,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          candidateRepositoryProvider.overrideWith((ref) async => repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    CandidateDetailsPage.open(context, candidate.id),
                child: const Text('Open profile'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    // Personal details are hidden by default so the hiring process is in focus.
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(StarRating), findsWidgets);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CandidateDetailsPage)),
    );
    container.read(evaluationsVisibleProvider.notifier).toggle();
    await tester.pumpAndSettle();
    expect(find.byType(StarRating), findsNothing);
    container.read(evaluationsVisibleProvider.notifier).toggle();
    await tester.pumpAndSettle();
    expect(find.byType(StarRating), findsWidgets);

    await tester.tap(find.byKey(const Key('toggle-candidate-profile')));
    await tester.pumpAndSettle();

    final firstName = find.byType(TextField).first;
    await tester.enterText(firstName, 'Grace');
    await tester.pump();
    await tester.tap(find.byKey(const Key('toggle-candidate-profile')));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(firstName).controller!.text, 'Grace');
    await tester.tap(find.text('Save candidate'));
    await tester.pumpAndSettle();
    expect(repository.data.candidates.single.firstName, 'Grace');

    await tester.enterText(firstName, 'Discarded draft');
    await tester.tap(find.byKey(const Key('toggle-candidate-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const Key('toggle-candidate-profile')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(firstName).controller!.text, 'Grace');

    await tester.enterText(firstName, '');
    await tester.pump();
    await tester.tap(find.text('Save candidate'));
    await tester.pumpAndSettle();
    expect(find.text('Enter at least a first name.'), findsOneWidget);
    expect(repository.data.candidates.single.firstName, 'Grace');

    await tester.enterText(firstName, 'Grace');
    final experience = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Years of experience',
    );
    await tester.ensureVisible(experience);
    await tester.enterText(experience, '-2');
    await tester.pump();
    await tester.tap(find.text('Save candidate'));
    await tester.pumpAndSettle();
    expect(
      find.text('Enter a whole number of years, zero or greater.'),
      findsOneWidget,
    );
    expect(repository.data.candidates.single.yearsOfExperience, isNull);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });
}
