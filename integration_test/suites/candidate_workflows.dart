import 'dart:io';
import 'dart:convert';

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

Future<void> _openActions(WidgetTester tester) async {
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
  await tester.tap(actions);
  await tester.pumpAndSettle();
}

Future<void> _openFeedback(WidgetTester tester) async {
  await _openActions(tester);
  await tester.tap(find.text('Interview & feedback'));
  await _waitFor(tester, find.byKey(const Key('feedback-notes')));
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

  testWidgets('protects profile drafts while hiding personal details', (
    tester,
  ) async {
    await startApp(tester);
    await tester.tap(find.text('Ada Lovelace'));
    await _waitFor(tester, find.byKey(const Key('toggle-candidate-profile')));
    await tester.tap(find.byKey(const Key('toggle-candidate-profile')));
    await tester.pumpAndSettle();
    final firstName = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'First name',
    );
    await tester.enterText(firstName, 'Grace');
    await tester.tap(find.byKey(const Key('toggle-candidate-profile')));
    await _waitFor(tester, find.text('Keep editing'));
    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(firstName).controller!.text, 'Grace');
    await tester.tap(find.text('Save candidate'));
    await tester.pumpAndSettle();
    expect(
      (await reopenRepository().load()).candidates.single.firstName,
      'Grace',
    );
    await tester.tap(find.byKey(const Key('toggle-candidate-profile')));
    await tester.pumpAndSettle();
    expect(firstName, findsNothing);
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
    'schedules every interview and tracks candidate communication before progression',
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
          find.byKey(const Key('interview-interviewer')),
          'Owner for $stage',
        );
        await tester.tap(find.byKey(const Key('interview-schedule')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('feedback-save')));
        await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
        var stored = (await reopenRepository().load()).candidates.single
            .latestFeedbackFor(stage)!;
        expect(stored.scheduledAt, isNotNull);
        expect(stored.interviewer, 'Owner for $stage');
        expect(stored.decision, FeedbackDecision.pending);
        await _openFeedback(tester);
        await tester.enterText(
          find.byKey(const Key('feedback-notes')),
          'Strong interview.',
        );
        await tester.tap(find.byKey(const Key('feedback-decision-positive')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('feedback-save')));
        await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
        expect(find.text('Candidate feedback pending'), findsWidgets);
        await _openActions(tester);
        expect(find.text('Move to stage'), findsNothing);
        await tester.tap(find.text('Interview & feedback'));
        await _waitFor(
          tester,
          find.byKey(const Key('feedback-shared-with-candidate')),
        );
        await tester.tap(
          find.byKey(const Key('feedback-shared-with-candidate')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('feedback-save')));
        await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
        await _openActions(tester);
        await tester.tap(find.text('Move to stage'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(ValueKey('candidate-move-$next')));
        await tester.pumpAndSettle();
        stored = (await reopenRepository().load()).candidates.single
            .latestFeedbackFor(stage)!;
        expect(stored.feedbackSharedWithCandidate, isTrue);
        expect(
          (await reopenRepository().load()).candidates.single.stageId,
          next,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );

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
    await tester.tap(find.byKey(const Key('feedback-save')));
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
    await tester.tap(find.byKey(const Key('feedback-save')));
    await _waitUntilGone(tester, find.byKey(const Key('feedback-notes')));
    await _waitFor(
      tester,
      find.byKey(const Key('candidate-actions-integration-candidate')),
    );

    final stored = (await reopenRepository().load()).candidates.single;
    expect(stored.interviews, hasLength(1));
    expect(stored.interviews.single.notes, editedNotes);
    expect(stored.interviews.single.decision, FeedbackDecision.pending);

    final candidateName = find.text('Ada Lovelace');
    await tester.ensureVisible(candidateName);
    await tester.pumpAndSettle();
    await tester.tap(candidateName);
    await _waitFor(tester, find.byKey(const Key('feedback-step-new')));
    await tester.tap(find.byKey(const Key('selection-edit-step')));
    await _waitFor(tester, find.byKey(const Key('feedback-notes')));
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('feedback-notes')))
          .controller!
          .text,
      editedNotes,
    );
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
    await tester.tap(find.byKey(const Key('feedback-close')));
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
    await tester.tap(find.byKey(const Key('feedback-close')));
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
