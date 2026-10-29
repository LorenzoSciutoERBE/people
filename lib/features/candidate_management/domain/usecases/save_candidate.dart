import '../entities/recruiting_data.dart';
import '../repositories/candidate_repository.dart';

class SaveCandidate {
  const SaveCandidate(this._repository);

  final CandidateRepository _repository;

  Future<Candidate> call(Candidate candidate, {List<int>? cvBytes}) =>
      _repository.saveCandidate(candidate, cvBytes: cvBytes);
}
