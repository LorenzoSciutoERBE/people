import '../entities/talent_page.dart';
import '../entities/talent_query.dart';
import '../failures/scouting_failure.dart';
import '../repositories/talent_repository.dart';

class SearchTalentsUseCase {
  const SearchTalentsUseCase(this._repository);

  final TalentRepository _repository;

  Future<TalentPage> call(
    TalentQuery query, {
    required String accessToken,
    required int page,
  }) {
    if (!query.hasCriteria) {
      throw const ScoutingFailure(ScoutingFailureReason.emptyQuery);
    }
    if (accessToken.isEmpty) {
      throw const ScoutingFailure(ScoutingFailureReason.authenticationRequired);
    }
    return _repository.search(query, accessToken: accessToken, page: page);
  }
}
