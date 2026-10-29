enum FeedbackDecision { pending, positive, neutral, negative }

enum TerminalOutcome { active, hired, rejected }

enum OfferStatus { draft, sent, accepted, declined }

class CandidateSource {
  const CandidateSource({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  final String id;
  final String name;
  final bool isActive;
}

class FavoriteTalent {
  const FavoriteTalent({
    required this.id,
    required this.username,
    required this.profileUrl,
    required this.avatarUrl,
    required this.savedAt,
    this.displayName = '',
    this.location = '',
    this.biography = '',
    this.languages = const <String>[],
  });

  final String id;
  final String username;
  final String profileUrl;
  final String avatarUrl;
  final String displayName;
  final String location;
  final String biography;
  final List<String> languages;
  final DateTime savedAt;
}

class HiringStage {
  const HiringStage({
    required this.id,
    required this.name,
    required this.order,
    this.isOfferStage = false,
    this.terminalOutcome = TerminalOutcome.active,
  });

  final String id;
  final String name;
  final int order;
  final bool isOfferStage;
  final TerminalOutcome terminalOutcome;
}

/// Aspects an interviewer rates from 0.5 to 5 stars, in half-star steps.
enum RatingAspect {
  technicalSkills,
  problemSolving,
  communication,
  teamFit,
  motivation,
}

class InterviewRecord {
  const InterviewRecord({
    required this.id,
    required this.stageId,
    required this.createdAt,
    required this.decision,
    required this.notes,
  });

  final String id;
  final String stageId;
  final DateTime createdAt;
  final FeedbackDecision decision;
  final String notes;
}

class CandidateOffer {
  const CandidateOffer({
    required this.status,
    this.position = '',
    this.salary = '',
    this.currency = 'EUR',
    this.contractType = '',
    this.proposedStartDate,
    this.notes = '',
  });

  final OfferStatus status;
  final String position;
  final String salary;
  final String currency;
  final String contractType;
  final DateTime? proposedStartDate;
  final String notes;
}

class Candidate {
  const Candidate({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.stageId,
    required this.sourceId,
    required this.createdAt,
    required this.updatedAt,
    this.email = '',
    this.phone = '',
    this.location = '',
    this.headline = '',
    this.skills = const <String>[],
    this.yearsOfExperience,
    this.githubUrl = '',
    this.linkedinUrl = '',
    this.cvFileName,
    this.cvStorageKey,
    this.cvExtractedText = '',
    this.interviews = const <InterviewRecord>[],
    this.ratings = const <RatingAspect, double>{},
    this.offer,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String location;
  final String headline;
  final List<String> skills;
  final int? yearsOfExperience;
  final String githubUrl;
  final String linkedinUrl;
  final String stageId;
  final String sourceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cvFileName;
  final String? cvStorageKey;
  final String cvExtractedText;
  final List<InterviewRecord> interviews;

  /// Single rating of the candidate, shared by every pipeline step.
  final Map<RatingAspect, double> ratings;
  final CandidateOffer? offer;

  String get fullName => '$firstName $lastName'.trim();

  bool get hasResume => cvStorageKey != null;

  /// Mean of the rated aspects, or null when nothing was rated.
  double? get averageRating => ratings.isEmpty
      ? null
      : ratings.values.reduce((a, b) => a + b) / ratings.length;

  InterviewRecord? latestFeedbackFor(String stageId) {
    final records = interviews.where((record) => record.stageId == stageId);
    if (records.isEmpty) return null;
    return records.reduce(
      (latest, record) =>
          record.createdAt.isAfter(latest.createdAt) ? record : latest,
    );
  }

  Candidate copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? location,
    String? headline,
    List<String>? skills,
    int? yearsOfExperience,
    bool clearYearsOfExperience = false,
    String? githubUrl,
    String? linkedinUrl,
    String? stageId,
    String? sourceId,
    DateTime? updatedAt,
    String? cvFileName,
    String? cvStorageKey,
    String? cvExtractedText,
    List<InterviewRecord>? interviews,
    Map<RatingAspect, double>? ratings,
    CandidateOffer? offer,
    bool clearOffer = false,
  }) => Candidate(
    id: id,
    firstName: firstName ?? this.firstName,
    lastName: lastName ?? this.lastName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    location: location ?? this.location,
    headline: headline ?? this.headline,
    skills: skills ?? this.skills,
    yearsOfExperience: clearYearsOfExperience
        ? null
        : yearsOfExperience ?? this.yearsOfExperience,
    githubUrl: githubUrl ?? this.githubUrl,
    linkedinUrl: linkedinUrl ?? this.linkedinUrl,
    stageId: stageId ?? this.stageId,
    sourceId: sourceId ?? this.sourceId,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    cvFileName: cvFileName ?? this.cvFileName,
    cvStorageKey: cvStorageKey ?? this.cvStorageKey,
    cvExtractedText: cvExtractedText ?? this.cvExtractedText,
    interviews: interviews ?? this.interviews,
    ratings: ratings ?? this.ratings,
    offer: clearOffer ? null : offer ?? this.offer,
  );
}

class RecruitingData {
  const RecruitingData({
    required this.candidates,
    required this.sources,
    required this.stages,
    this.favorites = const <FavoriteTalent>[],
  });

  final List<Candidate> candidates;
  final List<CandidateSource> sources;
  final List<HiringStage> stages;
  final List<FavoriteTalent> favorites;

  /// Every active step except the first (intake) step asks for feedback.
  bool requiresFeedback(String stageId) {
    final active =
        stages
            .where((stage) => stage.terminalOutcome == TerminalOutcome.active)
            .toList()
          ..sort((first, second) => first.order.compareTo(second.order));
    return active.isNotEmpty &&
        active.first.id != stageId &&
        active.any((stage) => stage.id == stageId);
  }

  factory RecruitingData.initial() => RecruitingData(
    candidates: const <Candidate>[],
    favorites: const <FavoriteTalent>[],
    sources: const <CandidateSource>[
      CandidateSource(id: 'grafton', name: 'Grafton'),
      CandidateSource(id: 'poli', name: 'Poli'),
      CandidateSource(id: 'github', name: 'GitHub'),
      CandidateSource(id: 'other', name: 'Other'),
    ],
    stages: const <HiringStage>[
      HiringStage(id: 'new', name: 'New', order: 0),
      HiringStage(id: 'cv_review', name: 'CV review', order: 1),
      HiringStage(id: 'screening', name: 'Screening interview', order: 2),
      HiringStage(id: 'technical', name: 'Technical interview', order: 3),
      HiringStage(id: 'final', name: 'Final interview', order: 4),
      HiringStage(
        id: 'offer',
        name: 'Offer / pre-contract',
        order: 5,
        isOfferStage: true,
      ),
      HiringStage(
        id: 'hired',
        name: 'Hired',
        order: 6,
        terminalOutcome: TerminalOutcome.hired,
      ),
      HiringStage(
        id: 'rejected',
        name: 'Rejected',
        order: 7,
        terminalOutcome: TerminalOutcome.rejected,
      ),
    ],
  );
}
