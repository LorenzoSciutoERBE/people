class TalentQuery {
  static const Map<String, String> _languageByTechnology = <String, String>{
    'angular': 'TypeScript',
    'asp.net': 'C#',
    'c': 'C',
    'c#': 'C#',
    'c++': 'C++',
    'dart': 'Dart',
    'flutter': 'Dart',
    'go': 'Go',
    'golang': 'Go',
    'java': 'Java',
    'javascript': 'JavaScript',
    'kotlin': 'Kotlin',
    'node.js': 'JavaScript',
    'php': 'PHP',
    'python': 'Python',
    'rails': 'Ruby',
    'react': 'JavaScript',
    'react native': 'JavaScript',
    'ruby': 'Ruby',
    'rust': 'Rust',
    'spring': 'Java',
    'sql': 'SQL',
    'swift': 'Swift',
    'typescript': 'TypeScript',
    'vue': 'JavaScript',
  };

  const TalentQuery({
    required this.keywords,
    required this.location,
    required this.minimumRepositories,
    required this.minimumFollowers,
  });

  final String keywords;
  final String location;
  final int minimumRepositories;
  final int minimumFollowers;

  /// Whether at least one filter is set; GitHub must never be asked for every user.
  bool get hasCriteria =>
      keywords.trim().isNotEmpty ||
      location.trim().isNotEmpty ||
      minimumRepositories > 0 ||
      minimumFollowers > 0;

  /// Builds the `q` parameter of `/search/users`, or an empty string when no
  /// filter is set.
  ///
  /// Keywords are comma-separated. Known technologies become `language:`
  /// qualifiers; every other term is searched as free text.
  String toGitHubQuery() {
    if (!hasCriteria) return '';
    final languages = <String>[];
    final freeTerms = <String>[];
    for (final term in keywords.split(',')) {
      final normalizedTerm = term.trim();
      if (normalizedTerm.isEmpty) continue;
      final language = _languageByTechnology[normalizedTerm.toLowerCase()];
      if (language == null) {
        freeTerms.add(normalizedTerm);
      } else if (!languages.contains(language)) {
        languages.add(language);
      }
    }
    final normalizedLocation = location.trim();
    final parts = <String>[
      for (final language in languages) 'language:$language',
      ...freeTerms,
      if (normalizedLocation.isNotEmpty)
        'location:"${normalizedLocation.replaceAll('"', r'\"')}"',
      if (minimumRepositories > 0) 'repos:>=$minimumRepositories',
      if (minimumFollowers > 0) 'followers:>=$minimumFollowers',
      'type:user',
    ];
    return parts.join(' ');
  }
}
