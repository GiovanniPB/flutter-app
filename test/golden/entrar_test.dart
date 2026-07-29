import 'package:despensa/domain/auth/auth_repository.dart';
import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:despensa/presentation/auth/entrar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// O dublê mora no teste de widget. Importar em vez de duplicar evita que os
// dois arquivos descrevam repositórios diferentes com o mesmo nome.
import '../presentation/auth/entrar_screen_test.dart' show FakeAuthRepository;
import 'harness.dart';

Widget Function(Widget) _com(FakeAuthRepository repo) {
  return (Widget child) => ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
        child: child,
      );
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('entrar — pedir e-mail', (WidgetTester tester) async {
    await pumpGoldenScreen(
      tester,
      const EntrarScreen(),
      wrap: _com(FakeAuthRepository()),
    );

    await expectLater(
      find.byType(EntrarScreen),
      matchesGoldenFile('goldens/entrar_email.png'),
    );
  }, tags: <String>['golden']);

  testWidgets('entrar — código recusado', (WidgetTester tester) async {
    await pumpGoldenScreen(
      tester,
      const EntrarScreen(),
      wrap: _com(FakeAuthRepository(verifyFailure: AuthFailure.invalidCode)),
    );

    await tester.enterText(find.byKey(campoEmailKey), 'giovanni@exemplo.com');
    await tester.pump();
    await tester.tap(find.byKey(botaoEnviarKey));
    await tester.pump();
    await tester.enterText(find.byKey(campoCodigoKey), '419027');
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(EntrarScreen),
      matchesGoldenFile('goldens/entrar_codigo.png'),
    );
  }, tags: <String>['golden']);

  // O golden da home mudou de arquivo junto com a tela: ela agora é a despensa,
  // e vive em test/golden/cadastro_test.dart.
}
