import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../data/datasources/github_account_remote_data_source.dart';
import '../../data/datasources/github_oauth_data_source.dart';
import '../../data/datasources/secure_token_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/authenticate_user_use_case.dart';
import '../../domain/usecases/restore_auth_session_use_case.dart';
import '../../domain/usecases/sign_out_use_case.dart';

final authHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(ref.watch(flutterSecureStorageProvider)),
);

final githubOAuthDataSourceProvider = Provider<GitHubOAuthDataSource>(
  (ref) => GitHubOAuthDataSource(
    clientId: AppConfig.githubClientId,
    clientSecret: AppConfig.githubClientSecret,
    webBaseUrl: AppConfig.githubWebBaseUrl,
    launchBrowser: (uri) =>
        launchUrl(uri, mode: LaunchMode.externalApplication),
  ),
);

final githubAccountRemoteDataSourceProvider =
    Provider<GitHubAccountRemoteDataSource>(
      (ref) => GitHubAccountRemoteDataSource(
        client: ref.watch(authHttpClientProvider),
        apiBaseUrl: AppConfig.githubApiBaseUrl,
      ),
    );

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    oauthDataSource: ref.watch(githubOAuthDataSourceProvider),
    accountDataSource: ref.watch(githubAccountRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final authenticateUserUseCaseProvider = Provider<AuthenticateUserUseCase>(
  (ref) => AuthenticateUserUseCase(ref.watch(authRepositoryProvider)),
);

final restoreAuthSessionUseCaseProvider = Provider<RestoreAuthSessionUseCase>(
  (ref) => RestoreAuthSessionUseCase(ref.watch(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.watch(authRepositoryProvider)),
);

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthSession?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() =>
      ref.watch(restoreAuthSessionUseCaseProvider).call();

  Future<void> signIn() async {
    state = const AsyncLoading<AuthSession?>();
    state = await AsyncValue.guard(
      ref.read(authenticateUserUseCaseProvider).call,
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading<AuthSession?>();
    state = await AsyncValue.guard(() async {
      await ref.read(signOutUseCaseProvider).call();
      return null;
    });
  }
}
