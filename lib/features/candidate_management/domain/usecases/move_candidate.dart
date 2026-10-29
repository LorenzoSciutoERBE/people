import '../repositories/candidate_repository.dart';

class MoveCandidate {
  const MoveCandidate(this._repository);

  final CandidateRepository _repository;

  Future<void> call(String candidateId, String destinationStageId) =>
      _repository.moveCandidate(candidateId, destinationStageId);
}
