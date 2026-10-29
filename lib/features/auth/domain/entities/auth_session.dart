class AuthSession {
  const AuthSession({
    required this.username,
    required this.accessToken,
    required this.profileUrl,
    this.displayName,
    this.avatarUrl,
  });

  final String username;
  final String accessToken;
  final String profileUrl;
  final String? displayName;
  final String? avatarUrl;
}
