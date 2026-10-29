import 'package:flutter_test/flutter_test.dart';
import 'package:people/features/candidate_management/domain/entities/candidate_list_filter.dart';
import 'package:people/features/candidate_management/domain/entities/recruiting_data.dart';

void main() {
  final stages = <HiringStage>[
    const HiringStage(id: 'new', name: 'New', order: 0),
    const HiringStage(id: 'tech', name: 'Tech', order: 1),
  ];
  final candidates = <Candidate>[
    _candidate('1', 'Ada', 'Lovelace', 'tech', ['Dart', 'Rust'], 2),
    _candidate('2', 'Bob', 'Stone', 'new', ['Go'], 3),
    _candidate(
      '3',
      'Carl',
      'Yu',
      'tech',
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
      stageId: 'tech',
      feedback: CandidateFeedbackFilter.missing,
    );
    expect(filter.apply(candidates, stages).map((c) => c.id), ['1']);
  });

  test('sorts by pipeline stage and by recent update', () {
    const byStage = CandidateListFilter(sort: CandidateSort.stage);
    expect(byStage.apply(candidates, stages).first.id, '2');
    const recent = CandidateListFilter();
    expect(recent.apply(candidates, stages).first.id, '2');
  });
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
