import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:oauth2/oauth2.dart' as oauth2;

import '../../domain/failures/auth_failure.dart';
import 'loopback_callback_server.dart';

typedef BrowserLauncher = Future<bool> Function(Uri uri);

class GitHubOAuthDataSource {
  const GitHubOAuthDataSource({
    required this.clientId,
    required this.clientSecret,
    required this.webBaseUrl,
    required this.launchBrowser,
  });

  final String clientId;
  final String clientSecret;
  final String webBaseUrl;
  final BrowserLauncher launchBrowser;

  Future<oauth2.Credentials> authenticate() async {
    if (!Platform.isWindows) {
      throw const AuthFailure(AuthFailureReason.unsupportedPlatform);
    }
    if (clientId.isEmpty || clientSecret.isEmpty) {
      throw const AuthFailure(AuthFailureReason.missingConfiguration);
    }

    final authorizationEndpoint = Uri.parse(
      '$webBaseUrl/login/oauth/authorize',
    );
    final tokenEndpoint = Uri.parse('$webBaseUrl/login/oauth/access_token');
    final callbackServer = await LoopbackCallbackServer.bind();
    final grant = oauth2.AuthorizationCodeGrant(
      clientId,
      authorizationEndpoint,
      tokenEndpoint,
      secret: clientSecret,
      basicAuth: false,
      getParameters: (contentType, body) {
        if (contentType?.mimeType == 'application/x-www-form-urlencoded') {
          return Uri.splitQueryString(body);
        }
        final Object? decoded = jsonDecode(body);
        if (decoded is Map<String, Object?>) return decoded;
        throw const FormatException('OAuth response must be a JSON object.');
      },
    );

    try {
      final authorizationUrl = grant.getAuthorizationUrl(
        callbackServer.redirectUri,
        scopes: const <String>['read:user'],
        state: _createState(),
      );
      if (!await launchBrowser(authorizationUrl)) {
        throw const AuthFailure(AuthFailureReason.browserLaunchFailed);
      }

      final parameters = await callbackServer.waitForCallback();
      if (parameters.containsKey('__invalid_callback__')) {
        throw const AuthFailure(AuthFailureReason.invalidCallback);
      }
      final authorizedClient = await grant.handleAuthorizationResponse(
        parameters,
      );
      final credentials = authorizedClient.credentials;
      return credentials;
    } on TimeoutException {
      throw const AuthFailure(AuthFailureReason.callbackTimeout);
    } on AuthFailure {
      rethrow;
    } on FormatException {
      throw const AuthFailure(AuthFailureReason.invalidCallback);
    } on oauth2.AuthorizationException {
      throw const AuthFailure(AuthFailureReason.authorizationDenied);
    } finally {
      grant.close();
      await callbackServer.close();
    }
  }

  String _createState() {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List<String>.generate(
      48,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }
}
