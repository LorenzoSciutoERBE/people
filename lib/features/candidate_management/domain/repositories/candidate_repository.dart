import '../entities/recruiting_data.dart';

abstract interface class CandidateRepository {
  Future<RecruitingData> load();

  Future<Candidate> saveCandidate(Candidate candidate, {List<int>? cvBytes});

  Future<void> deleteCandidate(String candidateId);

  Future<void> saveFavorite(FavoriteTalent favorite);

  Future<void> deleteFavorite(String favoriteId);

  Future<void> saveInterviewFeedback(
    String candidateId, {
    required String stageId,
    required FeedbackDecision decision,
    required String notes,
  });

  Future<void> moveCandidate(String candidateId, String destinationStageId);

  Future<void> saveOffer(String candidateId, CandidateOffer offer);

  Future<void> saveConfiguration({
    required List<CandidateSource> sources,
    required List<HiringStage> stages,
  });

  Future<List<int>?> readResume(String candidateId);
}
