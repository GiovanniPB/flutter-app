import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:despensa/presentation/home/home_screen.dart';
import 'package:despensa/presentation/pantry/pantry_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../presentation/auth/entrar_screen_test.dart' show FakeAuthRepository;
import '../presentation/pantry/cadastro_sheet_test.dart'
    show FakePantryRepository, hojeDeTeste, item;
import 'harness.dart';

/// "Hoje" fixo também aqui: sem isso o PNG mudaria sozinho amanhã, e o degrau 1
/// deixaria de ser um degrau.
Widget Function(Widget) _com(FakePantryRepository pantry) {
  return (Widget child) => ProviderScope(
        overrides: [
          pantryRepositoryProvider.overrideWithValue(pantry),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          todayProvider.overrideWithValue(hojeDeTeste),
        ],
        child: child,
      );
}

/// Um exemplar de cada situação em 29/07/2026.
List<PantryItem> _despensa() => <PantryItem>[
      item(
        id: 'i-1',
        nome: 'Leite integral 1 L',
        validade: DateTime(2026, 7, 24),
        quantidade: 2,
        local: StorageLocation.fridge,
      ),
      item(
        id: 'i-2',
        nome: 'Iogurte natural 170 g',
        validade: DateTime(2026, 7, 27),
        quantidade: 4,
        local: StorageLocation.fridge,
      ),
      item(
        id: 'i-3',
        nome: 'Pão de forma',
        validade: DateTime(2026, 7, 29),
        local: StorageLocation.pantry,
      ),
      item(
        id: 'i-4',
        nome: 'Queijo minas 500 g',
        validade: DateTime(2026, 7, 30),
        local: StorageLocation.fridge,
      ),
      item(
        id: 'i-5',
        nome: 'Presunto 200 g',
        validade: DateTime(2026, 8, 1),
        // Compra bem antes da validade: janela de 31 dias dá alerta de 6, então
        // este é o item que mostra a terceira aparência do selo, "em N dias".
        compra: DateTime(2026, 7, 1),
        local: StorageLocation.fridge,
      ),
      item(
        id: 'i-6',
        nome: 'Arroz Tio João 5 kg',
        validade: DateTime(2027, 3, 12),
        local: StorageLocation.pantry,
      ),
      item(
        id: 'i-7',
        nome: 'Feijão preto 1 kg',
        validade: DateTime(2027, 8, 20),
        quantidade: 3,
        local: StorageLocation.pantry,
      ),
    ];

/// O pump longo não é frescura: sem ele o respingo do toque na aba fica
/// congelado no PNG e eu julgaria a tela por um retângulo que não existe.
Future<void> _irParaDespensa(WidgetTester tester) async {
  await tester.tap(find.byKey(abaDespensaKey));
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUpAll(loadAppFonts);

  testWidgets('vencendo — vencidos no topo', (WidgetTester tester) async {
    await pumpGoldenScreen(
      tester,
      const HomeScreen(),
      wrap: _com(FakePantryRepository(itens: _despensa())),
    );

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/vencendo_com_itens.png'),
    );
  }, tags: <String>['golden']);

  testWidgets('vencendo — nada vencendo', (WidgetTester tester) async {
    await pumpGoldenScreen(
      tester,
      const HomeScreen(),
      wrap: _com(
        FakePantryRepository(itens: <PantryItem>[
          item(
            id: 'i-6',
            nome: 'Arroz Tio João 5 kg',
            validade: DateTime(2027, 3, 12),
            local: StorageLocation.pantry,
          ),
        ]),
      ),
    );

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/vencendo_vazia.png'),
    );
  }, tags: <String>['golden']);

  testWidgets('despensa — tudo, com selo', (WidgetTester tester) async {
    await pumpGoldenScreen(
      tester,
      const HomeScreen(),
      wrap: _com(FakePantryRepository(itens: _despensa())),
    );
    await _irParaDespensa(tester);

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/despensa_com_itens.png'),
    );
  }, tags: <String>['golden']);

  testWidgets('despensa — vazia', (WidgetTester tester) async {
    await pumpGoldenScreen(
      tester,
      const HomeScreen(),
      wrap: _com(FakePantryRepository()),
    );

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/despensa_vazia.png'),
    );
  }, tags: <String>['golden']);
}
