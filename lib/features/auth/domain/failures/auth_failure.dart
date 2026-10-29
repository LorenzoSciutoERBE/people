enum AuthFailureReason {
  missingConfiguration,
  unsupportedPlatform,
  browserLaunchFailed,
  callbackTimeout,
  invalidCallback,
  authorizationDenied,
  network,
  service,
  invalidCredentials,
}

class AuthFailure implements Exception {
  const AuthFailure(this.reason);

  final AuthFailureReason reason;
}
