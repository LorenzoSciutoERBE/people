enum ScoutingFailureReason {
  emptyQuery,
  authenticationRequired,
  rateLimitExceeded,
  requestTimedOut,
  invalidResponse,
  network,
  service,
}

class ScoutingFailure implements Exception {
  const ScoutingFailure(this.reason);

  final ScoutingFailureReason reason;
}
