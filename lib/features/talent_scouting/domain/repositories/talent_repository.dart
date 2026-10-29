import '../entities/talent_page.dart';
import '../entities/talent_query.dart';

abstract interface class TalentRepository {
  Future<TalentPage> search(
    TalentQuery query, {
    required String accessToken,
    required int page,
  });
}
