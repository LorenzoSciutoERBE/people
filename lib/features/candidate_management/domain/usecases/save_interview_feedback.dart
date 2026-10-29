import '../entities/recruiting_data.dart';
import '../repositories/candidate_repository.dart';

class SaveInterviewFeedback {
  const SaveInterviewFeedback(this._repository);

  final CandidateRepository _repository;

  Future<void> call(
    String candidateId, {
    required String stageId,
    required FeedbackDecision decision,
    required String notes,
  }) => _repository.saveInterviewFeedback(
    candidateId,
    stageId: stageId,
    decision: decision,
    notes: notes,
  );
}
