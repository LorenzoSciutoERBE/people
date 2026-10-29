import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn();

  Future<AuthSession?> restoreSession();

  Future<void> signOut();
}
