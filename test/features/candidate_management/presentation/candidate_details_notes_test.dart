import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/entities/employment_plan.dart';
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
    data = RecruitingData(
      candidates: [
        candidate.copyWith(
          interviews: [
            for (final record in candidate.interviews)
              if (record.stageId != stageId) record,
            InterviewRecord(
              id: previous.id,
              stageId: stageId,
              createdAt: recordedAt ?? previous.createdAt,
              decision: decision,
              notes: notes,
              feedbackSharedWithCandidate: feedbackSharedWithCandidate ?? false,
            ),
          ],
        ),
      ],
      sources: data.sources,
      stages: data.stages,
    );
  }

  @override
  Object? noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final hasOfferDate in [false, true]) {
    testWidgets(
      'pipeline shows compact recorded event dates with offer date: $hasOfferDate',
      (tester) async {
        final interviewDate = DateTime(2026, 2, 6, 14, 30);
        final offerDate = DateTime.utc(2026, 2, 15, 12);
        final startDate = DateTime(2026, 3, 1);
        await _pumpDetails(
          tester,
          const Size(1600, 1000),
          includeHistory: true,
          openStep: false,
          scheduledAt: interviewDate,
          offer: CandidateOffer(
            status: OfferStatus.sent,
            proposedStartDate: startDate,
            recordedAt: hasOfferDate ? offerDate : null,
          ),
        );
        final interview = find.byKey(const Key('pipeline-date-technical'));
        final offer = find.byKey(const Key('pipeline-date-offer'));
        final localization = MaterialLocalizations.of(
          tester.element(interview),
        );
        expect(
          find.descendant(
            of: interview,
            matching: find.text(localization.formatShortDate(interviewDate)),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: offer,
            matching: find.text(
              hasOfferDate
                  ? localization.formatShortDate(offerDate.toLocal())
                  : 'Start: ${localization.formatShortDate(startDate)}',
            ),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const Key('pipeline-date-final')), findsNothing);
        expect(find.byKey(const Key('candidate-profile')), findsOneWidget);
        expect(find.byKey(const Key('feedback-notes')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('pipeline shows the recorded hiring date', (tester) async {
    final hiredAt = DateTime(2026, 4, 6);
    await _pumpDetails(
      tester,
      const Size(1600, 1000),
      stageId: 'hired',
      openStep: false,
      hiredAt: hiredAt,
    );
    final date = find.byKey(const Key('pipeline-date-hired'));
    final localization = MaterialLocalizations.of(tester.element(date));
    expect(
      find.descendant(
        of: date,
        matching: find.text(localization.formatShortDate(hiredAt)),
      ),
      findsOneWidget,
    );
  });

  for (final outcome in ['hired', 'rejected']) {
    testWidgets(
      'pipeline includes the $outcome outcome without a current stage box',
      (tester) async {
        await _pumpDetails(
          tester,
          const Size(1600, 1000),
          includeHistory: true,
          stageId: outcome,
          openStep: false,
        );
        expect(
          find.byKey(ValueKey('pipeline-outcome-$outcome')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('pipeline-outcome-pending')), findsNothing);
        expect(find.text('CURRENT STEP'), findsNothing);
        expect(find.byKey(ValueKey('view-step-$outcome')), findsOneWidget);
        await tester.tap(find.byKey(const Key('view-step-new')));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('view-step-$outcome')), findsOneWidget);
        await tester.tap(find.byKey(ValueKey('view-step-$outcome')));
        await tester.pumpAndSettle();
        expect(find.byKey(ValueKey('feedback-step-$outcome')), findsOneWidget);
        expect(find.byKey(ValueKey('view-step-$outcome')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final size in const [
    Size(1600, 1000),
    Size(1100, 700),
    Size(700, 500),
  ]) {
    testWidgets(
      'recap keeps personal details visible and opens notes only on click at $size',
      (tester) async {
        final notes = List.generate(
          80,
          (index) => 'Observation $index: detailed interview feedback.',
        ).join('\n');
        await _pumpDetails(
          tester,
          size,
          includeHistory: true,
          previousNotes: notes,
          openStep: false,
        );
        expect(find.byKey(const Key('candidate-profile')), findsOneWidget);
        expect(find.byKey(const Key('feedback-notes')), findsNothing);
        expect(
          find.byKey(const Key('feedback-readonly-technical')),
          findsNothing,
        );
        expect(find.byIcon(Icons.visibility_outlined), findsNothing);
        expect(find.byIcon(Icons.visibility), findsNothing);
        final ratings = find.byKey(const Key('candidate-ratings-card'));
        final overview = find.byKey(const Key('candidate-overview-scrollbar'));
        expect(
          tester.getRect(ratings).right,
          lessThanOrEqualTo(tester.getRect(overview).right - 12),
        );
        final eye = find.byKey(const Key('view-step-new'));
        await tester.ensureVisible(eye);
        await tester.pumpAndSettle();
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(eye));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text(notes), findsNothing);
        expect(find.byKey(const Key('step-feedback-preview')), findsNothing);
        await tester.tap(
          find.descendant(of: eye, matching: find.text('CV review')),
        );
        await tester.pumpAndSettle();
        final sidebar = find.byKey(const Key('candidate-pipeline-scrollbar'));
        final rail = sidebar.evaluate().isEmpty ? overview : sidebar;
        expect(
          tester.getRect(ratings).right,
          lessThanOrEqualTo(tester.getRect(rail).right - 12),
        );
        expect(find.byKey(const Key('feedback-readonly-new')), findsOneWidget);
        expect(find.byKey(const Key('view-step-new')), findsNothing);
        expect(find.byKey(const Key('candidate-profile')), findsOneWidget);
        final close = find.byKey(const Key('close-step-notes'));
        await tester.ensureVisible(close);
        await tester.tap(close);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('feedback-readonly-new')), findsNothing);
        expect(find.byKey(const Key('candidate-profile')), findsOneWidget);
        expect(find.byKey(const Key('view-step-new')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('reads previous feedback from the timeline and protects drafts', (
    tester,
  ) async {
    await _pumpDetails(tester, const Size(1600, 1000), includeHistory: true);
    expect(
      find.widgetWithText(TextField, 'Current technical feedback.'),
      findsOneWidget,
    );
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.byKey(const Key('view-step-technical')), findsNothing);
    final previous = find.byKey(const Key('view-step-new'));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(previous));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Strong systems thinking.'), findsNothing);
    expect(find.byKey(const Key('step-feedback-preview')), findsNothing);
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('step-feedback-preview')), findsNothing);
    expect(find.byKey(const Key('view-step-new')), findsNothing);
    expect(find.byKey(const Key('view-step-technical')), findsOneWidget);
    final savedField = find.widgetWithText(
      TextField,
      'Strong systems thinking.',
    );
    expect(tester.widget<TextField>(savedField).readOnly, isTrue);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byKey(const Key('feedback-notes')), findsNothing);
    await tester.tap(find.byKey(const Key('selection-edit-step')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('feedback-notes')),
      'Unsaved previous feedback.',
    );
    await tester.tap(find.byKey(const Key('view-step-technical')));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved previous feedback.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('view-step-technical')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextField, 'Current technical feedback.'),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byKey(const Key('selection-edit-step')));
    await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile), findsNothing);
    expect(find.byKey(const Key('feedback-decision-positive')), findsOneWidget);
    expect(find.byKey(const Key('interview-interviewer')), findsOneWidget);
    expect(find.byKey(const Key('interview-schedule')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('feedback-notes')),
      'Updated technical feedback.',
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('feedback-save')));
    await tester.tap(find.byKey(const Key('feedback-save')));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextField, 'Updated technical feedback.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('feedback-save-success')), findsOneWidget);
  });

  testWidgets('discarded feedback does not carry into another stage', (
    tester,
  ) async {
    await _pumpDetails(
      tester,
      const Size(1600, 1000),
      includeHistory: true,
      previousNotes: '',
    );
    await tester.tap(find.byKey(const Key('selection-edit-step')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('feedback-notes')),
      'Discard this technical draft.',
    );
    final previous = find.byKey(const Key('view-step-new'));
    await tester.ensureVisible(previous);
    await tester.tap(previous);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('feedback-notes')),
    );
    expect(field.controller!.text, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('candidate header and ratings fit intermediate widths', (
    tester,
  ) async {
    await _pumpDetails(tester, const Size(950, 700));
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(700, 600);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final size in const [Size(1600, 1000), Size(1100, 700)]) {
    testWidgets('history shows saved interview notes at $size', (tester) async {
      await _pumpDetails(tester, size);

      expect(find.text('Strong systems thinking.'), findsOneWidget);

      // The pencil switches the visible feedback to editing in place.
      await tester.tap(find.byKey(const Key('selection-edit-step')));
      await tester.pumpAndSettle();
      final field = find.widgetWithText(TextField, 'Strong systems thinking.');
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Edited notes.');
      expect(find.text('Edited notes.'), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('feedback-save')));
      await tester.tap(find.text('Save feedback'));
      await tester.pumpAndSettle();
      expect(find.text('Edited notes.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('selection-edit-step')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('selection-edit-step')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feedback-notes')), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Edited notes.'), findsOneWidget);
    });
  }

  testWidgets('closing dirty feedback requires confirmation', (tester) async {
    await _pumpDetails(tester, const Size(1100, 700));
    await tester.tap(find.byKey(const Key('selection-edit-step')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Strong systems thinking.'),
      'Unsaved notes.',
    );
    await tester.ensureVisible(find.byKey(const Key('feedback-cancel')));
    await tester.tap(find.byKey(const Key('feedback-cancel')));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Unsaved notes.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('feedback-cancel')));
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
    await tester.tap(find.byKey(const Key('selection-edit-step')));
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

Future<void> _pumpDetails(
  WidgetTester tester,
  Size size, {
  bool includeHistory = false,
  String previousNotes = 'Strong systems thinking.',
  String? stageId,
  bool openStep = true,
  CandidateOffer? offer,
  DateTime? scheduledAt,
  DateTime? hiredAt,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final initial = RecruitingData.initial();
  final candidate = Candidate(
    id: 'c1',
    firstName: 'Ada',
    lastName: 'Lovelace',
    stageId:
        stageId ?? (includeHistory ? 'technical' : initial.stages.first.id),
    sourceId: initial.sources.first.id,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    offer: offer,
    employmentPlan: hiredAt == null ? null : EmploymentPlan.propose(hiredAt),
    headline: 'Senior engineer specializing in distributed systems and developer tools',
    ratings: const {
      RatingAspect.technicalSkills: 4.5,
      RatingAspect.problemSolving: 5,
    },
    interviews: [
      if (includeHistory)
        InterviewRecord(
          id: 'technical-feedback',
          stageId: 'technical',
          createdAt: DateTime(2026),
          decision: FeedbackDecision.pending,
          notes: 'Current technical feedback.',
          scheduledAt: scheduledAt,
        ),
      InterviewRecord(
        id: 'i1',
        stageId: initial.stages.first.id,
        createdAt: DateTime(2026),
        decision: FeedbackDecision.pending,
        notes: previousNotes,
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
  if (openStep) {
    final eye = find.byKey(ValueKey('view-step-${candidate.stageId}'));
    await tester.ensureVisible(eye);
    await tester.pumpAndSettle();
    await tester.tap(eye);
    await tester.pumpAndSettle();
  }
}
