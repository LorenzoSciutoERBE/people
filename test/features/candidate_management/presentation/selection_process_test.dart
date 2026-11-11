import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/repositories/candidate_repository.dart';
import 'package:people/features/candidate_management/presentation/providers/candidate_management_providers.dart';
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
    DateTime? recordedAt,
    bool? feedbackSharedWithCandidate,
    DateTime? scheduledAt,
    String? interviewer,
  }) async {
    final candidate = data.candidates.single;
    final previous = candidate.latestFeedbackFor(stageId)!;
    data = data.copyWith(
      candidates: [
        candidate.copyWith(
          interviews: [
            for (final record in candidate.interviews)
              if (record.stageId != stageId) record,
            InterviewRecord(
              id: previous.id,
              stageId: stageId,
              createdAt: previous.createdAt,
              decision: decision,
              notes: notes,
              scheduledAt: previous.scheduledAt,
              interviewer: previous.interviewer,
              feedbackSharedWithCandidate: feedbackSharedWithCandidate ?? false,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'current step has one communication action and unlocks progression when shared',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final initial = RecruitingData.initial();
      final candidate = Candidate(
        id: 'selection',
        firstName: 'Ada',
        lastName: 'Lovelace',
        stageId: 'technical',
        sourceId: 'grafton',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        interviews: [
          InterviewRecord(
            id: 'cv',
            stageId: 'new',
            createdAt: DateTime.utc(2026),
            decision: FeedbackDecision.pending,
            notes: 'Relevant CV.',
          ),
          InterviewRecord(
            id: 'technical',
            stageId: 'technical',
            createdAt: DateTime.utc(2026),
            decision: FeedbackDecision.positive,
            notes: 'Strong systems thinking.',
            scheduledAt: DateTime.utc(2026, 11, 12, 14),
            interviewer: 'Technical interviewer',
          ),
        ],
      );
      final repository = _Repository(initial.copyWith(candidates: [candidate]));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            candidateRepositoryProvider.overrideWith((ref) async => repository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: CandidateDetailsPage(candidateId: 'selection'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('CURRENT STEP'), findsOneWidget);
      expect(find.text('Technical interviewer'), findsOneWidget);
      expect(find.byKey(const Key('selection-advance-final')), findsNothing);
      final communication = find.byKey(const Key('feedback-shared-technical'));
      expect(communication, findsOneWidget);
      await tester.tap(communication);
      await tester.pumpAndSettle();
      expect(
        repository.data.candidates.single
            .latestFeedbackFor('technical')!
            .feedbackSharedWithCandidate,
        isTrue,
      );
      expect(find.byKey(const Key('selection-advance-final')), findsOneWidget);
      expect(find.byKey(const Key('selection-advance-rejected')), findsNothing);
      tester.view.physicalSize = const Size(850, 650);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
