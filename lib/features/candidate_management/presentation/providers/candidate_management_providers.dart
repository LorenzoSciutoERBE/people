import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/datasources/encrypted_vault.dart';
import '../../data/datasources/windows_resume_text_extractor.dart';
import '../../data/repositories/local_candidate_repository.dart';
import '../../domain/entities/recruiting_data.dart';
import '../../domain/entities/employment_plan.dart';
import '../../domain/usecases/save_employment_plan.dart';
import '../../domain/repositories/candidate_repository.dart';
import '../../domain/repositories/resume_text_extractor.dart';
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
import '../../domain/usecases/save_employee_review.dart';

final candidateVaultKeyStoreProvider = Provider<VaultKeyStore>(
  (ref) => SecureVaultKeyStore(const FlutterSecureStorage()),
);

final candidateRepositoryProvider = FutureProvider<CandidateRepository>((
  ref,
) async {
  final appDirectory = await getApplicationSupportDirectory();
  return LocalCandidateRepository(
    directory: Directory('${appDirectory.path}\\candidate_vault'),
    cipher: AesGcmVaultCipher(ref.watch(candidateVaultKeyStoreProvider)),
  );
});

final resumeTextExtractorProvider = Provider<ResumeTextExtractor>(
  (ref) => const WindowsResumeTextExtractor(MethodChannel('people/resume_ocr')),
);

final candidateManagementControllerProvider =
    AsyncNotifierProvider<CandidateManagementController, RecruitingData>(
      CandidateManagementController.new,
    );

/// Controls whether candidate evaluations and ratings are visible in the UI.
final evaluationsVisibleProvider =
    NotifierProvider<EvaluationsVisibilityNotifier, bool>(
      EvaluationsVisibilityNotifier.new,
    );

class EvaluationsVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

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

  Future<void> saveEmployeeReview(String candidateId, EmployeeReview review) =>
      _mutate(
        () =>
            SaveEmployeeReview(_requireRepository()).call(candidateId, review),
      );

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
    DateTime? recordedAt,
    bool? feedbackSharedWithCandidate,
    DateTime? scheduledAt,
    String? interviewer,
  }) => _mutate(
    () => SaveInterviewFeedback(_requireRepository()).call(
      candidateId,
      stageId: stageId,
      decision: decision,
      notes: notes,
      recordedAt: recordedAt,
      feedbackSharedWithCandidate: feedbackSharedWithCandidate,
      scheduledAt: scheduledAt,
      interviewer: interviewer,
    ),
  );

  Future<void> moveCandidate(
    String candidateId,
    String stageId, {
    EmploymentPlan? employmentPlan,
  }) => _mutate(
    () =>
        MoveCandidate(_requireRepository())
            .call(candidateId, stageId, employmentPlan: employmentPlan),
  );

  Future<void> saveEmploymentPlan(String candidateId, EmploymentPlan plan) =>
      _mutate(
        () => SaveEmploymentPlan(_requireRepository()).call(candidateId, plan),
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

  /// Publishes refreshed data only after both operations succeed. Failures
  /// propagate to the editor so its draft stays visible instead of closing.
  Future<void> _mutate(Future<void> Function() write) async {
    await write();
    state = AsyncData<RecruitingData>(
      await LoadRecruitingData(_requireRepository()).call(),
    );
  }

  CandidateRepository _requireRepository() =>
      _repository ??
      (throw StateError('The candidate repository is not initialized.'));
}
