import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/data/datasources/encrypted_vault.dart';
import 'package:people/features/candidate_management/data/models/recruiting_data_model.dart';
import 'package:people/features/candidate_management/data/repositories/local_candidate_repository.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
import 'package:people/features/candidate_management/domain/entities/employment_plan.dart';
import 'package:people/features/candidate_management/domain/failures/candidate_repository_exception.dart';

void main() {
  late Directory temporaryDirectory;
  late Directory vaultDirectory;
  late _MemoryVaultKeyStore keyStore;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'people-candidate-vault-test-',
    );
    vaultDirectory = Directory('${temporaryDirectory.path}\\vault');
    keyStore = _MemoryVaultKeyStore();
  });

  LocalCandidateRepository createRepository() => LocalCandidateRepository(
    directory: vaultDirectory,
    cipher: AesGcmVaultCipher(keyStore),
  );

  tearDown(() async {
    await temporaryDirectory.delete(recursive: true);
  });

  test(
    'stores candidate data and resume encrypted across repository instances',
    () async {
      final repository = createRepository();
      final candidate = _candidate('candidate-1');
      final resume = utf8.encode('Private candidate resume');
      final savedCandidate = await repository.saveCandidate(
        candidate,
        cvBytes: resume,
      );
      await repository.saveFavorite(
        FavoriteTalent(
          id: 'octocat',
          username: 'octocat',
          profileUrl: 'https://github.com/octocat',
          avatarUrl: 'https://example.com/octocat.png',
          savedAt: DateTime.utc(2026),
        ),
      );

      final vaultBytes = await File('${vaultDirectory.path}\\recruiting.vault')
          .readAsBytes();
      final resumeBytes = await File(
        '${vaultDirectory.path}\\${savedCandidate.cvStorageKey}.cv.enc',
      ).readAsBytes();
      expect(
        utf8.decode(vaultBytes, allowMalformed: true),
        isNot(contains('Private candidate resume')),
      );
      expect(
        utf8.decode(resumeBytes, allowMalformed: true),
        isNot(contains('Private candidate resume')),
      );

      final reopened = createRepository();
      final loaded = await reopened.load();
      expect(loaded.candidates.single.firstName, 'Ada');
      expect(await reopened.readResume(candidate.id), resume);
      expect(loaded.favorites.single.username, 'octocat');
    },
  );

  test(
    'completes interviews only after a decision and candidate communication',
    () async {
      final repository = createRepository();
      final candidate = _candidate('workflow');
      await repository.saveCandidate(candidate);
      await expectLater(
        repository.moveCandidate(candidate.id, 'screening'),
        throwsA(isA<CandidateRepositoryException>()),
      );
      await repository.saveInterviewFeedback(
        candidate.id,
        stageId: 'new',
        decision: FeedbackDecision.pending,
        notes: 'Relevant CV.',
      );
      await repository.moveCandidate(candidate.id, 'screening');
      for (final (stage, next) in [
        ('screening', 'technical'),
        ('technical', 'final'),
        ('final', 'offer'),
      ]) {
        await repository.saveInterviewFeedback(
          candidate.id,
          stageId: stage,
          decision: FeedbackDecision.pending,
          notes: '',
          scheduledAt: DateTime.utc(2026, 11, 12, 14),
          interviewer: 'Technical owner',
        );
        await expectLater(
          repository.moveCandidate(candidate.id, next),
          throwsA(isA<CandidateRepositoryException>()),
        );
        await repository.saveInterviewFeedback(
          candidate.id,
          stageId: stage,
          decision: FeedbackDecision.positive,
          notes: 'Proceed.',
        );
        await expectLater(
          repository.moveCandidate(candidate.id, next),
          throwsA(isA<CandidateRepositoryException>()),
        );
        await repository.saveInterviewFeedback(
          candidate.id,
          stageId: stage,
          decision: FeedbackDecision.positive,
          notes: 'Proceed.',
          feedbackSharedWithCandidate: true,
        );
        await repository.moveCandidate(candidate.id, next);
      }
      await expectLater(
        repository.moveCandidate(candidate.id, 'hired'),
        throwsA(isA<CandidateRepositoryException>()),
      );
      await repository.saveOffer(
        candidate.id,
        const CandidateOffer(status: OfferStatus.accepted),
      );
      await repository.moveCandidate(candidate.id, 'hired');
      final reopened = (await createRepository().load()).candidates.single;
      expect(reopened.stageId, 'hired');
      expect(
        reopened.interviews
            .where((record) => record.stageId != 'new')
            .every(
              (record) =>
                  record.feedbackSharedWithCandidate &&
                  record.interviewer == 'Technical owner' &&
                  record.scheduledAt == DateTime.utc(2026, 11, 12, 14),
            ),
        isTrue,
      );
      final plan = EmploymentPlan.propose(DateTime(2026, 1, 31));
      await repository.saveEmploymentPlan(candidate.id, plan);
      final review = EmployeeReview(
        id: 'review-1',
        reviewedAt: DateTime.utc(2026, 3),
        title: ' First review ',
        reviewer: ' Manager ',
        notes: ' Strong start ',
        goals: ' Own a project ',
      );
      await repository.saveEmployeeReview(candidate.id, review);
      await repository.saveEmployeeReview(
        candidate.id,
        EmployeeReview(
          id: review.id,
          reviewedAt: review.reviewedAt,
          title: review.title,
          reviewer: review.reviewer,
          notes: 'Updated discussion',
          goals: review.goals,
        ),
      );
      final stale = reopened.copyWith(firstName: 'Grace');
      await repository.saveCandidate(stale);
      final employee = (await createRepository().load()).hiredPeople.single;
      expect(employee.firstName, 'Grace');
      expect(employee.reviews, hasLength(1));
      expect(employee.reviews.single.notes, 'Updated discussion');
      expect(employee.reviews.single.reviewer, 'Manager');
      expect(employee.employmentPlan!.hiredAt, plan.hiredAt);
      expect(
        employee.employmentPlan!.followUps.first.scheduledAt,
        DateTime(2026, 2, 28, 15),
      );
      await expectLater(
        repository.saveEmployeeReview(
          candidate.id,
          EmployeeReview(
            id: 'bad',
            reviewedAt: DateTime(2026),
            title: '',
            reviewer: 'Manager',
            notes: 'Notes',
          ),
        ),
        throwsA(isA<CandidateRepositoryException>()),
      );
      await expectLater(
        repository.saveEmploymentPlan(
          candidate.id,
          EmploymentPlan(hiredAt: DateTime(2026), followUps: const []),
        ),
        throwsA(isA<CandidateRepositoryException>()),
      );
    },
  );

  test(
    'stores one candidate rating and migrates legacy interview ratings',
    () async {
      final repository = createRepository();
      final candidate = _candidate('candidate-ratings');
      await repository.saveCandidate(candidate);
      await expectLater(
        repository.saveEmployeeReview(
          candidate.id,
          EmployeeReview(
            id: 'review',
            reviewedAt: DateTime(2026),
            title: 'Review',
            reviewer: 'Manager',
            notes: 'Notes',
          ),
        ),
        throwsA(
          isA<CandidateRepositoryException>().having(
            (error) => error.code,
            'code',
            'hired_candidate_required',
          ),
        ),
      );
      await expectLater(
        repository.saveEmploymentPlan(
          candidate.id,
          EmploymentPlan.propose(DateTime(2026)),
        ),
        throwsA(isA<CandidateRepositoryException>()),
      );
      await repository.saveCandidate(
        candidate.copyWith(
          ratings: const {
            RatingAspect.technicalSkills: 4.5,
            RatingAspect.communication: 3,
          },
        ),
      );
      await expectLater(
        repository.saveCandidate(
          candidate.copyWith(ratings: const {RatingAspect.teamFit: 3.2}),
        ),
        throwsA(isA<CandidateRepositoryException>()),
      );
      final loaded = (await repository.load()).candidates.single;
      expect(loaded.ratings[RatingAspect.technicalSkills], 4.5);
      expect(loaded.averageRating, 3.75);

      final legacy = RecruitingDataModel.decode(
        jsonDecode(
          jsonEncode(
            RecruitingDataModel.encode(
              RecruitingData(
                candidates: [candidate],
                sources: RecruitingData.initial().sources,
                stages: RecruitingData.initial().stages,
              ),
            ),
          ),
        ) as Map<String, Object?>,
      );
      expect(legacy.candidates.single.ratings, isEmpty);
    },
  );

  test(
    'migrates an old pipeline once and resets candidates to CV review',
    () async {
      final repository = createRepository();
      final candidate = _candidate('migration');
      final base = RecruitingDataModel.encode(
        RecruitingData.initial().copyWith(
          candidates: [candidate.copyWith(stageId: 'technical')],
        ),
      );
      base['version'] = 1;
      final migrated = RecruitingDataModel.decode(base);
      expect(migrated.candidates.single.stageId, 'new');
      expect(migrated.candidates.single.interviews, isEmpty);
      expect(migrated.stages.map((stage) => stage.id), [
        'new',
        'screening',
        'technical',
        'final',
        'offer',
        'hired',
        'rejected',
      ]);
      await vaultDirectory.create(recursive: true);
      await File('${vaultDirectory.path}\\recruiting.vault').writeAsBytes(
        await AesGcmVaultCipher(keyStore)
            .encrypt(utf8.encode(jsonEncode(base))),
      );
      await repository.load();
      await repository.saveInterviewFeedback(
        candidate.id,
        stageId: 'new',
        decision: FeedbackDecision.pending,
        notes: 'Reviewed.',
      );
      await repository.moveCandidate(candidate.id, 'screening');
      expect(
        (await createRepository().load()).candidates.single.stageId,
        'screening',
      );
    },
  );

  test('rejects only after negative feedback is communicated', () async {
    final repository = createRepository();
    final candidate = _candidate('reject');
    await repository.saveCandidate(candidate);
    await repository.saveInterviewFeedback(
      candidate.id,
      stageId: 'new',
      decision: FeedbackDecision.pending,
      notes: 'Reviewed.',
    );
    await repository.moveCandidate(candidate.id, 'screening');
    await repository.saveInterviewFeedback(
      candidate.id,
      stageId: 'screening',
      decision: FeedbackDecision.negative,
      notes: 'Role mismatch.',
      scheduledAt: DateTime.utc(2026),
      interviewer: 'Recruiter',
    );
    await expectLater(
      repository.moveCandidate(candidate.id, 'rejected'),
      throwsA(isA<CandidateRepositoryException>()),
    );
    await repository.saveInterviewFeedback(
      candidate.id,
      stageId: 'screening',
      decision: FeedbackDecision.negative,
      notes: 'Role mismatch.',
      feedbackSharedWithCandidate: true,
    );
    await repository.moveCandidate(candidate.id, 'rejected');
    expect(
      (await createRepository().load()).candidates.single.stageId,
      'rejected',
    );
  });

  test('does not accept feedback for the first step', () async {
    final repository = createRepository();
    final candidate = _candidate('candidate-first');
    await repository.saveCandidate(candidate);
    await expectLater(
      repository.saveInterviewFeedback(
        candidate.id,
        stageId: 'new',
        decision: FeedbackDecision.positive,
        notes: '',
      ),
      throwsA(isA<CandidateRepositoryException>()),
    );
  });

  test('keeps pipeline stage and old resume rules when editing', () async {
    final repository = createRepository();
    final candidate = _candidate('candidate-3');
    final created = await repository.saveCandidate(
      candidate.copyWith(stageId: 'missing-stage'),
      cvBytes: utf8.encode('first'),
    );
    expect(created.stageId, 'new');
    await repository.saveInterviewFeedback(
      candidate.id,
      stageId: 'new',
      decision: FeedbackDecision.pending,
      notes: 'Reviewed.',
    );
    await repository.moveCandidate(candidate.id, 'screening');
    final edited = await repository.saveCandidate(
      created.copyWith(stageId: 'new', firstName: 'Grace'),
      cvBytes: utf8.encode('second'),
    );

    expect(edited.stageId, 'screening');
    expect(edited.cvStorageKey, isNot(created.cvStorageKey));
    expect(
      File('${vaultDirectory.path}\\${created.cvStorageKey}.cv.enc')
          .existsSync(),
      isFalse,
    );
    expect(await repository.readResume(candidate.id), utf8.encode('second'));
  });
}

Candidate _candidate(String id) {
  final now = DateTime.utc(2026);
  return Candidate(
    id: id,
    firstName: 'Ada',
    lastName: 'Lovelace',
    stageId: 'new',
    sourceId: 'grafton',
    createdAt: now,
    updatedAt: now,
  );
}

class _MemoryVaultKeyStore implements VaultKeyStore {
  List<int>? _key;

  @override
  Future<List<int>?> readKey() async => _key == null ? null : [..._key!];

  @override
  Future<void> writeKey(List<int> value) async => _key = [...value];
}
