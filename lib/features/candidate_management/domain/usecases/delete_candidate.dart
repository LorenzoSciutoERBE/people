import '../repositories/candidate_repository.dart';

class DeleteCandidate {
  const DeleteCandidate(this._repository);

  final CandidateRepository _repository;

  Future<void> call(String candidateId) =>
      _repository.deleteCandidate(candidateId);
}
