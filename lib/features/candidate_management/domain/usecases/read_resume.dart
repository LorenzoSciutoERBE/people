import '../repositories/candidate_repository.dart';

class ReadResume {
  const ReadResume(this._repository);

  final CandidateRepository _repository;

  Future<List<int>?> call(String candidateId) =>
      _repository.readResume(candidateId);
}
