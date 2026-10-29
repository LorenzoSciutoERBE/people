import 'recruiting_data.dart';

enum CandidateSort { recentlyUpdated, name, stage }

enum CandidateFeedbackFilter { any, missing, positive, neutral, negative }

/// Search, filter and sort criteria for the candidate list.
class CandidateListFilter {
  const CandidateListFilter({
    this.text = '',
    this.stageId,
    this.sourceId,
    this.feedback = CandidateFeedbackFilter.any,
    this.withResumeOnly = false,
    this.sort = CandidateSort.recentlyUpdated,
  });

  final String text;
  final String? stageId;
  final String? sourceId;
  final CandidateFeedbackFilter feedback;
  final bool withResumeOnly;
  final CandidateSort sort;

  bool get hasActiveFilters =>
      text.trim().isNotEmpty ||
      stageId != null ||
      sourceId != null ||
      feedback != CandidateFeedbackFilter.any ||
      withResumeOnly;

  CandidateListFilter copyWith({
    String? text,
    String? stageId,
    bool clearStage = false,
    String? sourceId,
    bool clearSource = false,
    CandidateFeedbackFilter? feedback,
    bool? withResumeOnly,
    CandidateSort? sort,
  }) => CandidateListFilter(
    text: text ?? this.text,
    stageId: clearStage ? null : stageId ?? this.stageId,
    sourceId: clearSource ? null : sourceId ?? this.sourceId,
    feedback: feedback ?? this.feedback,
    withResumeOnly: withResumeOnly ?? this.withResumeOnly,
    sort: sort ?? this.sort,
  );

  /// Returns the matching candidates in the requested order.
  List<Candidate> apply(List<Candidate> candidates, List<HiringStage> stages) {
    final stageOrder = <String, int>{
      for (final stage in stages) stage.id: stage.order,
    };
    final needle = text.trim().toLowerCase();
    final result = candidates
        .where((candidate) => _matches(candidate, needle))
        .toList();
    result.sort(switch (sort) {
      CandidateSort.recentlyUpdated => (a, b) => b.updatedAt.compareTo(
        a.updatedAt,
      ),
      CandidateSort.name => (a, b) => a.fullName.toLowerCase().compareTo(
        b.fullName.toLowerCase(),
      ),
      CandidateSort.stage => (a, b) => (stageOrder[a.stageId] ?? 0).compareTo(
        stageOrder[b.stageId] ?? 0,
      ),
    });
    return result;
  }

  bool _matches(Candidate candidate, String needle) {
    if (stageId != null && candidate.stageId != stageId) return false;
    if (sourceId != null && candidate.sourceId != sourceId) return false;
    if (withResumeOnly && !candidate.hasResume) return false;
    if (!_matchesFeedback(candidate)) return false;
    if (needle.isEmpty) return true;
    final haystack = <String>[
      candidate.fullName,
      candidate.email,
      candidate.location,
      candidate.headline,
      ...candidate.skills,
    ].join(' ').toLowerCase();
    return needle.split(RegExp(r'\s+')).every(haystack.contains);
  }

  bool _matchesFeedback(Candidate candidate) {
    if (feedback == CandidateFeedbackFilter.any) return true;
    final decision = candidate.latestFeedbackFor(candidate.stageId)?.decision;
    return switch (feedback) {
      CandidateFeedbackFilter.any => true,
      CandidateFeedbackFilter.missing =>
        decision == null || decision == FeedbackDecision.pending,
      CandidateFeedbackFilter.positive => decision == FeedbackDecision.positive,
      CandidateFeedbackFilter.neutral => decision == FeedbackDecision.neutral,
      CandidateFeedbackFilter.negative => decision == FeedbackDecision.negative,
    };
  }
}
