import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/failures/auth_failure.dart';
import '../providers/auth_providers.dart';

class AuthStatusPanel extends ConsumerWidget {
  const AuthStatusPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localization = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);
    return authState.when(
      data: (session) => session == null
          ? FilledButton.icon(
              onPressed: () => ref.read(authNotifierProvider.notifier).signIn(),
              icon: const Icon(Icons.login),
              label: Text(localization.authSignIn),
            )
          : _AuthenticatedStatus(
              session: session,
              onSignOut: ref.read(authNotifierProvider.notifier).signOut,
              signOutLabel: localization.authSignOut,
            ),
      loading: () => const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.error_outline, color: Colors.red),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _errorMessage(localization, error),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => ref.read(authNotifierProvider.notifier).signIn(),
            icon: const Icon(Icons.login),
            label: Text(localization.authSignIn),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }

  String _errorMessage(AppLocalizations localization, Object error) {
    if (error is! AuthFailure) return localization.authUnknownError;
    return switch (error.reason) {
      AuthFailureReason.missingConfiguration =>
        localization.authMissingConfiguration,
      AuthFailureReason.unsupportedPlatform =>
        localization.authUnsupportedPlatform,
      AuthFailureReason.browserLaunchFailed =>
        localization.authBrowserLaunchFailed,
      AuthFailureReason.callbackTimeout => localization.authCallbackTimeout,
      AuthFailureReason.invalidCallback => localization.authInvalidCallback,
      AuthFailureReason.authorizationDenied => localization.authDenied,
      AuthFailureReason.network => localization.authNetworkError,
      AuthFailureReason.service => localization.authServiceError,
      AuthFailureReason.invalidCredentials =>
        localization.authInvalidCredentials,
    };
  }
}

class _AuthenticatedStatus extends StatelessWidget {
  const _AuthenticatedStatus({
    required this.session,
    required this.onSignOut,
    required this.signOutLabel,
  });

  final AuthSession session;
  final VoidCallback onSignOut;
  final String signOutLabel;

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: Color(0xFF2155CD)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                localization.authenticatedAs(session.username),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: onSignOut, child: Text(signOutLabel)),
        ),
      ],
    );
  }
}
