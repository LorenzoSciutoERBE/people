import '../entities/employment_plan.dart';
import '../repositories/candidate_repository.dart';

class SaveEmploymentPlan {
  const SaveEmploymentPlan(this._repository);

  final CandidateRepository _repository;

  Future<void> call(String candidateId, EmploymentPlan plan) =>
      _repository.saveEmploymentPlan(candidateId, plan);
}
