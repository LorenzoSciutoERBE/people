import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/candidate_management_dependencies.dart';
import '../../domain/entities/recruiting_data.dart';
import '../../domain/repositories/candidate_repository.dart';
import '../../domain/usecases/delete_candidate.dart';
import '../../domain/usecases/load_recruiting_data.dart';
import '../../domain/usecases/move_candidate.dart';
import '../../domain/usecases/read_resume.dart';
import '../../domain/usecases/remove_favorite_talent.dart';
import '../../domain/usecases/save_candidate.dart';
import '../../domain/usecases/save_candidate_offer.dart';
import '../../domain/usecases/save_configuration.dart';
import '../../domain/usecases/save_favorite_talent.dart';
import '../../domain/usecases/save_interview_feedback.dart';

final candidateManagementControllerProvider =
    AsyncNotifierProvider<CandidateManagementController, RecruitingData>(
      CandidateManagementController.new,
    );

class CandidateManagementController extends AsyncNotifier<RecruitingData> {
  CandidateRepository? _repository;

  @override
  Future<RecruitingData> build() async {
    final repository = await ref.watch(candidateRepositoryProvider.future);
    _repository = repository;
    return LoadRecruitingData(repository).call();
  }

  Future<void> saveCandidate(Candidate candidate, {List<int>? cvBytes}) =>
      _mutate(
        () =>
            SaveCandidate(_requireRepository())
                .call(candidate, cvBytes: cvBytes),
      );

  Future<void> deleteCandidate(String candidateId) =>
      _mutate(() => DeleteCandidate(_requireRepository()).call(candidateId));

  Future<void> saveFavorite(FavoriteTalent favorite) =>
      _mutate(() => SaveFavoriteTalent(_requireRepository()).call(favorite));

  Future<void> deleteFavorite(String favoriteId) => _mutate(
    () => RemoveFavoriteTalent(_requireRepository()).call(favoriteId),
  );

  Future<void> saveFeedback(
    String candidateId, {
    required String stageId,
    required FeedbackDecision decision,
    required String notes,
  }) => _mutate(
    () => SaveInterviewFeedback(_requireRepository())
        .call(candidateId, stageId: stageId, decision: decision, notes: notes),
  );

  Future<void> moveCandidate(String candidateId, String stageId) => _mutate(
    () => MoveCandidate(_requireRepository()).call(candidateId, stageId),
  );

  Future<void> saveOffer(String candidateId, CandidateOffer offer) => _mutate(
    () => SaveCandidateOffer(_requireRepository()).call(candidateId, offer),
  );

  Future<void> saveConfiguration({
    required List<CandidateSource> sources,
    required List<HiringStage> stages,
  }) => _mutate(
    () =>
        SaveConfiguration(_requireRepository())
            .call(sources: sources, stages: stages),
  );

  Future<List<int>?> readResume(String candidateId) =>
      ReadResume(_requireRepository()).call(candidateId);

  /// Runs a write and then reloads. A failed reload keeps the previous data
  /// visible and reports the error instead of throwing from the write.
  Future<void> _mutate(Future<void> Function() write) async {
    await write();
    try {
      state = AsyncData<RecruitingData>(
        await LoadRecruitingData(_requireRepository()).call(),
      );
    } on Object catch (error, stackTrace) {
      state = AsyncError<RecruitingData>(error, stackTrace);
    }
  }

  CandidateRepository _requireRepository() =>
      _repository ??
      (throw StateError('The candidate repository is not initialized.'));
}
