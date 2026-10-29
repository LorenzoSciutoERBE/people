import '../../domain/entities/talent_page.dart';
import 'github_talent_model.dart';

class GitHubTalentPageModel {
  const GitHubTalentPageModel({
    required this.talents,
    required this.totalCount,
  });

  final List<GitHubTalentModel> talents;
  final int totalCount;

  TalentPage toEntity() => TalentPage(
    talents: talents.map((model) => model.toEntity()).toList(growable: false),
    totalCount: totalCount,
  );
}
