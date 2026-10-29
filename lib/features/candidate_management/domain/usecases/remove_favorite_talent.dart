import '../repositories/candidate_repository.dart';

class RemoveFavoriteTalent {
  const RemoveFavoriteTalent(this._repository);

  final CandidateRepository _repository;

  Future<void> call(String favoriteId) =>
      _repository.deleteFavorite(favoriteId);
}
