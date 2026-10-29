import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/di/candidate_management_dependencies.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/repositories/candidate_repository.dart';
import 'package:people/features/candidate_management/presentation/providers/candidate_management_providers.dart';
import 'package:people/features/candidate_management/presentation/widgets/interview_feedback_form.dart';
import 'package:people/l10n/app_localizations.dart';

class _RecordingRepository implements CandidateRepository {
  FeedbackDecision? savedDecision;

  @override
  Future<RecruitingData> load() async => RecruitingData.initial();

  @override
  Future<void> saveInterviewFeedback(
    String candidateId, {
    required String stageId,
    required FeedbackDecision decision,
    required String notes,
  }) async {
    savedDecision = decision;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('feedback form saves ratings and neutral decision', (
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
                      stage: data.stages.first,
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

    await tester.tap(find.text('Neutral'));
    await tester.pump();
    await tester.tap(find.text('Save feedback'));
    await tester.pumpAndSettle();

    expect(repository.savedDecision, FeedbackDecision.neutral);
  });
}
