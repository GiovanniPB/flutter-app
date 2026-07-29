import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/domain/pantry/pantry_repository.dart';
import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:despensa/presentation/home/home_screen.dart';
import 'package:despensa/presentation/pantry/cadastro_sheet.dart';
import 'package:despensa/presentation/pantry/pantry_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/auth/entrar_screen_test.dart' show FakeAuthRepository;
import '../presentation/pantry/cadastro_sheet_test.dart'
    show FakePantryRepository, item;
import 'harness.dart';

Widget Function(Widget) _com(FakePantryRepository pantry) {
  return (Widget child) => ProviderScope(
        overrides: [
          pantryRepositoryProvider.overrideWithValue(pantry),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: child,
      );
}

Future<void> _abrirFolha(WidgetTester tester) async {
  await tester.tap(find.byKey(adicionarKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('home — despensa vazia', (WidgetTester tester) async {
    await pumpGoldenScreen(
      tester,
      const HomeScreen(),
      wrap: _com(FakePantryRepository()),
    );

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_vazia.png'),
    );
  }, tags: <String>['golden']);

  testWidgets('home — com itens', (WidgetTester tester) async {
    await pumpGoldenScreen(
      tester,
      const HomeScreen(),
      wrap: _com(
        FakePantryRepository(itens: <PantryItem>[
          item(
            id: 'i-1',
            nome: 'Arroz Tio João 5 kg',
            validade: DateTime(2027, 3, 12),
            local: StorageLocation.pantry,
          ),
          item(
            id: 'i-2',
            nome: 'Arroz Tio João 5 kg',
            validade: DateTime(2027, 8, 20),
            local: StorageLocation.pantry,
          ),
          item(
            id: 'i-3',
            nome: 'Leite integral 1 L',
            validade: DateTime(2026, 8, 2),
            quantidade: 12,
            local: StorageLocation.fridge,
          ),
        ]),
      ),
    );

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_com_itens.png'),
    );
  }, tags: <String>['golden']);

  testWidgets('cadastro — obrigatórios preenchidos', (WidgetTester tester) async {
    await pumpGoldenScreen(
      tester,
      const HomeScreen(),
      wrap: _com(FakePantryRepository()),
    );
    await _abrirFolha(tester);

    await tester.enterText(find.byKey(campoNomeKey), 'Arroz Tio João 5 kg');
    await tester.enterText(find.byKey(campoValidadeKey), '12/03/2027');
    await tester.pump(const Duration(milliseconds: 300));

    // O golden mostra o botão habilitado; esta linha é o que garante que ele
    // está, em vez de eu julgar pelo tom do pixel.
    expect(
      tester.widget<FilledButton>(find.byKey(botaoSalvarKey)).onPressed,
      isNotNull,
    );

    await expectLater(
      find.byType(CadastroSheet),
      matchesGoldenFile('goldens/cadastro_obrigatorios.png'),
    );
  }, tags: <String>['golden']);

  testWidgets('cadastro — opcionais abertos com erro de rede',
      (WidgetTester tester) async {
    await pumpGoldenScreen(
      tester,
      const HomeScreen(),
      wrap: _com(FakePantryRepository(failure: PantryFailure.network)),
    );
    await _abrirFolha(tester);

    await tester.tap(find.byKey(maisOpcoesKey));
    await tester.pump();
    await tester.enterText(find.byKey(campoNomeKey), 'Leite integral 1 L');
    await tester.enterText(find.byKey(campoValidadeKey), '02/08/2026');
    await tester.enterText(find.byKey(campoQuantidadeKey), '12');
    await tester.enterText(find.byKey(campoPrecoKey), '1299');
    await tester.pump();
    await tester.tap(find.byKey(botaoSalvarKey));
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(CadastroSheet),
      matchesGoldenFile('goldens/cadastro_opcionais_erro.png'),
    );
  }, tags: <String>['golden']);
}
