import '../repositories/candidate_repository.dart';
import '../entities/employment_plan.dart';

class MoveCandidate {
  const MoveCandidate(this._repository);

  final CandidateRepository _repository;

  Future<void> call(
    String candidateId,
    String destinationStageId, {
    EmploymentPlan? employmentPlan,
  }) => _repository.moveCandidate(
    candidateId,
    destinationStageId,
    employmentPlan: employmentPlan,
  );
}
