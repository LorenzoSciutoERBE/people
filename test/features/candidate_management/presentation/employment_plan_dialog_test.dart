import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/domain/entities/employment_plan.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/failures/candidate_repository_exception.dart';
import 'package:people/features/candidate_management/domain/repositories/candidate_repository.dart';
import 'package:people/features/candidate_management/presentation/providers/candidate_management_providers.dart';
import 'package:people/features/candidate_management/presentation/widgets/employment_plan_dialog.dart';
import 'package:people/l10n/app_localizations.dart';

class _Repository implements CandidateRepository {
  String? failure;
  EmploymentPlan? savedPlan;
  String? destination;

  @override
  Future<RecruitingData> load() async => RecruitingData.initial();

  @override
  Future<void> moveCandidate(
    String candidateId,
    String destinationStageId, {
    EmploymentPlan? employmentPlan,
  }) async {
    if (failure case final code?) throw CandidateRepositoryException(code);
    destination = destinationStageId;
    savedPlan = employmentPlan;
  }

  @override
  Future<void> saveEmploymentPlan(
    String candidateId,
    EmploymentPlan plan,
  ) async {
    savedPlan = plan;
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester,
  _Repository repository, {
  bool hiring = true,
}) async {
  tester.view.physicalSize = const Size(1400, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        candidateRepositoryProvider.overrideWith((ref) async => repository),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(candidateManagementControllerProvider);
            return Scaffold(
              body: state.when(
                loading: () => const CircularProgressIndicator(),
                error: (error, stack) => Text(error.toString()),
                data: (_) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => EmploymentPlanDialog(
                      destinationStageId: hiring ? 'hired' : null,
                      candidate: Candidate(
                        id: 'candidate',
                        firstName: 'Ada',
                        lastName: 'Lovelace',
                        stageId: hiring ? 'offer' : 'hired',
                        sourceId: 'other',
                        createdAt: DateTime(2026),
                        updatedAt: DateTime(2026),
                        employmentPlan: EmploymentPlan.propose(
                          DateTime(2026, 1, 31),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('confirms hiring with one save action and optional export', (
    tester,
  ) async {
    final repository = _Repository();
    await _open(tester, repository);
    expect(find.text('Confirm hiring'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const Key('employment-save-export')),
          )
          .value,
      isFalse,
    );
    await tester.tap(find.byKey(const Key('employment-plan-save')));
    await tester.pumpAndSettle();
    expect(find.byType(EmploymentPlanDialog), findsNothing);
    expect(repository.destination, 'hired');
    expect(
      repository.savedPlan!.followUps.first.scheduledAt,
      DateTime(2026, 2, 28, 15),
    );
    expect(
      find.text(
        'Hiring confirmed. You can find this person and their meetings in Hired people.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows hiring failures inside the dialog and allows retry', (
    tester,
  ) async {
    final repository = _Repository()..failure = 'accepted_offer_required';
    await _open(tester, repository);
    tester.view.physicalSize = const Size(1400, 700);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('employment-plan-save')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('employment-plan-error')).hitTestable(),
      findsOneWidget,
    );
    expect(find.byType(EmploymentPlanDialog), findsOneWidget);
    expect(
      find.text(
        'Save an offer with status Accepted before hiring this candidate. A positive decision alone is not enough.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('employment-edit-offer')), findsOneWidget);
    expect(repository.savedPlan, isNull);
    repository.failure = null;
    await tester.tap(find.byKey(const Key('employment-plan-save')));
    await tester.pumpAndSettle();
    expect(find.byType(EmploymentPlanDialog), findsNothing);
    expect(repository.destination, 'hired');
  });

  testWidgets('saves an existing meeting plan without moving the person', (
    tester,
  ) async {
    final repository = _Repository();
    await _open(tester, repository, hiring: false);
    await tester.tap(find.byKey(const Key('employment-completed-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('employment-plan-save')));
    await tester.pumpAndSettle();
    expect(find.byType(EmploymentPlanDialog), findsNothing);
    expect(repository.destination, isNull);
    expect(repository.savedPlan!.followUps.first.completed, isTrue);
  });
}
