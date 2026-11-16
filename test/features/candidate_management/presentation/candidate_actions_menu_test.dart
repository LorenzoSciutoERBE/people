import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/entities/employment_plan.dart';
import 'package:people/features/candidate_management/domain/failures/candidate_repository_exception.dart';
import 'package:people/features/candidate_management/domain/repositories/candidate_repository.dart';
import 'package:people/features/candidate_management/presentation/providers/candidate_management_providers.dart';
import 'package:people/features/candidate_management/presentation/widgets/candidate_actions_menu.dart';
import 'package:people/l10n/app_localizations.dart';

class _Repository implements CandidateRepository {
  String? destination;
  String? failure;

  @override
  Future<RecruitingData> load() async => RecruitingData.initial().copyWith(
    candidates: [
      Candidate(
        id: 'c1',
        firstName: 'Ada',
        lastName: 'Lovelace',
        stageId: 'new',
        sourceId: 'grafton',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        interviews: [
          InterviewRecord(
            id: 'cv',
            stageId: 'new',
            createdAt: DateTime(2026),
            decision: FeedbackDecision.pending,
            notes: 'Relevant experience.',
          ),
        ],
      ),
    ],
  );

  @override
  Future<void> moveCandidate(
    String candidateId,
    String destinationStageId, {
    EmploymentPlan? employmentPlan,
  }) async {
    if (failure case final code?) throw CandidateRepositoryException(code);
    destination = destinationStageId;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpMenu(WidgetTester tester, _Repository repository) async {
  final data = RecruitingData.initial();
  final stage = data.stages.firstWhere((stage) => stage.id == 'new');
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
              body: CandidateActionsMenu(
                candidate: Candidate(
                  id: 'c1',
                  firstName: 'Ada',
                  lastName: 'Lovelace',
                  stageId: stage.id,
                  sourceId: data.sources.first.id,
                  createdAt: DateTime(2026),
                  updatedAt: DateTime(2026),
                  interviews: [
                    InterviewRecord(
                      id: 'cv',
                      stageId: 'new',
                      createdAt: DateTime(2026),
                      decision: FeedbackDecision.pending,
                      notes: 'Relevant experience.',
                    ),
                  ],
                ),
                stage: stage,
                feedbackEnabled: true,
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens the existing candidate editor with CV import available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpMenu(tester, _Repository());
    await tester.tap(find.byTooltip('Candidate actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit candidate'));
    await tester.pumpAndSettle();
    expect(find.text('Import CV'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Ada'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Lovelace'), findsOneWidget);
  });

  testWidgets(
    'opens saved feedback in the candidate screen without another dialog',
    (tester) async {
      await _pumpMenu(tester, _Repository());
      await tester.tap(find.byTooltip('Candidate actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Interview & feedback'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byKey(const Key('candidate-profile')), findsOneWidget);
      expect(find.byKey(const Key('feedback-readonly-new')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('view-step-new')));
      await tester.tap(find.byKey(const Key('view-step-new')));
      await tester.pumpAndSettle();
      expect(find.text('Interview notes'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Relevant experience.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('feedback-save')), findsNothing);
      expect(find.text('Save candidate'), findsOneWidget);
    },
  );

  testWidgets('moves through the menu without dragging or skipping stages', (
    tester,
  ) async {
    final repository = _Repository();
    await _pumpMenu(tester, repository);
    await tester.tap(find.byTooltip('Candidate actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to stage'));
    await tester.pumpAndSettle();
    expect(find.text('Technical interview'), findsNothing);
    expect(find.text('Hired'), findsNothing);
    await tester.tap(find.text('Introductory interview'));
    await tester.pumpAndSettle();
    expect(repository.destination, 'screening');
  });

  testWidgets('does not offer rejection before the first interview', (
    tester,
  ) async {
    await _pumpMenu(tester, _Repository());
    await tester.tap(find.byTooltip('Candidate actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to stage'));
    await tester.pumpAndSettle();
    expect(find.text('Rejected'), findsNothing);
    expect(find.text('Introductory interview'), findsOneWidget);
  });
}
