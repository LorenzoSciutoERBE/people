import '../../domain/entities/recruiting_data.dart';

class RecruitingDataModel {
  const RecruitingDataModel._();

  static Map<String, Object?> encode(RecruitingData data) => <String, Object?>{
    'version': 1,
    'candidates': data.candidates.map(_encodeCandidate).toList(),
    'favorites': data.favorites.map(_encodeFavorite).toList(),
    'sources': data.sources.map(_encodeSource).toList(),
    'stages': data.stages.map(_encodeStage).toList(),
  };

  static RecruitingData decode(Map<String, Object?> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unsupported recruiting data version.');
    }
    return RecruitingData(
      candidates: _objects(json['candidates'])
          .map(_decodeCandidate)
          .toList(growable: false),
      favorites: json['favorites'] == null
          ? const <FavoriteTalent>[]
          : _objects(json['favorites'])
                .map(_decodeFavorite)
                .toList(growable: false),
      sources: _objects(json['sources'])
          .map(_decodeSource)
          .toList(growable: false),
      stages: _objects(json['stages'])
          .map(_decodeStage)
          .toList(growable: false),
    );
  }

  static Map<String, Object?> _encodeCandidate(
    Candidate value,
  ) => <String, Object?>{
    'id': value.id,
    'firstName': value.firstName,
    'lastName': value.lastName,
    'email': value.email,
    'phone': value.phone,
    'location': value.location,
    'headline': value.headline,
    'skills': value.skills,
    'yearsOfExperience': value.yearsOfExperience,
    'githubUrl': value.githubUrl,
    'linkedinUrl': value.linkedinUrl,
    'stageId': value.stageId,
    'sourceId': value.sourceId,
    'createdAt': value.createdAt.toIso8601String(),
    'updatedAt': value.updatedAt.toIso8601String(),
    'cvFileName': value.cvFileName,
    'cvStorageKey': value.cvStorageKey,
    'cvExtractedText': value.cvExtractedText,
    'interviews': value.interviews.map(_encodeInterview).toList(),
    'ratings': <String, Object?>{
      for (final entry in value.ratings.entries) entry.key.name: entry.value,
    },
    'offer': value.offer == null ? null : _encodeOffer(value.offer!),
  };

  static Candidate _decodeCandidate(Map<String, Object?> json) => Candidate(
    id: _string(json, 'id'),
    firstName: _string(json, 'firstName'),
    lastName: _string(json, 'lastName'),
    email: _string(json, 'email'),
    phone: _string(json, 'phone'),
    location: _string(json, 'location'),
    headline: _string(json, 'headline'),
    skills: _strings(json['skills']),
    yearsOfExperience: json['yearsOfExperience'] as int?,
    githubUrl: _string(json, 'githubUrl'),
    linkedinUrl: _string(json, 'linkedinUrl'),
    stageId: _string(json, 'stageId'),
    sourceId: _string(json, 'sourceId'),
    createdAt: DateTime.parse(_string(json, 'createdAt')),
    updatedAt: DateTime.parse(_string(json, 'updatedAt')),
    cvFileName: json['cvFileName'] as String?,
    cvStorageKey: json['cvStorageKey'] as String?,
    cvExtractedText: _string(json, 'cvExtractedText'),
    interviews: _singleRecordPerStage(
      _objects(json['interviews']).map(_decodeInterview).toList(),
    ),
    ratings: json['ratings'] == null
        ? _legacyRatings(json['interviews'])
        : _decodeRatings(json['ratings']),
    offer: json['offer'] == null ? null : _decodeOffer(_object(json['offer'])),
  );

  // Older data could hold several feedbacks per stage. Merge them into one:
  // the latest decision wins and every non-empty note is kept in order.
  static List<InterviewRecord> _singleRecordPerStage(
    List<InterviewRecord> records,
  ) {
    final sorted = [...records]
      ..sort((first, second) => first.createdAt.compareTo(second.createdAt));
    final byStage = <String, List<InterviewRecord>>{};
    for (final record in sorted) {
      byStage
          .putIfAbsent(record.stageId, () => <InterviewRecord>[])
          .add(record);
    }
    return <InterviewRecord>[
      for (final group in byStage.values)
        InterviewRecord(
          id: group.last.id,
          stageId: group.last.stageId,
          createdAt: group.first.createdAt,
          decision: group.last.decision,
          notes: group
              .map((record) => record.notes)
              .where((notes) => notes.isNotEmpty)
              .join('\n\n'),
        ),
    ];
  }

  // Ratings used to live on each interview; keep the most recent per aspect.
  static Map<RatingAspect, double> _legacyRatings(Object? interviews) {
    final records = _objects(interviews)
      ..sort(
        (first, second) =>
            DateTime.parse(_string(first, 'createdAt'))
                .compareTo(DateTime.parse(_string(second, 'createdAt'))),
      );
    final merged = <RatingAspect, double>{};
    for (final record in records) {
      merged.addAll(_decodeRatings(record['ratings']));
    }
    return merged;
  }

  static Map<String, Object?> _encodeInterview(InterviewRecord value) =>
      <String, Object?>{
        'id': value.id,
        'stageId': value.stageId,
        'createdAt': value.createdAt.toIso8601String(),
        'decision': value.decision.name,
        'notes': value.notes,
      };

  static InterviewRecord _decodeInterview(Map<String, Object?> json) =>
      InterviewRecord(
        id: _string(json, 'id'),
        stageId: _string(json, 'stageId'),
        createdAt: DateTime.parse(_string(json, 'createdAt')),
        decision: _enum(FeedbackDecision.values, json, 'decision'),
        notes: _string(json, 'notes'),
      );

  static Map<RatingAspect, double> _decodeRatings(Object? value) {
    if (value == null) return const <RatingAspect, double>{};
    final json = _object(value);
    return <RatingAspect, double>{
      for (final entry in json.entries)
        RatingAspect.values.byName(entry.key): _rating(entry.value),
    };
  }

  static double _rating(Object? value) {
    if (value is num && value >= 0.5 && value <= 5 && value * 2 % 1 == 0) {
      return value.toDouble();
    }
    throw FormatException('Invalid rating: $value');
  }

  static Map<String, Object?> _encodeOffer(CandidateOffer value) =>
      <String, Object?>{
        'status': value.status.name,
        'position': value.position,
        'salary': value.salary,
        'currency': value.currency,
        'contractType': value.contractType,
        'proposedStartDate': value.proposedStartDate?.toIso8601String(),
        'notes': value.notes,
      };

  static CandidateOffer _decodeOffer(Map<String, Object?> json) =>
      CandidateOffer(
        status: _enum(OfferStatus.values, json, 'status'),
        position: _string(json, 'position'),
        salary: _string(json, 'salary'),
        currency: _string(json, 'currency'),
        contractType: _string(json, 'contractType'),
        proposedStartDate: json['proposedStartDate'] == null
            ? null
            : DateTime.parse(_string(json, 'proposedStartDate')),
        notes: _string(json, 'notes'),
      );

  static Map<String, Object?> _encodeSource(CandidateSource value) =>
      <String, Object?>{
        'id': value.id,
        'name': value.name,
        'isActive': value.isActive,
      };

  static Map<String, Object?> _encodeFavorite(FavoriteTalent value) =>
      <String, Object?>{
        'id': value.id,
        'username': value.username,
        'profileUrl': value.profileUrl,
        'avatarUrl': value.avatarUrl,
        'displayName': value.displayName,
        'location': value.location,
        'biography': value.biography,
        'languages': value.languages,
        'savedAt': value.savedAt.toIso8601String(),
      };

  static FavoriteTalent _decodeFavorite(Map<String, Object?> json) =>
      FavoriteTalent(
        id: _string(json, 'id'),
        username: _string(json, 'username'),
        profileUrl: _string(json, 'profileUrl'),
        avatarUrl: _string(json, 'avatarUrl'),
        displayName: _string(json, 'displayName'),
        location: _string(json, 'location'),
        biography: _string(json, 'biography'),
        languages: _strings(json['languages']),
        savedAt: DateTime.parse(_string(json, 'savedAt')),
      );

  static CandidateSource _decodeSource(Map<String, Object?> json) =>
      CandidateSource(
        id: _string(json, 'id'),
        name: _string(json, 'name'),
        isActive: _bool(json, 'isActive'),
      );

  static Map<String, Object?> _encodeStage(HiringStage value) =>
      <String, Object?>{
        'id': value.id,
        'name': value.name,
        'order': value.order,
        'isOfferStage': value.isOfferStage,
        'terminalOutcome': value.terminalOutcome.name,
      };

  static HiringStage _decodeStage(Map<String, Object?> json) => HiringStage(
    id: _string(json, 'id'),
    name: _string(json, 'name'),
    order: _int(json, 'order'),
    isOfferStage: _bool(json, 'isOfferStage'),
    terminalOutcome: _enum(TerminalOutcome.values, json, 'terminalOutcome'),
  );

  static T _enum<T extends Enum>(
    List<T> values,
    Map<String, Object?> json,
    String key,
  ) {
    final name = _string(json, key);
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('Invalid recruiting data field: $key.');
  }

  static int _int(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('Invalid recruiting data field: $key.');
    }
    return value;
  }

  static bool _bool(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw FormatException('Invalid recruiting data field: $key.');
    }
    return value;
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Invalid recruiting data field: $key.');
    }
    return value;
  }

  static Map<String, Object?> _object(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid recruiting record.');
    }
    return value.map((key, value) => MapEntry(key as String, value));
  }

  static List<Map<String, Object?>> _objects(Object? value) {
    if (value is! List) throw const FormatException('Invalid recruiting list.');
    return value.map(_object).toList(growable: false);
  }

  static List<String> _strings(Object? value) {
    if (value is! List || value.any((item) => item is! String)) {
      throw const FormatException('Invalid recruiting string list.');
    }
    return value.cast<String>().toList(growable: false);
  }
}
