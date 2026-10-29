/// Maximum accepted size of an imported resume file.
const int maximumResumeBytes = 15 * 1024 * 1024;

/// A recoverable, code-based failure raised by candidate persistence rules.
class CandidateRepositoryException implements Exception {
  const CandidateRepositoryException(this.code);

  final String code;

  @override
  String toString() => code;
}
