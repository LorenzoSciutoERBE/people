import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/entities/talent_page.dart';
import '../../domain/entities/talent_query.dart';
import '../../domain/failures/scouting_failure.dart';
import '../../domain/repositories/talent_repository.dart';
import '../datasources/github_talent_remote_data_source.dart';

class GitHubTalentRepository implements TalentRepository {
  const GitHubTalentRepository(this.remoteDataSource);

  final GitHubTalentRemoteDataSource remoteDataSource;

  @override
  Future<TalentPage> search(
    TalentQuery query, {
    required String accessToken,
    required int page,
  }) async {
    try {
      final model = await remoteDataSource.search(
        query,
        accessToken: accessToken,
        page: page,
      );
      return model.toEntity();
    } on SocketException {
      throw const ScoutingFailure(ScoutingFailureReason.network);
    } on http.ClientException {
      throw const ScoutingFailure(ScoutingFailureReason.network);
    } on TimeoutException {
      throw const ScoutingFailure(ScoutingFailureReason.requestTimedOut);
    }
  }
}
