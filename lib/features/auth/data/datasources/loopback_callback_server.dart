import 'dart:async';
import 'dart:io';

class LoopbackCallbackServer {
  LoopbackCallbackServer._(this._server) {
    _subscription = _server.listen(_handleRequest);
  }

  static const Duration callbackTimeout = Duration(minutes: 2);
  static const String _callbackPath = '/callback';

  final HttpServer _server;
  late final StreamSubscription<HttpRequest> _subscription;
  final Completer<Map<String, String>> _callback =
      Completer<Map<String, String>>();

  Uri get redirectUri => Uri(
    scheme: 'http',
    host: InternetAddress.loopbackIPv4.address,
    port: _server.port,
    path: _callbackPath,
  );

  static Future<LoopbackCallbackServer> bind() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return LoopbackCallbackServer._(server);
  }

  Future<Map<String, String>> waitForCallback() =>
      _callback.future.timeout(callbackTimeout);

  Future<void> close() async {
    await _subscription.cancel();
    await _server.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path != _callbackPath || request.method != 'GET') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final parameters = <String, String>{};
    for (final entry in request.uri.queryParametersAll.entries) {
      if (entry.value.length != 1) {
        if (!_callback.isCompleted) {
          _callback.complete(<String, String>{'__invalid_callback__': 'true'});
        }
        request.response
          ..statusCode = HttpStatus.badRequest
          ..write('Invalid authorization response.');
        await request.response.close();
        return;
      }
      parameters[entry.key] = entry.value.single;
    }
    // Ignore stray requests (for example a browser probe) that carry no
    // authorization result, so they cannot end the login flow.
    final isAuthorizationResponse =
        parameters.containsKey('state') &&
        (parameters.containsKey('code') || parameters.containsKey('error'));
    if (!isAuthorizationResponse) {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(
        '<!doctype html><html><head><meta charset="utf-8">'
        '<title>People</title></head><body>'
        '<p>Authorization response received. You can close this window.</p>'
        '</body></html>',
      );
    await request.response.close();
    if (!_callback.isCompleted) _callback.complete(parameters);
  }
}
