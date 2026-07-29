import 'dart:async';
import 'dart:io';

import 'package:despensa/data/auth/auth_error.dart';
import 'package:despensa/domain/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

supabase.User _user({String? email}) => supabase.User(
      id: 'u-1',
      appMetadata: const <String, dynamic>{},
      userMetadata: const <String, dynamic>{},
      aud: 'authenticated',
      email: email,
      createdAt: '2026-07-29T00:00:00Z',
    );

void main() {
  group('translateAuthError', () {
    test('erro de API vira a falha que a operação pediu', () {
      expect(
        translateAuthError(
          const supabase.AuthApiException('Token has expired'),
          onApiError: AuthFailure.invalidCode,
        )?.failure,
        AuthFailure.invalidCode,
      );
    });

    test('sem onApiError, erro de API é desconhecido', () {
      expect(
        translateAuthError(const supabase.AuthApiException('boom'))?.failure,
        AuthFailure.unknown,
      );
    });

    test('falha de rede é rede, venha de onde vier', () {
      expect(
        translateAuthError(supabase.AuthRetryableFetchException())?.failure,
        AuthFailure.network,
      );
      expect(
        translateAuthError(const SocketException('sem rota'))?.failure,
        AuthFailure.network,
      );
      expect(
        translateAuthError(TimeoutException('demorou'))?.failure,
        AuthFailure.network,
      );
    });

    test('retryable ganha de AuthApiException na ordem do switch', () {
      // Regressão: se o caso base subir no switch, toda queda de rede passa a
      // ser lida como código inválido.
      expect(
        translateAuthError(
          supabase.AuthRetryableFetchException(),
          onApiError: AuthFailure.invalidCode,
        )?.failure,
        AuthFailure.network,
      );
    });

    test('AuthException genérica é desconhecida', () {
      expect(
        translateAuthError(
          const supabase.AuthException('outra coisa'),
        )?.failure,
        AuthFailure.unknown,
      );
    });

    test('erro que não é de autenticação deve subir, não ser traduzido', () {
      expect(translateAuthError(StateError('bug meu')), isNull);
      expect(translateAuthError(ArgumentError('bug meu')), isNull);
    });

    test('a falha aparece na mensagem de diagnóstico', () {
      expect(
        const AuthException(AuthFailure.invalidCode).toString(),
        contains('invalidCode'),
      );
    });
  });

  group('mapUser', () {
    test('sessão ausente é usuário nulo', () {
      expect(mapUser(null), isNull);
    });

    test('usuário do SDK vira usuário do domínio', () {
      expect(
        mapUser(_user(email: 'ana@exemplo.com')),
        const AuthUser(id: 'u-1', email: 'ana@exemplo.com'),
      );
    });

    test('usuário sem e-mail não quebra o mapeamento', () {
      expect(mapUser(_user())?.email, '');
    });

    test('iguais têm o mesmo hashCode', () {
      // Riverpod compara por igualdade para decidir se reconstrói a tela.
      expect(
        mapUser(_user(email: 'ana@exemplo.com')).hashCode,
        mapUser(_user(email: 'ana@exemplo.com')).hashCode,
      );
    });
  });
}
