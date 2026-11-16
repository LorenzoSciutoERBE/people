import 'dart:io';
import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:people/app.dart';
import 'package:people/core/l10n/locale_controller.dart';
import 'package:people/features/auth/domain/entities/auth_session.dart';
import 'package:people/features/auth/presentation/providers/auth_providers.dart';
import 'package:people/features/candidate_management/data/datasources/encrypted_vault.dart';
import 'package:people/features/candidate_management/data/repositories/local_candidate_repository.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/entities/employment_plan.dart';
import 'package:people/features/candidate_management/domain/repositories/resume_text_extractor.dart';
import 'package:people/features/candidate_management/presentation/providers/candidate_management_providers.dart';
import 'package:people/features/candidate_management/presentation/widgets/employment_reminders_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../support/test_file_picker.dart';

class _TestResumeExtractor implements ResumeTextExtractor {
  @override
  Future<String> extractText(List<int> bytes, String fileName) async =>
      'ADA LOVELACE\nada@example.com';
}

class _MemoryKeyStore implements VaultKeyStore {
  List<int>? _key;

  @override
  Future<List<int>?> readKey() async => _key;

  @override
  Future<void> writeKey(List<int> value) async => _key = List.of(value);
}

class _SignedOutAuthNotifier extends AuthNotifier {
  @override
  Future<AuthSession?> build() async => null;
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
  await tester.pumpAndSettle();
}

Future<void> _waitUntilGone(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 15));
  while (finder.evaluate().isNotEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsNothing);
  await tester.pumpAndSettle();
}

Future<void> _openActions(WidgetTester tester, {bool openMenu = true}) async {
  final close = find.byKey(const Key('candidate-details-close'));
  if (close.evaluate().isNotEmpty) {
    await tester.tap(close);
    await _waitUntilGone(tester, close);
  }
  final actions = find.byKey(
    const Key('candidate-actions-integration-candidate'),
  );
  if (actions.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      actions,
      400,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('candidate-board-stages')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
  }
  await _waitFor(tester, actions);
  await tester.ensureVisible(actions);
  await tester.pumpAndSettle();
  if (openMenu) {
    await tester.tap(actions);
    await tester.pumpAndSettle();
  }
}

Future<void> _openFeedback(WidgetTester tester) async {
  if (find.byKey(const Key('candidate-details-close')).evaluate().isEmpty) {
    await _openActions(tester);
    await tester.tap(find.text('Interview & feedback'));
    await _waitFor(tester, find.byKey(const Key('candidate-details-close')));
  }
  final container = ProviderScope.containerOf(
    tester.element(find.byKey(const Key('candidate-details-close'))),
  );
  final candidate = container
      .read(candidateManagementControllerProvider)
      .asData!
      .value
      .candidates
      .firstWhere((candidate) => candidate.id == 'integration-candidate');
  if (find
      .byKey(ValueKey('feedback-step-${candidate.stageId}'))
      .evaluate()
      .isEmpty) {
    await _openStep(tester, candidate.stageId);
  }
  final edit = find.byKey(const Key('selection-edit-step'));
  if (edit.evaluate().isNotEmpty) {
    await tester.ensureVisible(edit);
    await tester.tap(edit);
  }
  await _waitFor(tester, find.byKey(const Key('feedback-notes')));
  expect(find.byType(Dialog), findsOneWidget);
}

Future<void> _openStep(WidgetTester tester, String stageId) async {
  final eye = find.byKey(ValueKey('view-step-$stageId'));
  await tester.ensureVisible(eye);
  await tester.pumpAndSettle();
  await tester.tap(eye);
  await _waitFor(tester, find.byKey(ValueKey('feedback-step-$stageId')));
}

Future<void> _saveFeedback(WidgetTester tester) async {
  final save = find.byKey(const Key('feedback-save'));
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
}

