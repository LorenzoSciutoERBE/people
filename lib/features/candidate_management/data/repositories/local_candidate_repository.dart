// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../domain/entities/recruiting_data.dart';
import '../../domain/entities/employment_plan.dart';
import '../../domain/failures/candidate_repository_exception.dart';
import '../../domain/repositories/candidate_repository.dart';
import '../datasources/encrypted_vault.dart';
import '../models/recruiting_data_model.dart';

class LocalCandidateRepository implements CandidateRepository {
  LocalCandidateRepository({
    required Directory directory,
    required AesGcmVaultCipher cipher,
    Uuid uuid = const Uuid(),
  }) : _directory = directory,
       _cipher = cipher,
       _uuid = uuid;

  static const String _snapshotName = 'recruiting.vault';

  final Directory _directory;
  final AesGcmVaultCipher _cipher;
  final Uuid _uuid;
  Future<void> _operationQueue = Future<void>.value();

  @override
  Future<RecruitingData> load() => _serialize(_readSnapshot);

  @override
  Future<Candidate> saveCandidate(Candidate candidate, {List<int>? cvBytes}) =>
      _serialize(() async {
        if (cvBytes != null && cvBytes.length > maximumResumeBytes) {
          throw const CandidateRepositoryException('resume_too_large');
        }
        if (candidate.ratings.values.any(
          (value) => value < 0.5 || value > 5 || value * 2 % 1 != 0,
        )) {
          throw const CandidateRepositoryException('feedback_rating_invalid');
        }
        final data = await _readSnapshot();
        if (!data.sources.any((source) => source.id == candidate.sourceId)) {
          throw const CandidateRepositoryException('source_not_found');
        }
        final existing = data.candidates
            .where((value) => value.id == candidate.id)
            .firstOrNull;
        // Pipeline progress, interviews, offer and the stored CV are owned by
        // the repository; edits cannot overwrite them.
        var storedCandidate = existing == null
            ? candidate.copyWith(stageId: _initialStageId(data))
            : candidate.copyWith(
                stageId: existing.stageId,
                interviews: existing.interviews,
                reviews: existing.reviews,
                employmentPlan: existing.employmentPlan,
                offer: existing.offer,
                clearOffer: existing.offer == null,
                cvStorageKey: existing.cvStorageKey,
              );
        String? replacedResumeKey;
        if (cvBytes != null) {
          final storageKey = _uuid.v4();
          await _writeEncryptedFile(_resumePath(storageKey), cvBytes);
          replacedResumeKey = existing?.cvStorageKey;
          storedCandidate = storedCandidate.copyWith(cvStorageKey: storageKey);
        }
        final candidates = <Candidate>[
          for (final existing in data.candidates)
            if (existing.id != candidate.id) existing,
          storedCandidate,
        ]..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
        await _writeSnapshot(data.copyWith(candidates: candidates));
        if (replacedResumeKey != null) {
          final replaced = File(_resumePath(replacedResumeKey));
          if (await replaced.exists()) await replaced.delete();
        }
        return storedCandidate;
      });

