import 'package:despensa/domain/auth/auth_repository.dart';
import 'package:despensa/domain/auth/email.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// O que provou a fatia `entrar`, agora repetível (ADR 0010).
void main() {
  test('o código do e-mail abre a sessão', () async {
    final SessaoDeTeste sessao = await entrar();

    expect(sessao.contas.currentUser?.email, sessao.email);
  }, tags: <String>['integration']);

  test('código errado é invalidCode, e é disso que a tela depende', () async {
    final SessaoDeTeste sessao = await entrar();

    await expectLater(
      sessao.contas.verifyCode(
        email: Email.tryParse(sessao.email)!,
        code: '000000',
      ),
      throwsA(
        isA<AuthException>().having(
          (AuthException e) => e.failure,
          'failure',
          AuthFailure.invalidCode,
        ),
      ),
    );
  }, tags: <String>['integration']);

  test('o trigger provisiona exatamente uma casa', () async {
    final SessaoDeTeste sessao = await entrar();

    expect(
      await psql(
        'select count(*)::text from public.household_members '
        "where user_id = '${sessao.userId}'",
      ),
      '1',
    );
  }, tags: <String>['integration']);

  test('sair encerra a sessão', () async {
    final SessaoDeTeste sessao = await entrar();

    await sessao.contas.signOut();

    expect(sessao.contas.currentUser, isNull);
  }, tags: <String>['integration']);
}
