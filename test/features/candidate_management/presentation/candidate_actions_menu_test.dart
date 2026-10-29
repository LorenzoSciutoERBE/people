import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/di/candidate_management_dependencies.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/failures/candidate_repository_exception.dart';
import 'package:people/features/candidate_management/domain/repositories/candidate_repository.dart';
import 'package:people/features/candidate_management/presentation/providers/candidate_management_providers.dart';
import 'package:people/features/candidate_management/presentation/widgets/candidate_actions_menu.dart';
import 'package:people/l10n/app_localizations.dart';

class _Repository implements CandidateRepository {
  String? destination;
  String? failure;

  @override
  Future<RecruitingData> load() async => RecruitingData.initial();

  @override
  Future<void> moveCandidate(
    String candidateId,
    String destinationStageId,
  ) async {
    if (failure case final code?) throw CandidateRepositoryException(code);
    destination = destinationStageId;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pumpMenu(WidgetTester tester, _Repository repository) async {
  final data = RecruitingData.initial();
  final stage = data.stages.firstWhere((stage) => stage.id == 'cv_review');
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
  testWidgets('opens feedback directly without nesting a candidate dialog', (
    tester,
  ) async {
    await _pumpMenu(tester, _Repository());
    await tester.tap(find.byTooltip('Candidate actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Interview feedback'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Interview notes'), findsOneWidget);
    expect(find.text('Save candidate'), findsNothing);
  });

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
    await tester.tap(find.text('Screening interview'));
    await tester.pumpAndSettle();
    expect(repository.destination, 'screening');
  });

  testWidgets('explains the requirement for rejecting a candidate', (
    tester,
  ) async {
    final repository = _Repository()..failure = 'negative_feedback_required';
    await _pumpMenu(tester, repository);
    await tester.tap(find.byTooltip('Candidate actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to stage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rejected'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Record a negative or neutral decision for the current stage before rejecting this candidate.',
      ),
      findsOneWidget,
    );
    expect(repository.destination, isNull);
  });
}
