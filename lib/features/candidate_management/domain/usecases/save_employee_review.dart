import '../entities/recruiting_data.dart';
import '../repositories/candidate_repository.dart';

class SaveEmployeeReview {
  const SaveEmployeeReview(this._repository);

  final CandidateRepository _repository;

  Future<void> call(String candidateId, EmployeeReview review) =>
      _repository.saveEmployeeReview(candidateId, review);
}
