import 'dart:async';

import 'package:despensa/domain/auth/auth_repository.dart';
import 'package:despensa/domain/auth/email.dart';
import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:despensa/presentation/auth/entrar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.sendFailure, this.verifyFailure});

  final AuthFailure? sendFailure;
  final AuthFailure? verifyFailure;

  final StreamController<AuthUser?> _users =
      StreamController<AuthUser?>.broadcast();

  final List<String> enviados = <String>[];
  final List<String> verificados = <String>[];
  int saidas = 0;

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> watchUser() => _users.stream;

  @override
  Future<void> sendCode(Email email) async {
    enviados.add(email.value);
    if (sendFailure != null) throw AuthException(sendFailure!);
  }

  @override
  Future<void> verifyCode({
    required Email email,
    required String code,
  }) async {
    verificados.add(code);
    if (verifyFailure != null) throw AuthException(verifyFailure!);
  }

  @override
  Future<void> signOut() async => saidas++;
}

Future<void> _pump(WidgetTester tester, FakeAuthRepository repo,
    {Widget tela = const EntrarScreen()}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(home: tela),
    ),
  );
}

void main() {
  testWidgets('o botão só habilita com e-mail válido',
      (WidgetTester tester) async {
    final FakeAuthRepository repo = FakeAuthRepository();
    await _pump(tester, repo);

    FilledButton botao() => tester.widget<FilledButton>(find.byKey(botaoEnviarKey));
    expect(botao().onPressed, isNull, reason: 'começa desabilitado');

    await tester.enterText(find.byKey(campoEmailKey), 'ana@');
    await tester.pump();
    expect(botao().onPressed, isNull, reason: 'e-mail incompleto');

    await tester.enterText(find.byKey(campoEmailKey), 'ana@exemplo.com');
    await tester.pump();
    expect(botao().onPressed, isNotNull);
  });

  testWidgets('e-mail inválido não chega na rede', (WidgetTester tester) async {
    final FakeAuthRepository repo = FakeAuthRepository();
    await _pump(tester, repo);

    await tester.enterText(find.byKey(campoEmailKey), 'ana@exemplo');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pump();

    expect(repo.enviados, isEmpty);
  });

  testWidgets('enviar avança para o código, com o e-mail à vista',
      (WidgetTester tester) async {
    final FakeAuthRepository repo = FakeAuthRepository();
    await _pump(tester, repo);

    await tester.enterText(find.byKey(campoEmailKey), 'Ana@Exemplo.com ');
    await tester.pump();
    await tester.tap(find.byKey(botaoEnviarKey));
    await tester.pump();

    expect(repo.enviados, <String>['ana@exemplo.com'], reason: 'normalizado');
    expect(find.byKey(campoCodigoKey), findsOneWidget);
    expect(find.textContaining('Ana@Exemplo.com'), findsOneWidget);
  });

  testWidgets('código errado mostra erro e aceita nova tentativa',
      (WidgetTester tester) async {
    final FakeAuthRepository repo =
        FakeAuthRepository(verifyFailure: AuthFailure.invalidCode);
    await _pump(tester, repo);

    await tester.enterText(find.byKey(campoEmailKey), 'ana@exemplo.com');
    await tester.pump();
    await tester.tap(find.byKey(botaoEnviarKey));
    await tester.pump();

    await tester.enterText(find.byKey(campoCodigoKey), '419027');
    await tester.pump();

    expect(find.byKey(erroKey), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(erroKey)).data,
      'Código inválido ou expirado. Tente de novo.',
    );

    await tester.enterText(find.byKey(campoCodigoKey), '111111');
    await tester.pump();
    expect(repo.verificados, <String>['419027', '111111']);
  });

  testWidgets('falha de rede no envio não perde o e-mail digitado',
      (WidgetTester tester) async {
    final FakeAuthRepository repo =
        FakeAuthRepository(sendFailure: AuthFailure.network);
    await _pump(tester, repo);

    await tester.enterText(find.byKey(campoEmailKey), 'ana@exemplo.com');
    await tester.pump();
    await tester.tap(find.byKey(botaoEnviarKey));
    await tester.pump();

    expect(find.byKey(campoCodigoKey), findsNothing, reason: 'não avançou');
    expect(
      tester.widget<Text>(find.byKey(erroKey)).data,
      'Sem conexão. Tente de novo.',
    );
    expect(
      tester.widget<TextField>(find.byKey(campoEmailKey)).controller?.text,
      'ana@exemplo.com',
    );
  });

  // A home deixou de ser superfície de autenticação: virou a despensa. O teste
  // de `sair` mora agora em test/presentation/pantry/cadastro_sheet_test.dart,
  // junto da tela que o abriga.
}