  @override
  Future<void> saveEmployeeReview(String candidateId, EmployeeReview review) =>
      _serialize(() async {
        final data = await _readSnapshot();
        final candidate = _candidate(data, candidateId);
        if (_stage(data, candidate.stageId).terminalOutcome !=
            TerminalOutcome.hired) {
          throw const CandidateRepositoryException('hired_candidate_required');
        }
        if (review.id.trim().isEmpty ||
            review.title.trim().isEmpty ||
            review.reviewer.trim().isEmpty ||
            review.notes.trim().isEmpty) {
          throw const CandidateRepositoryException('employee_review_invalid');
        }
        final stored = EmployeeReview(
          id: review.id,
          reviewedAt: review.reviewedAt.toUtc(),
          reviewer: review.reviewer.trim(),
          title: review.title.trim(),
          notes: review.notes.trim(),
          goals: review.goals.trim(),
        );
        final reviews = [
          for (final existing in candidate.reviews)
            if (existing.id != review.id) existing,
          stored,
        ]..sort((a, b) => b.reviewedAt.compareTo(a.reviewedAt));
        await _replaceCandidate(
          data,
          candidate.copyWith(
            reviews: reviews,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      });

  String _initialStageId(RecruitingData data) {
    final active = data.activeStages;
    if (active.isEmpty) {
      throw const CandidateRepositoryException('stage_not_found');
    }
    return active.first.id;
  }

  @override
  Future<void> deleteCandidate(String candidateId) => _serialize(() async {
    final data = await _readSnapshot();
    final candidate = data.candidates
        .where((value) => value.id == candidateId)
        .firstOrNull;
    await _writeSnapshot(
      data.copyWith(
        candidates: data.candidates
            .where((value) => value.id != candidateId)
            .toList(growable: false),
      ),
    );
    if (candidate?.cvStorageKey case final storageKey?) {
      final resume = File(_resumePath(storageKey));
      if (await resume.exists()) await resume.delete();
    }
  });

  @override
  Future<void> saveFavorite(FavoriteTalent favorite) => _serialize(() async {
    final data = await _readSnapshot();
    final favorites = <FavoriteTalent>[
      for (final existing in data.favorites)
        if (existing.id != favorite.id) existing,
      favorite,
    ]..sort((first, second) => second.savedAt.compareTo(first.savedAt));
    await _writeSnapshot(data.copyWith(favorites: favorites));
  });

  @override
  Future<void> deleteFavorite(String favoriteId) => _serialize(() async {
    final data = await _readSnapshot();
    await _writeSnapshot(
      data.copyWith(
        favorites: data.favorites
            .where((favorite) => favorite.id != favoriteId)
            .toList(growable: false),
      ),
    );
  });

  @override
  Future<void> saveInterviewFeedback(
    String candidateId, {
    required String stageId,
    required FeedbackDecision decision,
    required String notes,
    DateTime? recordedAt,
    bool? feedbackSharedWithCandidate,
    DateTime? scheduledAt,
    String? interviewer,
  }) => _serialize(() async {
    final data = await _readSnapshot();
    final candidate = _candidate(data, candidateId);
    if (!data.requiresFeedback(stageId)) {
      throw const CandidateRepositoryException('feedback_not_allowed');
    }
    // Each stage holds a single feedback; saving again edits it in place.
    // Only the current stage can receive its first feedback.
    final existing = candidate.latestFeedbackFor(stageId);
    if (existing == null && candidate.stageId != stageId) {
      throw const CandidateRepositoryException('feedback_stage_mismatch');
    }
    final now = DateTime.now().toUtc();
    if (stageId == 'new' && decision != FeedbackDecision.pending) {
      throw const CandidateRepositoryException('feedback_not_allowed');
    }
    if (stageId != 'new' &&
        decision != FeedbackDecision.pending &&
        ((scheduledAt ?? existing?.scheduledAt) == null ||
            (interviewer ?? existing?.interviewer ?? '').trim().isEmpty)) {
      throw const CandidateRepositoryException('interview_schedule_required');
    }
    final shared =
        decision != FeedbackDecision.pending &&
        (feedbackSharedWithCandidate ??
            (existing?.decision == decision &&
                (existing?.feedbackSharedWithCandidate ?? false)));
    final feedback = InterviewRecord(
      id: existing?.id ?? _uuid.v4(),
      stageId: stageId,
      createdAt: (recordedAt ?? existing?.createdAt ?? now).toUtc(),
      decision: decision,
      notes: notes.trim(),
      feedbackSharedWithCandidate: shared,
      scheduledAt: scheduledAt?.toUtc() ?? existing?.scheduledAt,
      interviewer: (interviewer ?? existing?.interviewer ?? '').trim(),
    );
    final interviews = <InterviewRecord>[
      for (final record in candidate.interviews)
        if (record.stageId != stageId) record,
      feedback,
    ]..sort((first, second) => first.createdAt.compareTo(second.createdAt));
    await _replaceCandidate(
      data,
      candidate.copyWith(interviews: interviews, updatedAt: now),
    );
  });

  @override
  Future<void> moveCandidate(
    String candidateId,
    String destinationStageId, {
    EmploymentPlan? employmentPlan,
  }) => _serialize(() async {
    final data = await _readSnapshot();
    final candidate = _candidate(data, candidateId);
    final currentStage = _stage(data, candidate.stageId);
    final destination = _stage(data, destinationStageId);
    final currentOutcome = currentStage.terminalOutcome;
    if (currentOutcome != TerminalOutcome.active ||
        destination.id == currentStage.id) {
      throw const CandidateRepositoryException('invalid_stage_transition');
    }
    final feedback = candidate.latestFeedbackFor(currentStage.id);
    if (destination.terminalOutcome == TerminalOutcome.hired) {
      if (!currentStage.isOfferStage) {
        throw const CandidateRepositoryException('offer_stage_required');
      }
      if (candidate.offer?.status != OfferStatus.accepted) {
        throw const CandidateRepositoryException('accepted_offer_required');
      }
      if (employmentPlan != null && !employmentPlan.isValid) {
        throw const CandidateRepositoryException('employment_plan_invalid');
      }
    } else {
      if (currentStage.id == 'new') {
        if (destination.terminalOutcome == TerminalOutcome.rejected ||
            feedback == null ||
            feedback.notes.trim().isEmpty) {
          throw const CandidateRepositoryException('cv_review_required');
        }
      } else if (!currentStage.isOfferStage) {
        final requiredDecision =
            destination.terminalOutcome == TerminalOutcome.rejected
            ? FeedbackDecision.negative
            : FeedbackDecision.positive;
        if (feedback?.decision != requiredDecision) {
          throw CandidateRepositoryException(
            requiredDecision == FeedbackDecision.positive
                ? 'positive_feedback_required'
                : 'negative_feedback_required',
          );
        }
        if (!feedback!.feedbackSharedWithCandidate) {
          throw const CandidateRepositoryException(
            'candidate_feedback_required',
          );
        }
      }
      if (!data
          .availableDestinationsFor(candidate, currentStage)
          .contains(destination)) {
        throw const CandidateRepositoryException('invalid_stage_transition');
      }
    }
    await _replaceCandidate(
      data,
      candidate.copyWith(
        stageId: destination.id,
        employmentPlan: destination.terminalOutcome == TerminalOutcome.hired
            ? employmentPlan ?? EmploymentPlan.propose(DateTime.now())
            : candidate.employmentPlan,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  });

  @override
  Future<void> saveEmploymentPlan(String candidateId, EmploymentPlan plan) =>
      _serialize(() async {
        final data = await _readSnapshot();
        final candidate = _candidate(data, candidateId);
        if (_stage(data, candidate.stageId).terminalOutcome !=
            TerminalOutcome.hired) {
          throw const CandidateRepositoryException('hired_candidate_required');
        }
        if (!plan.isValid) {
          throw const CandidateRepositoryException('employment_plan_invalid');
        }
        await _replaceCandidate(
          data,
          candidate.copyWith(
            employmentPlan: plan,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      });

  @override
  Future<void> saveOffer(String candidateId, CandidateOffer offer) =>
      _serialize(() async {
        final data = await _readSnapshot();
        final candidate = _candidate(data, candidateId);
        final stage = _stage(data, candidate.stageId);
        if (!stage.isOfferStage) {
          throw const CandidateRepositoryException('offer_stage_required');
        }
        await _replaceCandidate(
          data,
          candidate.copyWith(offer: offer, updatedAt: DateTime.now().toUtc()),
        );
      });

  @override
  Future<void> saveConfiguration({
    required List<CandidateSource> sources,
    required List<HiringStage> stages,
  }) => _serialize(() async {
    final data = await _readSnapshot();
    _validateSources(sources, data.candidates);
    _validateStages(stages, data.candidates);
    await _writeSnapshot(data.copyWith(sources: sources, stages: stages));
  });

  @override
  Future<List<int>?> readResume(String candidateId) => _serialize(() async {
    final candidate = _candidate(await _readSnapshot(), candidateId);
    final storageKey = candidate.cvStorageKey;
    if (storageKey == null) return null;
    final file = File(_resumePath(storageKey));
    if (!await file.exists()) {
      throw const CandidateRepositoryException('resume_file_missing');
    }
    return _cipher.decrypt(await file.readAsBytes());
  });

  Future<RecruitingData> _readSnapshot() async {
    final file = File('${_directory.path}\\$_snapshotName');
    if (!await file.exists()) return RecruitingData.initial();
    final clearBytes = await _cipher.decrypt(await file.readAsBytes());
    final decoded = jsonDecode(utf8.decode(clearBytes));
    if (decoded is! Map) {
      throw const FormatException('Candidate vault contents are invalid.');
    }
    final data = RecruitingDataModel.decode(
      decoded.map((key, value) => MapEntry(key as String, value)),
    );
    if (decoded['version'] != 2) await _writeSnapshot(data);
    return data;
  }

  Future<void> _writeSnapshot(RecruitingData data) async {
    final bytes = utf8.encode(jsonEncode(RecruitingDataModel.encode(data)));
    await _writeEncryptedFile('${_directory.path}\\$_snapshotName', bytes);
  }

  Future<void> _writeEncryptedFile(String path, List<int> clearBytes) async {
    await _directory.create(recursive: true);
    final encrypted = await _cipher.encrypt(clearBytes);
    final temporaryFile = File('$path.tmp');
    await temporaryFile.writeAsBytes(encrypted, flush: true);
    await temporaryFile.rename(path);
  }

  Future<void> _replaceCandidate(RecruitingData data, Candidate updated) =>
      _writeSnapshot(
        data.copyWith(
          candidates: data.candidates
              .map(
                (candidate) => candidate.id == updated.id ? updated : candidate,
              )
              .toList(growable: false),
        ),
      );

  Candidate _candidate(RecruitingData data, String id) =>
      data.candidates.where((candidate) => candidate.id == id).firstOrNull ??
      (throw const CandidateRepositoryException('candidate_not_found'));

  HiringStage _stage(RecruitingData data, String id) =>
      data.stages.where((stage) => stage.id == id).firstOrNull ??
      (throw const CandidateRepositoryException('stage_not_found'));

  String _resumePath(String storageKey) {
    if (!RegExp(r'^[a-f0-9-]{36}$').hasMatch(storageKey)) {
      throw const FormatException('Invalid candidate resume storage key.');
    }
    return '${_directory.path}\\$storageKey.cv.enc';
  }

  void _validateUniqueIds(Iterable<String> ids, String errorCode) {
    final values = ids.toList(growable: false);
    if (values.toSet().length != values.length) {
      throw CandidateRepositoryException(errorCode);
    }
  }

  void _validateSources(
    List<CandidateSource> sources,
    List<Candidate> candidates,
  ) {
    _validateUniqueIds(sources.map((source) => source.id), 'duplicate_source');
    if (sources.isEmpty ||
        !sources.any((source) => source.isActive) ||
        sources.any(
          (source) => source.id.trim().isEmpty || source.name.trim().isEmpty,
        )) {
      throw const CandidateRepositoryException('invalid_source');
    }
    if (candidates.any(
      (candidate) => !sources.any((source) => source.id == candidate.sourceId),
    )) {
      throw const CandidateRepositoryException('source_in_use');
    }
  }

  void _validateStages(List<HiringStage> stages, List<Candidate> candidates) {
    final expected = RecruitingData.initial().orderedStages;
    final ordered = [...stages]..sort((a, b) => a.order.compareTo(b.order));
    if (ordered.length != expected.length) {
      throw const CandidateRepositoryException('invalid_pipeline');
    }
    for (var index = 0; index < expected.length; index++) {
      final actual = ordered[index];
      final required = expected[index];
      if (actual.id != required.id ||
          actual.order != required.order ||
          actual.isOfferStage != required.isOfferStage ||
          actual.terminalOutcome != required.terminalOutcome ||
          actual.name.trim().isEmpty) {
        throw const CandidateRepositoryException('invalid_pipeline');
      }
    }
  }

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      try {
        result.complete(await operation());
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}
