import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/domain/entities/candidate_list_filter.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';

void main() {
  final stages = <HiringStage>[
    const HiringStage(id: 'new', name: 'New', order: 0),
    const HiringStage(id: 'technical', name: 'Technical interview', order: 1),
  ];
  final candidates = <Candidate>[
    _candidate('1', 'Ada', 'Lovelace', 'technical', ['Dart', 'Rust'], 2),
    _candidate('2', 'Bob', 'Stone', 'new', ['Go'], 3),
    _candidate(
      '3',
      'Carl',
      'Yu',
      'technical',
      ['Dart'],
      1,
      feedback: FeedbackDecision.positive,
    ),
  ];

  test('matches every search word against name, headline and skills', () {
    const filter = CandidateListFilter(text: 'dart ada');
    expect(filter.apply(candidates, stages).map((c) => c.id), ['1']);
  });

  test('combines stage and feedback filters', () {
    const filter = CandidateListFilter(
      stageId: 'technical',
      feedback: CandidateFeedbackFilter.missing,
    );
    expect(filter.apply(candidates, stages).map((c) => c.id), ['1']);
  });

  test('does not request interview decisions during CV review or offers', () {
    const filter = CandidateListFilter(
      feedback: CandidateFeedbackFilter.missing,
    );
    final applicants = [
      _candidate('cv', 'Ada', 'Lovelace', 'new', const [], 1),
      _candidate('offer', 'Grace', 'Hopper', 'offer', const [], 1),
      _candidate('interview', 'Alan', 'Turing', 'screening', const [], 1),
    ];
    expect(
      filter
          .apply(applicants, RecruitingData.initial().stages)
          .map((candidate) => candidate.id),
      ['interview'],
    );
  });

  test('sorts by pipeline stage and by recent update', () {
    const byStage = CandidateListFilter(sort: CandidateSort.stage);
    expect(byStage.apply(candidates, stages).first.id, '2');
    const recent = CandidateListFilter();
    expect(recent.apply(candidates, stages).first.id, '2');
  });

  test(
    'finds candidate communication still pending after positive feedback',
    () {
      const filter = CandidateListFilter(
        feedback: CandidateFeedbackFilter.communicationPending,
      );
      expect(
        filter.apply(candidates, stages).map((candidate) => candidate.id),
        ['3'],
      );
      final shared = candidates.last.copyWith(
        interviews: [
          InterviewRecord(
            id: 'shared',
            stageId: 'technical',
            createdAt: DateTime.utc(2026),
            decision: FeedbackDecision.positive,
            notes: 'Proceed.',
            feedbackSharedWithCandidate: true,
          ),
        ],
      );
      expect(filter.apply([shared], stages), isEmpty);
    },
  );
}

Candidate _candidate(
  String id,
  String first,
  String last,
  String stageId,
  List<String> skills,
  int day, {
  FeedbackDecision? feedback,
}) => Candidate(
  id: id,
  firstName: first,
  lastName: last,
  stageId: stageId,
  sourceId: 'direct',
  skills: skills,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026, 1, day),
  interviews: feedback == null
      ? const <InterviewRecord>[]
      : [
          InterviewRecord(
            id: 'i$id',
            stageId: stageId,
            createdAt: DateTime.utc(2026),
            decision: feedback,
            notes: '',
          ),
        ],
);
