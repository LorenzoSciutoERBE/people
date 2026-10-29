import '../entities/recruiting_data.dart';
import '../repositories/candidate_repository.dart';

class SaveCandidateOffer {
  const SaveCandidateOffer(this._repository);

  final CandidateRepository _repository;

  Future<void> call(String candidateId, CandidateOffer offer) =>
      _repository.saveOffer(candidateId, offer);
}