void registerCandidateWorkflowTests() {
  late Directory directory;
  late _MemoryKeyStore keyStore;
  late LocalCandidateRepository repository;
  late SharedPreferences preferences;

  LocalCandidateRepository reopenRepository() => LocalCandidateRepository(
    directory: directory,
    cipher: AesGcmVaultCipher(keyStore),
  );

  setUp(() async {
    await windowManager.ensureInitialized();
    await windowManager.setSize(const Size(1400, 900));
    directory = await Directory.systemTemp.createTemp('people-integration-');
    keyStore = _MemoryKeyStore();
    repository = reopenRepository();
    final initial = RecruitingData.initial();
    await repository.saveCandidate(
      Candidate(
        id: 'integration-candidate',
        firstName: 'Ada',
        lastName: 'Lovelace',
        stageId: initial.stages.first.id,
        sourceId: initial.sources.first.id,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    SharedPreferences.setMockInitialValues({'app_locale': 'en'});
    preferences = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await directory.delete(recursive: true);
  });

  Future<void> startApp(
    WidgetTester tester, {
    ResumeTextExtractor? extractor,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authNotifierProvider.overrideWith(_SignedOutAuthNotifier.new),
          candidateRepositoryProvider.overrideWith((ref) async => repository),
          employmentReminderClockProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 11, 2)),
          ),
          if (extractor != null)
            resumeTextExtractorProvider.overrideWithValue(extractor),
        ],
        child: const PeopleApp(),
      ),
    );
    await _waitFor(tester, find.byKey(const Key('candidate-board-stages')));
  }

  testWidgets('attaches and replaces CV files for an existing candidate', (
    tester,
  ) async {
    final originalPicker = FilePickerPlatform.instance;
    final picker = TestFilePicker(directory: directory);
    FilePickerPlatform.instance = picker;
    addTearDown(() => FilePickerPlatform.instance = originalPicker);
    await startApp(tester, extractor: _TestResumeExtractor());
    for (final index in [1, 2]) {
      final bytes = utf8.encode('Private resume version $index');
      picker.selected = await File('${directory.path}/resume-$index.png')
          .writeAsBytes(bytes);
      await _openActions(tester);
      await tester.tap(find.text('Edit candidate'));
      await _waitFor(
        tester,
        find.text(index == 1 ? 'Import CV' : 'Replace CV'),
      );
      final importButton = find.text(index == 1 ? 'Import CV' : 'Replace CV');
      await tester.ensureVisible(importButton);
      await tester.pumpAndSettle();
      await tester.tap(importButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save candidate'));
      await tester.pumpAndSettle();
      final reopened = reopenRepository();
      expect(await reopened.readResume('integration-candidate'), bytes);
      expect(
        (await reopened.load()).candidates.single.cvFileName,
        'resume-$index.png',
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps personal details visible while opening and closing step notes',
    (tester) async {
      await startApp(tester);
      await tester.tap(find.text('Ada Lovelace'));
      await _waitFor(tester, find.byKey(const Key('candidate-profile')));
      expect(find.byKey(const Key('feedback-notes')), findsNothing);
      expect(find.byKey(const Key('toggle-candidate-profile')), findsNothing);
      final firstName = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'First name',
      );
      await tester.enterText(firstName, 'Grace');
      await _openStep(tester, 'new');
      expect(tester.widget<TextField>(firstName).controller!.text, 'Grace');
      expect(find.byKey(const Key('feedback-notes')), findsOneWidget);
      await tester.tap(find.byKey(const Key('close-step-notes')));
      await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
      expect(tester.widget<TextField>(firstName).controller!.text, 'Grace');
      await tester.tap(find.text('Save candidate'));
      await tester.pumpAndSettle();
      expect(
        (await reopenRepository().load()).candidates.single.firstName,
        'Grace',
      );
      expect(firstName, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('discards stage drafts before saving another stage', (
    tester,
  ) async {
    await repository.saveInterviewFeedback(
      'integration-candidate',
      stageId: 'new',
      decision: FeedbackDecision.pending,
      notes: 'Relevant CV.',
    );
    await repository.moveCandidate('integration-candidate', 'screening');
    await repository.saveInterviewFeedback(
      'integration-candidate',
      stageId: 'new',
      decision: FeedbackDecision.pending,
      notes: '',
    );
    await startApp(tester);
    await _openFeedback(tester);
    await tester.enterText(
      find.byKey(const Key('feedback-notes')),
      'Discard this interview draft.',
    );
    final previous = find.byKey(const Key('view-step-new'));
    await tester.ensureVisible(previous);
    await tester.tap(previous);
    await _waitFor(tester, find.text('Discard changes'));
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('feedback-notes')))
          .controller!
          .text,
      isEmpty,
    );
    await tester.enterText(
      find.byKey(const Key('feedback-notes')),
      'Updated CV review.',
    );
    await _saveFeedback(tester);
    await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
    final stored = (await reopenRepository().load()).candidates.single;
    expect(stored.latestFeedbackFor('new')!.notes, 'Updated CV review.');
    expect(stored.latestFeedbackFor('screening'), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'hires with a meeting plan and persists reviews and calendar export',
    (tester) async {
      var current = 'new';
      for (final next in ['screening', 'technical', 'final', 'offer']) {
        await repository.saveInterviewFeedback(
          'integration-candidate',
          stageId: current,
          decision: current == 'new'
              ? FeedbackDecision.pending
              : FeedbackDecision.positive,
          notes: 'Proceed.',
          scheduledAt: current == 'new' ? null : DateTime.utc(2026, 11, 12, 14),
          interviewer: 'Interview owner',
          feedbackSharedWithCandidate: true,
        );
        await repository.moveCandidate('integration-candidate', next);
        current = next;
      }
      await repository.saveOffer(
        'integration-candidate',
        CandidateOffer(
          status: OfferStatus.accepted,
          proposedStartDate: DateTime(2026, 1, 31),
        ),
      );
      final originalPicker = FilePickerPlatform.instance;
      final picker = TestFilePicker(directory: directory);
      FilePickerPlatform.instance = picker;
      addTearDown(() => FilePickerPlatform.instance = originalPicker);
      await startApp(tester);
      await _openActions(tester);
      await tester.tap(find.text('Move to stage'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('candidate-move-hired')));
      await _waitFor(tester, find.byKey(const Key('employment-plan-save')));
      for (final milestone in EmploymentPlan.milestones) {
        expect(
          find.byKey(ValueKey('employment-meeting-$milestone')),
          findsOneWidget,
        );
      }
      final exportOption = find.byKey(const Key('employment-save-export'));
      await tester.ensureVisible(exportOption);
      await tester.pumpAndSettle();
      await tester.tap(exportOption);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('employment-plan-save')));
      await _waitUntilGone(
        tester,
        find.byKey(const Key('employment-plan-save')),
      );
      final employee = (await reopenRepository().load()).hiredPeople.single;
      final hiringCalendar = await picker.exported!.readAsString();
      expect(hiringCalendar, contains('DTSTART:20260228T150000'));
      expect('DURATION:PT1H'.allMatches(hiringCalendar), hasLength(4));
      expect(
        find.byKey(const Key('employment-reminders-open')),
        findsOneWidget,
      );
      expect(employee.employmentPlan!.hiredAt, DateTime(2026, 1, 31));
      expect(
        employee.employmentPlan!.followUps.first.scheduledAt,
        DateTime(2026, 2, 28, 15),
      );
      await tester.tap(find.byKey(const Key('navigation-hired-people')));
      await _waitFor(
        tester,
        find.byKey(const Key('hired-person-integration-candidate')),
      );
      await tester.tap(
        find.byKey(const Key('hired-person-integration-candidate')),
      );
      await _waitFor(tester, find.byKey(const Key('employee-add-review')));
      await tester.tap(find.byKey(const Key('employee-add-review')));
      await _waitFor(tester, find.byKey(const Key('employee-review-title')));
      await tester.enterText(
        find.byKey(const Key('employee-review-title')),
        'First month review',
      );
      await tester.enterText(
        find.byKey(const Key('employee-review-reviewer')),
        'Team manager',
      );
      await tester.enterText(
        find.byKey(const Key('employee-review-notes')),
        'Strong onboarding progress.',
      );
      await tester.enterText(
        find.byKey(const Key('employee-review-goals')),
        'Lead the next delivery.',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('employee-review-save')));
      await _waitUntilGone(
        tester,
        find.byKey(const Key('employee-review-save')),
      );
      var stored = (await reopenRepository().load()).hiredPeople.single;
      expect(stored.reviews.single.notes, 'Strong onboarding progress.');
      final reviewId = stored.reviews.single.id;
      final reviewCard = find.byKey(ValueKey('employee-review-$reviewId'));
      await tester.ensureVisible(reviewCard);
      await tester.pumpAndSettle();
      await tester.tap(reviewCard);
      await tester.pumpAndSettle();
      final edit = find.byKey(ValueKey('employee-review-edit-$reviewId'));
      await tester.ensureVisible(edit);
      await tester.pumpAndSettle();
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('employee-review-notes')),
        'Updated review discussion.',
      );
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await _waitFor(tester, find.text('Keep editing'));
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('employee-review-notes')))
            .controller!
            .text,
        'Updated review discussion.',
      );
      await tester.tap(find.byKey(const Key('employee-review-save')));
      await _waitUntilGone(
        tester,
        find.byKey(const Key('employee-review-save')),
      );
      stored = (await reopenRepository().load()).hiredPeople.single;
      expect(stored.reviews, hasLength(1));
      expect(stored.reviews.single.notes, 'Updated review discussion.');
      await tester.tap(find.byKey(const Key('employee-export-calendar')));
      await _waitFor(
        tester,
        find.byKey(const Key('employment-calendar-saved')),
      );
      final calendar = await picker.exported!.readAsString();
      expect('BEGIN:VEVENT'.allMatches(calendar), hasLength(4));
      expect(calendar, contains('DTSTART:20260228T150000'));
      expect(calendar, contains('TRIGGER:-P1D'));
      expect(calendar, contains('TRIGGER:-PT15M'));
      await tester.tap(find.byKey(const Key('employee-meeting-plan')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('employment-completed-1')));
      await tester.tap(find.byKey(const Key('employment-meeting-3')));
      await tester.pumpAndSettle();
      final material = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      await tester.tap(find.byTooltip(material.inputDateModeButtonLabel));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.byType(TextField),
        ),
        '05/04/2026',
      );
      await tester.tap(find.text(material.okButtonLabel));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.text(material.okButtonLabel));
      await tester.pumpAndSettle();
      picker.cancelSave = true;
      await tester.ensureVisible(exportOption);
      await tester.pumpAndSettle();
      await tester.tap(exportOption);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('employment-plan-save')));
      await _waitUntilGone(
        tester,
        find.byKey(const Key('employment-plan-save')),
      );
      expect(
        (await reopenRepository().load())
            .hiredPeople
            .single
            .employmentPlan!
            .followUps
            .first
            .completed,
        isTrue,
      );
      expect(
        (await reopenRepository().load())
            .hiredPeople
            .single
            .employmentPlan!
            .followUps[1]
            .scheduledAt,
        DateTime(2026, 5, 4, 15),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saves interview feedback and progresses without scheduling or an author',
    (tester) async {
      await repository.saveInterviewFeedback(
        'integration-candidate',
        stageId: 'new',
        decision: FeedbackDecision.pending,
        notes: 'Relevant CV.',
      );
      await repository.moveCandidate('integration-candidate', 'screening');
      await startApp(tester);
      for (final (stage, next) in [
        ('screening', 'technical'),
        ('technical', 'final'),
        ('final', 'offer'),
      ]) {
        await _openFeedback(tester);
        await tester.enterText(
          find.byKey(const Key('feedback-notes')),
          'Strong interview.',
        );
        await tester.tap(find.byKey(const Key('feedback-decision-positive')));
        await tester.pumpAndSettle();
        await _saveFeedback(tester);
        await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
        var stored = (await reopenRepository().load()).candidates.single
            .latestFeedbackFor(stage)!;
        expect(stored.scheduledAt, isNull);
        expect(stored.interviewer, isEmpty);
        expect(stored.decision, FeedbackDecision.positive);
        expect(stored.notes, 'Strong interview.');
        await _openFeedback(tester);
        await tester.enterText(
          find.byKey(const Key('feedback-notes')),
          'Strong interview. Updated after saving.',
        );
        await tester.tap(find.byKey(const Key('feedback-decision-positive')));
        await tester.pumpAndSettle();
        await _saveFeedback(tester);
        await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
        expect(find.text('Candidate feedback pending'), findsWidgets);
        final communication = find.byKey(ValueKey('feedback-shared-$stage'));
        await tester.ensureVisible(communication);
        await tester.tap(communication);
        await tester.pumpAndSettle();
        final advance = find.byKey(ValueKey('selection-advance-$next'));
        await tester.ensureVisible(advance);
        await tester.tap(advance);
        await tester.pumpAndSettle();
        stored = (await reopenRepository().load()).candidates.single
            .latestFeedbackFor(stage)!;
        expect(stored.feedbackSharedWithCandidate, isTrue);
        expect(stored.scheduledAt, isNull);
        expect(stored.interviewer, isEmpty);
        expect(
          (await reopenRepository().load()).candidates.single.stageId,
          next,
        );
      }
      final previous = find.byKey(const Key('view-step-screening'));
      await tester.ensureVisible(previous);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(ExpansionTile), findsNothing);
      expect(
        find.byKey(const Key('feedback-readonly-screening')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('feedback-notes')), findsNothing);
      await tester.tap(find.byKey(const Key('selection-edit-step')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('feedback-notes')),
        'Updated previous interview feedback.',
      );
      await _saveFeedback(tester);
      await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
      final reopened = (await reopenRepository().load()).candidates.single;
      expect(reopened.stageId, 'offer');
      expect(
        reopened.latestFeedbackFor('screening')!.notes,
        'Updated previous interview feedback.',
      );
      expect(
        reopened.latestFeedbackFor('technical')!.notes,
        'Strong interview. Updated after saving.',
      );
      await tester.tap(find.byKey(const Key('view-step-offer')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('feedback-step-offer')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('opens long step feedback by clicking the pipeline label', (
    tester,
  ) async {
    final notes = List.generate(
      80,
      (index) =>
          'Observation $index: clear reasoning and detailed interview feedback.',
    ).join('\n');
    await repository.saveInterviewFeedback(
      'integration-candidate',
      stageId: 'new',
      decision: FeedbackDecision.pending,
      notes: notes,
    );
    await repository.moveCandidate('integration-candidate', 'screening');
    await repository.saveInterviewFeedback(
      'integration-candidate',
      stageId: 'screening',
      decision: FeedbackDecision.pending,
      notes: 'Current step notes.',
    );
    await startApp(tester);
    await _openActions(tester);
    await tester.tap(find.text('Interview & feedback'));
    await _waitFor(tester, find.byKey(const Key('candidate-profile')));
    expect(find.byKey(const Key('feedback-readonly-screening')), findsNothing);
    expect(find.byKey(const Key('view-step-screening')), findsOneWidget);
    final eye = find.byKey(const Key('view-step-new'));
    await tester.ensureVisible(eye);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(eye));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('step-feedback-preview')), findsNothing);
    expect(find.text(notes), findsNothing);
    expect(
      find.descendant(
        of: eye,
        matching: find.byIcon(Icons.visibility_outlined),
      ),
      findsNothing,
    );
    await tester.tap(
      find.descendant(of: eye, matching: find.text('CV review')),
    );
    await _waitFor(tester, find.byKey(const Key('feedback-readonly-new')));
    expect(find.byKey(const Key('candidate-profile')), findsOneWidget);
    expect(find.byKey(const Key('view-step-new')), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    expect(
      (await reopenRepository().load()).candidates.single.stageId,
      'screening',
    );
    await _openStep(tester, 'screening');
    await _waitFor(
      tester,
      find.byKey(const Key('feedback-readonly-screening')),
    );
    expect(find.byKey(const Key('view-step-screening')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'shows compact pipeline dates from persisted interview and offer events',
    (tester) async {
      final cvDate = DateTime.utc(2026, 1, 3, 12);
      final offerDate = DateTime.utc(2026, 1, 20, 12);
      await repository.saveInterviewFeedback(
        'integration-candidate',
        stageId: 'new',
        decision: FeedbackDecision.pending,
        notes: 'Reviewed CV.',
        recordedAt: cvDate,
      );
      await repository.moveCandidate('integration-candidate', 'screening');
      for (final (stage, next, day) in [
        ('screening', 'technical', 8),
        ('technical', 'final', 10),
        ('final', 'offer', 12),
      ]) {
        await repository.saveInterviewFeedback(
          'integration-candidate',
          stageId: stage,
          decision: FeedbackDecision.positive,
          notes: 'Proceed.',
          scheduledAt: DateTime(2026, 1, day, 14),
          recordedAt: DateTime.utc(2026, 1, 15, 12),
          feedbackSharedWithCandidate: true,
        );
        await repository.moveCandidate('integration-candidate', next);
      }
      await repository.saveOffer(
        'integration-candidate',
        CandidateOffer(
          status: OfferStatus.sent,
          proposedStartDate: DateTime(2026, 6, 1),
          recordedAt: offerDate,
        ),
      );
      expect(
        (await reopenRepository().load()).candidates.single.offer!.recordedAt,
        offerDate,
      );
      await startApp(tester);
      await _openActions(tester, openMenu: false);
      await tester.tap(find.text('Ada Lovelace'));
      await _waitFor(tester, find.byKey(const Key('candidate-profile')));
      for (final (stage, date) in [
        ('new', cvDate),
        ('screening', DateTime(2026, 1, 8)),
        ('technical', DateTime(2026, 1, 10)),
        ('final', DateTime(2026, 1, 12)),
        ('offer', offerDate),
      ]) {
        final caption = find.byKey(ValueKey('pipeline-date-$stage'));
        final formatted = MaterialLocalizations.of(tester.element(caption))
            .formatShortDate(date.toLocal());
        expect(
          find.descendant(of: caption, matching: find.text(formatted)),
          findsOneWidget,
        );
      }
      expect(find.byKey(const Key('feedback-notes')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('updates half-star ratings and persists the candidate summary', (
    tester,
  ) async {
    await startApp(tester);
    await _openActions(tester);
    await tester.tap(find.text('Interview & feedback'));
    await _waitFor(tester, find.byKey(const Key('candidate-profile')));
    expect(find.byKey(const Key('feedback-notes')), findsNothing);
    expect(find.text('CURRENT STEP'), findsNothing);
    expect(find.byKey(const Key('pipeline-outcome-pending')), findsOneWidget);
    final technical = find.byKey(const Key('candidate-rating-technicalSkills'));
    await tester.ensureVisible(technical);
    await tester.pumpAndSettle();
    final ratings = find.byKey(const Key('candidate-ratings-card'));
    final rail = find.byKey(const Key('candidate-overview-scrollbar'));
    expect(
      tester.getRect(ratings).right,
      lessThanOrEqualTo(tester.getRect(rail).right - 12),
    );
    await tester.tapAt(tester.getTopLeft(technical) + const Offset(110, 13));
    await tester.pumpAndSettle();
    expect(
      (await reopenRepository().load()).candidates.single.ratings[RatingAspect
          .technicalSkills],
      4.5,
    );
    expect(find.text('4.5 / 5'), findsOneWidget);
    expect(find.text('1 of 5 criteria rated'), findsOneWidget);
    final communication = find.byKey(
      const Key('candidate-rating-communication'),
    );
    await tester.ensureVisible(communication);
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getTopLeft(communication) + const Offset(71, 13));
    await tester.pumpAndSettle();
    final stored = (await reopenRepository().load()).candidates.single;
    expect(stored.ratings[RatingAspect.technicalSkills], 4.5);
    expect(stored.ratings[RatingAspect.communication], 3);
    expect(find.text('3.8 / 5'), findsOneWidget);
    expect(find.text('2 of 5 criteria rated'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('edits long feedback and persists one record per stage', (
    tester,
  ) async {
    await startApp(tester);
    await _openFeedback(tester);
    final notes = List.generate(
      60,
      (index) =>
          'Observation $index: clear reasoning and thoughtful trade-offs.',
    ).join('\n');
    await tester.enterText(find.byKey(const Key('feedback-notes')), notes);

    await tester.pumpAndSettle();
    await _saveFeedback(tester);
    await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
    await _waitFor(
      tester,
      find.byKey(const Key('candidate-actions-integration-candidate')),
    );
    expect(find.byKey(const Key('feedback-notes')), findsNothing);

    await _openFeedback(tester);
    final field = tester.widget<TextField>(
      find.byKey(const Key('feedback-notes')),
    );
    expect(field.controller!.text, notes);
    final editedNotes = '$notes\nUpdated after the follow-up discussion.';
    await tester.enterText(
      find.byKey(const Key('feedback-notes')),
      editedNotes,
    );

    await tester.pumpAndSettle();
    await _saveFeedback(tester);
    await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
    await _waitFor(
      tester,
      find.byKey(const Key('candidate-actions-integration-candidate')),
    );

    final stored = (await reopenRepository().load()).candidates.single;
    expect(stored.interviews, hasLength(1));
    expect(stored.interviews.single.notes, editedNotes);
    expect(stored.interviews.single.decision, FeedbackDecision.pending);

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byKey(const Key('selection-history')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('selection-edit-step')));
    await tester.tap(find.byKey(const Key('selection-edit-step')));
    await _waitFor(tester, find.byKey(const Key('feedback-notes')));
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('feedback-notes')))
          .controller!
          .text,
      editedNotes,
    );
    final detailNotes = '$editedNotes\nSaved from the candidate record.';
    await tester.enterText(
      find.byKey(const Key('feedback-notes')),
      detailNotes,
    );
    await tester.pumpAndSettle();
    await _saveFeedback(tester);
    await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
    final success = find.byKey(const Key('feedback-save-success'));
    expect(success, findsOneWidget);
    await tester.ensureVisible(success);
    await tester.pumpAndSettle();
    expect(success.hitTestable(), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    final reopened = (await reopenRepository().load()).candidates.single;
    expect(reopened.interviews, hasLength(1));
    expect(reopened.interviews.single.notes, detailNotes);
    expect(tester.takeException(), isNull);
  });

  testWidgets('protects unsaved notes and explains blocked stage transitions', (
    tester,
  ) async {
    await startApp(tester);
    await _openFeedback(tester);
    await tester.enterText(
      find.byKey(const Key('feedback-notes')),
      'These notes have not been saved.',
    );
    await tester.tap(find.byKey(const Key('candidate-details-close')));
    await _waitFor(tester, find.text('Unsaved changes'));
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('feedback-notes')))
          .controller!
          .text,
      'These notes have not been saved.',
    );
    await tester.tap(find.byKey(const Key('candidate-details-close')));
    await _waitFor(tester, find.text('Discard changes'));
    await tester.tap(find.text('Discard changes'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('feedback-notes')), findsNothing);
    expect(
      (await reopenRepository().load()).candidates.single.interviews,
      isEmpty,
    );

    await _openActions(tester);
    expect(find.text('Move to stage'), findsNothing);
    expect((await reopenRepository().load()).candidates.single.stageId, 'new');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keeps navigation and feedback usable in a small desktop window',
    (tester) async {
      await windowManager.setSize(const Size(900, 650));
      await startApp(tester);
      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).extended,
        isFalse,
      );
      await _openFeedback(tester);
      await windowManager.setSize(const Size(700, 500));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('feedback-notes')),
        'A draft written in a small desktop window.',
      );
      final save = find.byKey(const Key('feedback-save'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
      await _waitFor(
        tester,
        find.byKey(const Key('candidate-actions-integration-candidate')),
      );
      expect(
        (await reopenRepository().load())
            .candidates
            .single
            .interviews
            .single
            .notes,
        'A draft written in a small desktop window.',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
