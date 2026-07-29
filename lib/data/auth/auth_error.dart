import 'dart:async';
import 'dart:io';

import 'package:despensa/domain/auth/auth_repository.dart';
// Prefixado: o Supabase também tem uma AuthException, e a do domínio é a que
// atravessa para a presentation.
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// A lógica da camada `data` mora aqui, separada do binding do SDK, porque
/// binding é delegação pura e isto não é: errar a tradução é um bug visível — o
/// usuário lê "não deu para continuar" em vez de "código inválido".
///
/// `null` significa **não é minha**: quem chamou deixa o erro subir, para bug de
/// programação não virar mensagem simpática na tela.
AuthException? translateAuthError(
  Object error, {
  AuthFailure onApiError = AuthFailure.unknown,
}) {
  return switch (error) {
    // Subtipos antes do tipo base: a ordem do switch é a ordem do teste.
    supabase.AuthRetryableFetchException() =>
      const AuthException(AuthFailure.network),
    SocketException() || TimeoutException() =>
      const AuthException(AuthFailure.network),
    supabase.AuthApiException() => AuthException(onApiError),
    supabase.AuthException() => const AuthException(AuthFailure.unknown),
    _ => null,
  };
}

/// Usuário do SDK para usuário do domínio.
AuthUser? mapUser(supabase.User? user) {
  if (user == null) return null;
  return AuthUser(id: user.id, email: user.email ?? '');
}
