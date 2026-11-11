import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/repositories/candidate_repository.dart';
import 'package:people/features/candidate_management/presentation/providers/candidate_management_providers.dart';
import 'package:people/features/candidate_management/presentation/widgets/interview_feedback_form.dart';
import 'package:people/l10n/app_localizations.dart';

class _RecordingRepository implements CandidateRepository {
  FeedbackDecision? savedDecision;
  DateTime? savedRecordedAt;
  bool? savedSharedWithCandidate;
  bool failReload = false;

  @override
  Future<RecruitingData> load() async {
    if (failReload && savedDecision != null) {
      throw const FormatException('Test reload failure.');
    }
    return RecruitingData.initial();
  }

  @override
  Future<void> saveInterviewFeedback(
    String candidateId, {
    required String stageId,
    required FeedbackDecision decision,
    required String notes,
    DateTime? recordedAt,
    bool? feedbackSharedWithCandidate,
    DateTime? scheduledAt,
    String? interviewer,
  }) async {
    savedDecision = decision;
    savedRecordedAt = recordedAt;
    savedSharedWithCandidate = feedbackSharedWithCandidate;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final failReload in [false, true]) {
    testWidgets('feedback save handles reload failure: $failReload', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repository = _RecordingRepository()..failReload = failReload;
      var saved = false;
      final data = RecruitingData.initial();
      final candidate = Candidate(
        id: 'c1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        stageId: data.stages.first.id,
        sourceId: data.sources.first.id,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            candidateRepositoryProvider.overrideWith((ref) async => repository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer(
              builder: (context, ref, _) {
                ref.watch(candidateManagementControllerProvider);
                return Scaffold(
                  body: SizedBox(
                    width: 1500,
                    height: 900,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: InterviewFeedbackForm(
                        candidate: candidate,
                        stage: data.stages.first,
                        onSaved: () => saved = true,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('feedback-notes')),
        'Keep this draft if refreshing fails.',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('feedback-save')));
      await tester.pumpAndSettle();

      expect(repository.savedDecision, FeedbackDecision.pending);
      expect(repository.savedRecordedAt, isNotNull);
      expect(saved, !failReload);
      if (failReload) {
        expect(
          find.text('Keep this draft if refreshing fails.'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Unable to save this recruiting change. Please review the data and try again.',
          ),
          findsOneWidget,
        );
      }
    });
  }

  testWidgets('defaults feedback date automatically and allows editing it', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _RecordingRepository();
    final data = RecruitingData.initial();
    final candidate = Candidate(
      id: 'c1',
      firstName: 'Ada',
      lastName: 'Lovelace',
      stageId: data.stages.first.id,
      sourceId: data.sources.first.id,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
    final existing = InterviewRecord(
      id: 'i1',
      stageId: data.stages.first.id,
      createdAt: DateTime.utc(2026, 3, 15, 12),
      decision: FeedbackDecision.positive,
      notes: 'Great interview.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          candidateRepositoryProvider.overrideWith((ref) async => repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(candidateManagementControllerProvider);
              return Scaffold(
                body: SizedBox(
                  width: 1500,
                  height: 900,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: InterviewFeedbackForm(
                      candidate: candidate,
                      stage: data.stages.first,
                      existing: existing,
                      onSaved: () {},
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('feedback-date')), findsOneWidget);

    await tester.tap(find.byKey(const Key('feedback-date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('feedback-save')));
    await tester.pumpAndSettle();

    expect(repository.savedRecordedAt?.year, 2026);
    expect(repository.savedRecordedAt?.month, 3);
    expect(repository.savedRecordedAt?.day, 10);
  });

  testWidgets('allows marking positive and negative feedback as communicated', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _RecordingRepository();
    final data = RecruitingData.initial();
    final candidate = Candidate(
      id: 'c1',
      firstName: 'Ada',
      lastName: 'Lovelace',
      stageId: data.stages.first.id,
      sourceId: data.sources.first.id,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          candidateRepositoryProvider.overrideWith((ref) async => repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) {
              ref.watch(candidateManagementControllerProvider);
              return Scaffold(
                body: SizedBox(
                  width: 1500,
                  height: 900,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: InterviewFeedbackForm(
                      candidate: candidate,
                      stage: data.stages.firstWhere(
                        (stage) => stage.id == 'screening',
                      ),
                      onSaved: () {},
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('feedback-shared-with-candidate')),
      findsNothing,
    );

    await tester.tap(find.text('Negative'));
    await tester.pumpAndSettle();

    final sharedChip = find.byKey(const Key('feedback-shared-with-candidate'));
    expect(sharedChip, findsOneWidget);

    await tester.tap(sharedChip);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('feedback-save')));
    await tester.pumpAndSettle();

    expect(repository.savedDecision, FeedbackDecision.negative);
    expect(repository.savedSharedWithCandidate, isTrue);
    await tester.tap(find.text('Positive'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilterChip>(sharedChip).selected, isFalse);
    await tester.tap(sharedChip);
    await tester.tap(find.byKey(const Key('feedback-save')));
    await tester.pumpAndSettle();
    expect(repository.savedDecision, FeedbackDecision.positive);
    expect(repository.savedSharedWithCandidate, isTrue);
  });
}
