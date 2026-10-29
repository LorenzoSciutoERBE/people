import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;

import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/github_account_remote_data_source.dart';
import '../datasources/github_oauth_data_source.dart';
import '../datasources/secure_token_storage.dart';
import '../models/github_account_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.oauthDataSource,
    required this.accountDataSource,
    required this.tokenStorage,
  });

  final GitHubOAuthDataSource oauthDataSource;
  final GitHubAccountRemoteDataSource accountDataSource;
  final TokenStorage tokenStorage;

  @override
  Future<AuthSession> signIn() async {
    final credentials = await _authenticate();
    final account = await _loadAccount(credentials.accessToken);
    await tokenStorage.write(credentials.toJson());
    return account.toEntity(credentials.accessToken);
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final serializedCredentials = await tokenStorage.read();
    if (serializedCredentials == null) return null;

    late final oauth2.Credentials credentials;
    try {
      credentials = oauth2.Credentials.fromJson(serializedCredentials);
    } on FormatException {
      await tokenStorage.delete();
      throw const AuthFailure(AuthFailureReason.invalidCredentials);
    }

    final account = await _loadAccount(credentials.accessToken);
    return account.toEntity(credentials.accessToken);
  }

  @override
  Future<void> signOut() => tokenStorage.delete();

  Future<oauth2.Credentials> _authenticate() async {
    try {
      return await oauthDataSource.authenticate();
    } on SocketException {
      throw const AuthFailure(AuthFailureReason.network);
    } on http.ClientException {
      throw const AuthFailure(AuthFailureReason.network);
    }
  }

  Future<GitHubAccountModel> _loadAccount(String accessToken) async {
    try {
      return await accountDataSource.getCurrentAccount(accessToken);
    } on SocketException {
      throw const AuthFailure(AuthFailureReason.network);
    } on http.ClientException {
      throw const AuthFailure(AuthFailureReason.network);
    }
  }
}
