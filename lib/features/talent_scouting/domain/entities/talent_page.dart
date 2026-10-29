import 'talent.dart';

/// One page of search results together with the total number of matches.
class TalentPage {
  const TalentPage({required this.talents, required this.totalCount});

  final List<Talent> talents;

  /// Total matches reported by GitHub, which can exceed the loaded talents.
  final int totalCount;
}
