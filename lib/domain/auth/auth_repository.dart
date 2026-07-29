import 'package:despensa/domain/auth/email.dart';

/// Pessoa autenticada. O domínio não conhece Supabase.
class AuthUser {
  const AuthUser({required this.id, required this.email});

  final String id;
  final String email;

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}

/// As falhas que a interface precisa distinguir — e só elas.
enum AuthFailure {
  /// Código errado **ou** expirado. Um caso só, de propósito: separar os dois
  /// conta a um atacante se aquele e-mail tem conta.
  invalidCode,

  /// Não chegou no servidor.
  network,

  unknown,
}

class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException(${failure.name})';
}

/// Porta de autenticação. A implementação vive em `data`.
abstract interface class AuthRepository {
  /// Sessão atual, já resolvida — usada para decidir a primeira tela sem
  /// piscar a de login.
  AuthUser? get currentUser;

  Stream<AuthUser?> watchUser();

  /// Dispara o e-mail com o código de 6 dígitos, criando a conta se não
  /// existir. Não revela se o e-mail já tinha conta.
  Future<void> sendCode(Email email);

  Future<void> verifyCode({required Email email, required String code});

  Future<void> signOut();
}
