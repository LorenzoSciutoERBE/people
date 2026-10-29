// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../../domain/entities/recruiting_data.dart';
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
  Future<RecruitingData> load() => _serialize(() async {
    final snapshot = File('${_directory.path}\\$_snapshotName');
    if (!await snapshot.exists()) return RecruitingData.initial();
    final clearBytes = await _cipher.decrypt(await snapshot.readAsBytes());
    final decoded = jsonDecode(utf8.decode(clearBytes));
    if (decoded is! Map) {
      throw const FormatException('Candidate vault contents are invalid.');
    }
    final data = RecruitingDataModel.decode(
      decoded.map((key, value) => MapEntry(key as String, value)),
    );
    return data;
  });

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
            ? candidate.copyWith(stageId: _initialStageId(data.stages))
            : candidate.copyWith(
                stageId: existing.stageId,
                interviews: existing.interviews,
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
        await _writeSnapshot(
          RecruitingData(
            candidates: candidates,
            sources: data.sources,
            stages: data.stages,
            favorites: data.favorites,
          ),
        );
        if (replacedResumeKey != null) {
          final replaced = File(_resumePath(replacedResumeKey));
          if (await replaced.exists()) await replaced.delete();
        }
        return storedCandidate;
      });

  String _initialStageId(List<HiringStage> stages) {
    final active =
        stages
            .where((stage) => stage.terminalOutcome == TerminalOutcome.active)
            .toList()
          ..sort((first, second) => first.order.compareTo(second.order));
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
    final updated = RecruitingData(
      candidates: data.candidates
          .where((value) => value.id != candidateId)
          .toList(growable: false),
      sources: data.sources,
      stages: data.stages,
      favorites: data.favorites,
    );
    await _writeSnapshot(updated);
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
    await _writeSnapshot(
      RecruitingData(
        candidates: data.candidates,
        sources: data.sources,
        stages: data.stages,
        favorites: favorites,
      ),
    );
  });

  @override
  Future<void> deleteFavorite(String favoriteId) => _serialize(() async {
    final data = await _readSnapshot();
    await _writeSnapshot(
      RecruitingData(
        candidates: data.candidates,
        sources: data.sources,
        stages: data.stages,
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
  }) => _serialize(() async {
    if (decision == FeedbackDecision.pending) {
      throw const CandidateRepositoryException('feedback_decision_required');
    }
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
    final feedback = InterviewRecord(
      id: existing?.id ?? _uuid.v4(),
      stageId: stageId,
      createdAt: existing?.createdAt ?? now,
      decision: decision,
      notes: notes.trim(),
    );
    await _replaceCandidate(
      data,
      candidate.copyWith(
        interviews: <InterviewRecord>[
          for (final record in candidate.interviews)
            if (record.stageId != stageId) record,
          feedback,
        ],
        updatedAt: now,
      ),
    );
  });

  @override
  Future<void> moveCandidate(
    String candidateId,
    String destinationStageId,
  ) => _serialize(() async {
    final data = await _readSnapshot();
    final candidate = _candidate(data, candidateId);
    final currentStage = _stage(data, candidate.stageId);
    final destination = _stage(data, destinationStageId);
    final currentOutcome = currentStage.terminalOutcome;
    if (currentOutcome != TerminalOutcome.active ||
        destination.id == currentStage.id) {
      throw const CandidateRepositoryException('invalid_stage_transition');
    }
    final latestFeedback = candidate.latestFeedbackFor(currentStage.id);
    final feedbackRequired = data.requiresFeedback(currentStage.id);
    if (feedbackRequired && latestFeedback == null) {
      throw const CandidateRepositoryException('positive_feedback_required');
    }
    final decision = latestFeedback?.decision;
    if (destination.terminalOutcome == TerminalOutcome.hired) {
      if (!currentStage.isOfferStage ||
          decision != FeedbackDecision.positive ||
          candidate.offer?.status != OfferStatus.accepted) {
        throw const CandidateRepositoryException('accepted_offer_required');
      }
    } else if (destination.terminalOutcome == TerminalOutcome.rejected) {
      if (feedbackRequired &&
          decision != FeedbackDecision.negative &&
          decision != FeedbackDecision.neutral) {
        throw const CandidateRepositoryException('negative_feedback_required');
      }
    } else if (destination.terminalOutcome == TerminalOutcome.active) {
      if (feedbackRequired &&
          decision != FeedbackDecision.positive &&
          decision != FeedbackDecision.neutral) {
        throw const CandidateRepositoryException('positive_feedback_required');
      }
      final stages = _activeStages(data);
      final currentIndex = stages.indexOf(currentStage);
      if (currentIndex < 0 ||
          currentIndex + 1 >= stages.length ||
          stages[currentIndex + 1].id != destination.id) {
        throw const CandidateRepositoryException('invalid_stage_transition');
      }
    }
    await _replaceCandidate(
      data,
      candidate.copyWith(
        stageId: destination.id,
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
    await _writeSnapshot(
      RecruitingData(
        candidates: data.candidates,
        sources: sources,
        stages: stages,
        favorites: data.favorites,
      ),
    );
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
    return RecruitingDataModel.decode(
      decoded.map((key, value) => MapEntry(key as String, value)),
    );
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
        RecruitingData(
          candidates: data.candidates
              .map(
                (candidate) => candidate.id == updated.id ? updated : candidate,
              )
              .toList(growable: false),
          sources: data.sources,
          stages: data.stages,
          favorites: data.favorites,
        ),
      );

  Candidate _candidate(RecruitingData data, String id) =>
      data.candidates.where((candidate) => candidate.id == id).firstOrNull ??
      (throw const CandidateRepositoryException('candidate_not_found'));

  HiringStage _stage(RecruitingData data, String id) =>
      data.stages.where((stage) => stage.id == id).firstOrNull ??
      (throw const CandidateRepositoryException('stage_not_found'));

  List<HiringStage> _activeStages(RecruitingData data) =>
      data.stages
          .where((stage) => stage.terminalOutcome == TerminalOutcome.active)
          .toList()
        ..sort((first, second) => first.order.compareTo(second.order));

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
    _validateUniqueIds(stages.map((stage) => stage.id), 'duplicate_stage');
    if (stages.isEmpty ||
        stages.any(
          (stage) => stage.id.trim().isEmpty || stage.name.trim().isEmpty,
        )) {
      throw const CandidateRepositoryException('invalid_stage');
    }
    if (stages.where((stage) => stage.isOfferStage).length != 1 ||
        stages
                .where(
                  (stage) => stage.terminalOutcome == TerminalOutcome.hired,
                )
                .length !=
            1 ||
        stages
                .where(
                  (stage) => stage.terminalOutcome == TerminalOutcome.rejected,
                )
                .length !=
            1) {
      throw const CandidateRepositoryException('invalid_pipeline');
    }
    if (!stages.any(
          (stage) => stage.terminalOutcome == TerminalOutcome.active,
        ) ||
        stages.any(
          (stage) =>
              stage.isOfferStage &&
              stage.terminalOutcome != TerminalOutcome.active,
        )) {
      throw const CandidateRepositoryException('invalid_pipeline');
    }
    final ordered = [...stages]
      ..sort((first, second) => first.order.compareTo(second.order));
    for (var index = 1; index < ordered.length; index++) {
      if (ordered[index].order <= ordered[index - 1].order) {
        throw const CandidateRepositoryException('duplicate_stage_order');
      }
    }
    if (candidates.any(
      (candidate) => !stages.any((stage) => stage.id == candidate.stageId),
    )) {
      throw const CandidateRepositoryException('stage_in_use');
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
