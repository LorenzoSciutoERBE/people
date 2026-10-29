import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../data/datasources/encrypted_vault.dart';
import '../data/datasources/windows_resume_text_extractor.dart';
import '../data/repositories/local_candidate_repository.dart';
import '../domain/repositories/candidate_repository.dart';
import '../domain/repositories/resume_text_extractor.dart';

/// Composition root: the only place that binds domain interfaces to the
/// local, encrypted data-layer implementations.
final candidateVaultKeyStoreProvider = Provider<VaultKeyStore>(
  (ref) => SecureVaultKeyStore(const FlutterSecureStorage()),
);

final candidateRepositoryProvider = FutureProvider<CandidateRepository>((
  ref,
) async {
  final appDirectory = await getApplicationSupportDirectory();
  return LocalCandidateRepository(
    directory: Directory('${appDirectory.path}\\candidate_vault'),
    cipher: AesGcmVaultCipher(ref.watch(candidateVaultKeyStoreProvider)),
  );
});

final resumeTextExtractorProvider = Provider<ResumeTextExtractor>(
  (ref) => WindowsResumeTextExtractor(const MethodChannel('people/resume_ocr')),
);
