import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class AuthenticateUserUseCase {
  const AuthenticateUserUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call() => _repository.signIn();
}
