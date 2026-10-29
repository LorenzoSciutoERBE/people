import '../entities/recruiting_data.dart';
import '../repositories/candidate_repository.dart';

class LoadRecruitingData {
  const LoadRecruitingData(this._repository);

  final CandidateRepository _repository;

  Future<RecruitingData> call() => _repository.load();
}
