import 'package:despensa/data/auth/auth_error.dart';
import 'package:despensa/domain/auth/auth_repository.dart';
import 'package:despensa/domain/auth/email.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Binding do SDK: **só delegação**, zero lógica.
///
/// Não é medido por cobertura (ADR 0008) porque não há como exercitá-lo sem
/// rede. Em troca, nada de decisão pode entrar aqui — o que precisa ser pensado
/// vive em `auth_error.dart`, que é medido.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final supabase.GoTrueClient _auth;

  @override
  AuthUser? get currentUser => mapUser(_auth.currentUser);

  @override
  Stream<AuthUser?> watchUser() => _auth.onAuthStateChange
      .map((supabase.AuthState state) => mapUser(state.session?.user));

  @override
  Future<void> sendCode(Email email) => _guard(
        () => _auth.signInWithOtp(
          email: email.value,
          shouldCreateUser: true,
        ),
      );

  @override
  Future<void> verifyCode({
    required Email email,
    required String code,
  }) =>
      _guard(
        () => _auth.verifyOTP(
          email: email.value,
          token: code,
          type: supabase.OtpType.email,
        ),
        // Código errado e código expirado chegam como o mesmo erro de API, e é
        // assim que a interface os trata: sem revelar existência de conta.
        onApiError: AuthFailure.invalidCode,
      );

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  Future<void> _guard(
    Future<void> Function() acao, {
    AuthFailure onApiError = AuthFailure.unknown,
  }) async {
    try {
      await acao();
    } on Object catch (erro) {
      final AuthException? traduzido =
          translateAuthError(erro, onApiError: onApiError);
      if (traduzido == null) rethrow;
      throw traduzido;
    }
  }
}
