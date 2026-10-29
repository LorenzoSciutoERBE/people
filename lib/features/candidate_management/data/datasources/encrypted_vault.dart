import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class VaultKeyStore {
  Future<List<int>?> readKey();

  Future<void> writeKey(List<int> value);
}

class SecureVaultKeyStore implements VaultKeyStore {
  const SecureVaultKeyStore(this._storage);

  static const String _keyName = 'people_candidate_vault_key_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<List<int>?> readKey() async {
    final encoded = await _storage.read(key: _keyName);
    return encoded == null ? null : base64Url.decode(encoded);
  }

  @override
  Future<void> writeKey(List<int> value) =>
      _storage.write(key: _keyName, value: base64UrlEncode(value));
}

class AesGcmVaultCipher {
  AesGcmVaultCipher(this._keyStore);

  static const int _formatVersion = 1;
  static const int keyLength = 32;

  final VaultKeyStore _keyStore;
  final AesGcm _algorithm = AesGcm.with256bits();
  Future<SecretKey>? _secretKey;

  Future<Uint8List> encrypt(List<int> clearBytes) async {
    final secretBox = await _algorithm.encrypt(
      clearBytes,
      secretKey: await _getSecretKey(),
    );
    return Uint8List.fromList(<int>[
      _formatVersion,
      ...secretBox.concatenation(),
    ]);
  }

  Future<Uint8List> decrypt(List<int> encryptedBytes) async {
    if (encryptedBytes.isEmpty || encryptedBytes.first != _formatVersion) {
      throw const FormatException('Unsupported encrypted vault format.');
    }
    final secretBox = SecretBox.fromConcatenation(
      encryptedBytes.sublist(1),
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    return Uint8List.fromList(
      await _algorithm.decrypt(secretBox, secretKey: await _getSecretKey()),
    );
  }

  Future<SecretKey> _getSecretKey() {
    final pending = _secretKey ??= _loadOrCreateKey();
    // Do not cache a failed load; allow a later retry.
    pending.ignore();
    return pending.catchError((Object error) {
      _secretKey = null;
      throw error;
    });
  }

  Future<SecretKey> _loadOrCreateKey() async {
    final storedKey = await _keyStore.readKey();
    if (storedKey != null) {
      if (storedKey.length != keyLength) {
        throw const FormatException('The candidate vault key is invalid.');
      }
      return SecretKey(storedKey);
    }
    final random = Random.secure();
    final key = List<int>.generate(keyLength, (_) => random.nextInt(256));
    await _keyStore.writeKey(key);
    return SecretKey(key);
  }
}
