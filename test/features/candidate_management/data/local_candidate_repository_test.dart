import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/data/datasources/encrypted_vault.dart';
import 'package:people/features/candidate_management/data/models/recruiting_data_model.dart';
import 'package:people/features/candidate_management/data/repositories/local_candidate_repository.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';
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
    'requires a positive decision to advance and a negative decision to reject',
    () async {
      final repository = createRepository();
      final candidate = _candidate('candidate-2');
      await repository.saveCandidate(candidate);
      await repository.moveCandidate(candidate.id, 'cv_review');

      await expectLater(
        repository.moveCandidate(candidate.id, 'screening'),
        throwsA(
          isA<CandidateRepositoryException>().having(
            (error) => error.code,
            'code',
            'positive_feedback_required',
          ),
        ),
      );

      await repository.saveInterviewFeedback(
        candidate.id,
        stageId: 'cv_review',
        decision: FeedbackDecision.negative,
        notes: 'Not a match for this role.',
      );
      await expectLater(
        repository.moveCandidate(candidate.id, 'screening'),
        throwsA(
          isA<CandidateRepositoryException>().having(
            (error) => error.code,
            'code',
            'positive_feedback_required',
          ),
        ),
      );
      await repository.moveCandidate(candidate.id, 'rejected');
      expect((await repository.load()).candidates.single.stageId, 'rejected');
    },
  );

  test(
    'allows hiring only after accepted offer and positive final feedback',
    () async {
      final repository = createRepository();
      final candidate = _candidate('candidate-3');
      await repository.saveCandidate(candidate);
      var currentStage = 'new';
      const activeStages = <String>[
        'new',
        'cv_review',
        'screening',
        'technical',
        'final',
        'offer',
      ];

      for (final nextStage in activeStages.skip(1)) {
        if (currentStage != 'new') {
          await repository.saveInterviewFeedback(
            candidate.id,
            stageId: currentStage,
            decision: FeedbackDecision.positive,
            notes: 'Proceed to the next step.',
          );
        }
        await repository.moveCandidate(candidate.id, nextStage);
        currentStage = nextStage;
      }

      await repository.saveOffer(
        candidate.id,
        const CandidateOffer(status: OfferStatus.accepted),
      );
      await repository.saveInterviewFeedback(
        candidate.id,
        stageId: 'offer',
        decision: FeedbackDecision.positive,
        notes: 'Offer accepted.',
      );
      await repository.moveCandidate(candidate.id, 'hired');
      final loaded = await repository.load();
      expect(loaded.candidates.single.stageId, 'hired');
      expect(loaded.candidates.single.offer?.status, OfferStatus.accepted);
    },
  );

  test(
    'stores one candidate rating and migrates legacy interview ratings',
    () async {
      final repository = createRepository();
      final candidate = _candidate('candidate-ratings');
      await repository.saveCandidate(candidate);
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
      final legacyJson = <String, Object?>{
        ...RecruitingDataModel.encode(legacy),
        'candidates': [
          {
            ...(RecruitingDataModel.encode(legacy)['candidates']! as List)
                    .single
                as Map<String, Object?>,
            'ratings': null,
            'interviews': [
              {
                'id': 'i1',
                'stageId': 'cv_review',
                'createdAt': '2026-01-01T00:00:00.000Z',
                'decision': 'positive',
                'notes': '',
                'ratings': {'teamFit': 4.0},
              },
            ],
          },
        ],
      };
      expect(
        RecruitingDataModel.decode(legacyJson)
            .candidates
            .single
            .ratings[RatingAspect.teamFit],
        4,
      );
    },
  );

  test('keeps one editable feedback per stage', () async {
    final repository = createRepository();
    final candidate = _candidate('candidate-edit');
    await repository.saveCandidate(candidate);
    await repository.moveCandidate(candidate.id, 'cv_review');
    await repository.saveInterviewFeedback(
      candidate.id,
      stageId: 'cv_review',
      decision: FeedbackDecision.neutral,
      notes: 'First impression.',
    );
    await repository.saveInterviewFeedback(
      candidate.id,
      stageId: 'cv_review',
      decision: FeedbackDecision.positive,
      notes: 'Updated after review.',
    );
    await repository.moveCandidate(candidate.id, 'screening');

    // Past stages stay editable, but never gain a second record.
    await repository.saveInterviewFeedback(
      candidate.id,
      stageId: 'cv_review',
      decision: FeedbackDecision.negative,
      notes: 'Changed my mind.',
    );
    final interviews = (await repository.load()).candidates.single.interviews;
    expect(interviews, hasLength(1));
    expect(interviews.single.decision, FeedbackDecision.negative);
    expect(interviews.single.notes, 'Changed my mind.');

    await expectLater(
      repository.saveInterviewFeedback(
        candidate.id,
        stageId: 'technical',
        decision: FeedbackDecision.positive,
        notes: '',
      ),
      throwsA(isA<CandidateRepositoryException>()),
    );
  });

  test('merges legacy duplicate feedbacks of a stage when loading', () {
    final base = RecruitingDataModel.encode(
      RecruitingData(
        candidates: [_candidate('candidate-legacy')],
        sources: RecruitingData.initial().sources,
        stages: RecruitingData.initial().stages,
        favorites: const [],
      ),
    );
    Map<String, Object?> record(
      String id,
      String day,
      String decision,
      String notes,
    ) => {
      'id': id,
      'stageId': 'cv_review',
      'createdAt': '2026-01-${day}T00:00:00.000Z',
      'decision': decision,
      'notes': notes,
    };
    final json = <String, Object?>{
      ...base,
      'candidates': [
        {
          ...(base['candidates']! as List).single as Map<String, Object?>,
          'interviews': [
            record('b', '02', 'positive', 'Second.'),
            record('a', '01', 'neutral', 'First.'),
          ],
        },
      ],
    };
    final interviews = RecruitingDataModel.decode(json)
        .candidates
        .single
        .interviews;
    expect(interviews, hasLength(1));
    expect(interviews.single.decision, FeedbackDecision.positive);
    expect(interviews.single.notes, 'First.\n\nSecond.');
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
    await repository.moveCandidate(candidate.id, 'cv_review');
    final edited = await repository.saveCandidate(
      created.copyWith(stageId: 'new', firstName: 'Grace'),
      cvBytes: utf8.encode('second'),
    );

    expect(edited.stageId, 'cv_review');
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
