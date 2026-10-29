import '../entities/recruiting_data.dart';
import '../repositories/candidate_repository.dart';

class SaveConfiguration {
  const SaveConfiguration(this._repository);

  final CandidateRepository _repository;

  Future<void> call({
    required List<CandidateSource> sources,
    required List<HiringStage> stages,
  }) => _repository.saveConfiguration(sources: sources, stages: stages);
}
