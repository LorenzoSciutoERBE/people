import '../entities/recruiting_data.dart';
import '../repositories/candidate_repository.dart';

class SaveFavoriteTalent {
  const SaveFavoriteTalent(this._repository);

  final CandidateRepository _repository;

  Future<void> call(FavoriteTalent favorite) =>
      _repository.saveFavorite(favorite);
}
