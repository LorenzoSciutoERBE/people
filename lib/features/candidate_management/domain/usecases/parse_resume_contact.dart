/// Identity details recognized in a resume; empty strings mean "not found".
class ResumeContact {
  const ResumeContact({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
  });

  final String firstName;
  final String lastName;
  final String email;
}

/// Extracts only the candidate name and email from raw resume text.
class ParseResumeContact {
  const ParseResumeContact();

  static const int _maximumNameLines = 15;

  static final RegExp _emailPattern = RegExp(
    r'[A-Za-z0-9._%+\-]+\s?@\s?[A-Za-z0-9\-]+(?:\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}',
  );
  static final RegExp _labelPattern = RegExp(
    r'^(?:full\s+name|nome\s+e\s+cognome|nome|name)\s*[:\-]\s*',
    caseSensitive: false,
  );
  static final RegExp _edgeNoisePattern = RegExp(
    r'^[^A-Za-zÀ-ÖØ-öø-ÿ]+|[^A-Za-zÀ-ÖØ-öø-ÿ]+$',
  );
  static final RegExp _wordPattern = RegExp(
    r"^[A-Za-zÀ-ÖØ-öø-ÿ][A-Za-zÀ-ÖØ-öø-ÿ'’\-]*\.?$",
  );

  static const Set<String> _excludedTerms = <String>{
    'address',
    'analyst',
    'architect',
    'cv',
    'consultant',
    'contact',
    'contacts',
    'contatti',
    'curriculum',
    'dati',
    'designer',
    'developer',
    'education',
    'email',
    'engineer',
    'esperienza',
    'europass',
    'experience',
    'formazione',
    'informazioni',
    'istruzione',
    'lingue',
    'manager',
    'personali',
    'personal',
    'phone',
    'profile',
    'profilo',
    'resume',
    'skills',
    'competenze',
    'software',
    'sviluppatore',
    'summary',
    'telefono',
    'vitae',
  };

  ResumeContact call(String text) {
    final lines = text
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    final nameLine = lines
        .take(_maximumNameLines)
        .map(_cleanNameLine)
        .firstWhere(_looksLikePersonName, orElse: () => '');
    final words = nameLine.split(RegExp(r'\s+'));
    return ResumeContact(
      firstName: nameLine.isEmpty ? '' : _normalizeCase(words.first),
      lastName: words.length > 1
          ? words.skip(1).map(_normalizeCase).join(' ')
          : '',
      email: _findEmail(text),
    );
  }

  String _findEmail(String text) {
    final match = _emailPattern.firstMatch(text)?.group(0);
    if (match == null) return '';
    return match.replaceAll(RegExp(r'\s'), '').toLowerCase();
  }

  String _cleanNameLine(String line) => line
      .replaceFirst(_labelPattern, '')
      .replaceAll(_edgeNoisePattern, '')
      .replaceAll(RegExp(r'\s+'), ' ');

  bool _looksLikePersonName(String line) {
    if (line.length < 5 || line.length > 50) return false;
    final words = line.split(' ');
    if (words.length < 2 || words.length > 4) return false;
    if (!words.every(_wordPattern.hasMatch)) return false;
    return !words.any(
      (word) => _excludedTerms.contains(word.toLowerCase().replaceAll('.', '')),
    );
  }

  // Mixed-case names are kept as written; OCR often yields all-caps names.
  String _normalizeCase(String word) {
    final isUniform = word == word.toUpperCase() || word == word.toLowerCase();
    if (!isUniform) return word;
    return word.toLowerCase().splitMapJoin(
      RegExp(r"[\-'’]"),
      onMatch: (match) => match.group(0)!,
      onNonMatch: (part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}',
    );
  }
}
