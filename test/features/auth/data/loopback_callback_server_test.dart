import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:people/features/auth/data/datasources/loopback_callback_server.dart';

void main() {
  test('receives authorization callback parameters on loopback', () async {
    final server = await LoopbackCallbackServer.bind();
    final callback = server.waitForCallback();

    try {
      final response = await http.get(
        server.redirectUri.replace(
          queryParameters: <String, String>{
            'code': 'authorization-code',
            'state': 'random-state',
          },
        ),
      );
      expect(response.statusCode, 200);
      expect(await callback, <String, String>{
        'code': 'authorization-code',
        'state': 'random-state',
      });
    } finally {
      await server.close();
    }
  });

  test('marks duplicate callback parameters as invalid', () async {
    final server = await LoopbackCallbackServer.bind();
    final callback = server.waitForCallback();

    try {
      await http.get(
        Uri.parse('${server.redirectUri}?state=first&state=second'),
      );
      expect(await callback, <String, String>{'__invalid_callback__': 'true'});
    } finally {
      await server.close();
    }
  });
}
