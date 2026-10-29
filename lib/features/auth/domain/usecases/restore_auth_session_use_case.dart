import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class RestoreAuthSessionUseCase {
  const RestoreAuthSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession?> call() => _repository.restoreSession();
}
