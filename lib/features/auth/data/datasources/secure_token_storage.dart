import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> read();

  Future<void> write(String value);

  Future<void> delete();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  static const String _key = 'github_oauth_credentials';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}
