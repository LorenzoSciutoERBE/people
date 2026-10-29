class Talent {
  const Talent({
    required this.username,
    required this.profileUrl,
    required this.avatarUrl,
    required this.publicRepositoryCount,
    required this.followerCount,
    required this.languages,
    this.displayName,
    this.location,
    this.biography,
  });

  final String username;
  final String profileUrl;
  final String avatarUrl;
  final String? displayName;
  final String? location;
  final String? biography;
  final int publicRepositoryCount;
  final int followerCount;
  final List<String> languages;
}
