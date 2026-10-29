import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/di/candidate_management_dependencies.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/repositories/candidate_repository.dart';
import 'package:people/features/candidate_management/presentation/widgets/candidate_details_page.dart';
import 'package:people/l10n/app_localizations.dart';

class _Repository implements CandidateRepository {
  _Repository(this.data);

  RecruitingData data;

  @override
  Future<RecruitingData> load() async => data;

  @override
  Future<void> saveInterviewFeedback(
    String candidateId, {
    required String stageId,
    required FeedbackDecision decision,
    required String notes,
  }) async {
    final candidate = data.candidates.single;
    final previous = candidate.latestFeedbackFor(stageId)!;
    data = RecruitingData(
      candidates: [
        candidate.copyWith(
          interviews: [
            InterviewRecord(
              id: previous.id,
              stageId: stageId,
              createdAt: previous.createdAt,
              decision: decision,
              notes: notes,
            ),
          ],
        ),
      ],
      sources: data.sources,
      stages: data.stages,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final size in const [Size(1600, 1000), Size(1100, 700)]) {
    testWidgets('history shows saved interview notes at $size', (tester) async {
      await _pumpDetails(tester, size);

      expect(find.text('Strong systems thinking.'), findsOneWidget);

      // Tapping the card opens the stage feedback in an editable dialog.
      await tester.tap(find.text('Strong systems thinking.'));
      await tester.pumpAndSettle();
      final field = find.widgetWithText(TextField, 'Strong systems thinking.');
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Edited notes.');
      expect(find.text('Edited notes.'), findsOneWidget);
      await tester.tap(find.text('Save feedback'));
      await tester.pumpAndSettle();
      expect(find.text('Edited notes.'), findsOneWidget);
      await tester.tap(find.text('Edited notes.'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Edited notes.'), findsOneWidget);
    });
  }

  testWidgets('closing dirty feedback requires confirmation', (tester) async {
    await _pumpDetails(tester, const Size(1100, 700));
    await tester.tap(find.text('Strong systems thinking.'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Strong systems thinking.'),
      'Unsaved notes.',
    );
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Unsaved notes.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Unsaved notes.'), findsNothing);
    expect(find.text('Strong systems thinking.'), findsOneWidget);
  });

  testWidgets('feedback actions remain reachable in a small window', (
    tester,
  ) async {
    await _pumpDetails(tester, const Size(1100, 700));
    await tester.tap(find.text('Strong systems thinking.'));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(600, 440);
    await tester.pumpAndSettle();
    final save = find.text('Save feedback');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    expect(save.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDetails(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final initial = RecruitingData.initial();
  final candidate = Candidate(
    id: 'c1',
    firstName: 'Ada',
    lastName: 'Lovelace',
    stageId: initial.stages.first.id,
    sourceId: initial.sources.first.id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    interviews: [
      InterviewRecord(
        id: 'i1',
        stageId: initial.stages.first.id,
        createdAt: DateTime(2026),
        decision: FeedbackDecision.positive,
        notes: 'Strong systems thinking.',
      ),
    ],
  );
  final repository = _Repository(
    RecruitingData(
      candidates: [candidate],
      sources: initial.sources,
      stages: initial.stages,
      favorites: const [],
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
        home: const Scaffold(body: CandidateDetailsPage(candidateId: 'c1')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
