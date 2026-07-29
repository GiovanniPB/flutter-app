import 'dart:async';

import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/domain/pantry/pantry_repository.dart';
import 'package:despensa/domain/pantry/product.dart';
import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:despensa/presentation/home/home_screen.dart';
import 'package:despensa/presentation/pantry/cadastro_sheet.dart';
import 'package:despensa/presentation/pantry/item_tile.dart';
import 'package:despensa/presentation/pantry/pantry_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// O dublê de autenticação mora no teste da tela de entrar. Importar em vez de
// duplicar evita que os dois arquivos descrevam repositórios diferentes.
import '../auth/entrar_screen_test.dart' show FakeAuthRepository;

/// "Hoje" de todos os testes de tela. Fixo de propósito: com `DateTime.now()`
/// o selo de validade mudaria de texto conforme o dia em que a suíte roda.
final DateTime hojeDeTeste = DateTime(2026, 7, 29);

class FakePantryRepository implements PantryRepository {
  FakePantryRepository({this.failure, List<PantryItem>? itens})
      : _itens = List<PantryItem>.of(itens ?? const <PantryItem>[]);

  final PantryFailure? failure;
  final List<PantryItem> _itens;
  final StreamController<List<PantryItem>> _mudancas =
      StreamController<List<PantryItem>>.broadcast();

  final List<ProductName> nomesGravados = <ProductName>[];
  final List<int> quantidadesGravadas = <int>[];
  final List<StorageLocation?> locaisGravados = <StorageLocation?>[];
  final List<int?> precosGravados = <int?>[];

  @override
  Stream<List<PantryItem>> watchItems() async* {
    yield List<PantryItem>.of(_itens);
    yield* _mudancas.stream;
  }

  @override
  Future<void> addItem({
    required ProductName name,
    required DateTime expiresOn,
    int quantity = 1,
    DateTime? purchasedOn,
    StorageLocation? location,
    int? priceCents,
  }) async {
    if (failure != null) throw PantryException(failure!);

    nomesGravados.add(name);
    quantidadesGravadas.add(quantity);
    locaisGravados.add(location);
    precosGravados.add(priceCents);

    _itens.insert(
      0,
      PantryItem(
        id: 'i-${_itens.length + 1}',
        product: Product(id: 'p-${name.value}', name: name),
        expiresOn: expiresOn,
        // O banco carimba `now()`; aqui a data é fixa para o teste não depender
        // do dia em que roda.
        createdAt: hojeDeTeste,
        quantity: quantity,
        purchasedOn: purchasedOn,
        location: location,
        priceCents: priceCents,
      ),
    );
    _mudancas.add(List<PantryItem>.of(_itens));
  }
}

PantryItem item({
  required String id,
  required String nome,
  required DateTime validade,
  DateTime? criadoEm,
  DateTime? compra,
  int quantidade = 1,
  StorageLocation? local,
}) =>
    PantryItem(
      id: id,
      product: Product(id: 'p-$nome', name: ProductName.tryParse(nome)!),
      expiresOn: validade,
      createdAt: criadoEm ?? hojeDeTeste,
      purchasedOn: compra,
      quantity: quantidade,
      location: local,
    );

Future<void> pumpHome(
  WidgetTester tester, {
  required FakePantryRepository pantry,
  FakeAuthRepository? auth,
  DateTime? hoje,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pantryRepositoryProvider.overrideWithValue(pantry),
        authRepositoryProvider.overrideWithValue(auth ?? FakeAuthRepository()),
        todayProvider.overrideWithValue(hoje ?? hojeDeTeste),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pump();
}

/// Sem `pumpAndSettle`: cursor de `TextField` agenda quadro para sempre e o
/// settle nunca volta.
Future<void> abrir(WidgetTester tester) async {
  await tester.tap(find.byKey(adicionarKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// A home abre na aba Vencendo. Item tranquilo só existe na segunda aba — é
/// para lá que vão os testes que falam da despensa inteira.
Future<void> irParaDespensa(WidgetTester tester) async {
  await tester.tap(find.byKey(abaDespensaKey));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('despensa vazia convida a cadastrar', (WidgetTester tester) async {
    await pumpHome(tester, pantry: FakePantryRepository());

    expect(find.text('Despensa vazia'), findsOneWidget);
    expect(find.text('Cadastre o primeiro item para começar.'), findsOneWidget);
    expect(find.byKey(adicionarKey), findsOneWidget);
  });

  testWidgets('mesmo produto, validades diferentes, duas linhas',
      (WidgetTester tester) async {
    await pumpHome(
      tester,
      pantry: FakePantryRepository(itens: <PantryItem>[
        item(id: 'i-1', nome: 'Arroz Tio João 5 kg', validade: DateTime(2027, 3, 12)),
        item(id: 'i-2', nome: 'Arroz Tio João 5 kg', validade: DateTime(2027, 8, 20)),
      ]),
    );
    await irParaDespensa(tester);

    expect(find.text('Arroz Tio João 5 kg'), findsNWidgets(2));
    expect(find.textContaining('vence 12/03/2027'), findsOneWidget);
    expect(find.textContaining('vence 20/08/2027'), findsOneWidget);
  });

  testWidgets('salvar só habilita com nome e validade',
      (WidgetTester tester) async {
    await pumpHome(tester, pantry: FakePantryRepository());
    await abrir(tester);

    FilledButton salvar() =>
        tester.widget<FilledButton>(find.byKey(botaoSalvarKey));
    expect(salvar().onPressed, isNull, reason: 'começa desabilitado');

    await tester.enterText(find.byKey(campoNomeKey), 'Arroz Tio João 5 kg');
    await tester.pump();
    expect(salvar().onPressed, isNull, reason: 'falta validade');

    await tester.enterText(find.byKey(campoValidadeKey), '12/03/2027');
    await tester.pump();
    expect(salvar().onPressed, isNotNull);
  });

  testWidgets('data que não existe no calendário não habilita salvar',
      (WidgetTester tester) async {
    await pumpHome(tester, pantry: FakePantryRepository());
    await abrir(tester);

    await tester.enterText(find.byKey(campoNomeKey), 'Leite');
    await tester.enterText(find.byKey(campoValidadeKey), '31/02/2027');
    await tester.pump();

    // DateTime(2027, 2, 31) viraria 03/03 em silêncio.
    expect(
      tester.widget<FilledButton>(find.byKey(botaoSalvarKey)).onPressed,
      isNull,
    );
  });

  testWidgets('salvar fecha a folha e o item aparece na lista',
      (WidgetTester tester) async {
    final FakePantryRepository pantry = FakePantryRepository();
    await pumpHome(tester, pantry: pantry);
    await abrir(tester);

    await tester.enterText(find.byKey(campoNomeKey), '  Arroz Tio João 5 kg ');
    await tester.enterText(find.byKey(campoValidadeKey), '12/03/2027');
    await tester.pump();
    await tester.tap(find.byKey(botaoSalvarKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(campoNomeKey), findsNothing, reason: 'a folha fechou');
    expect(pantry.nomesGravados.single.value, 'Arroz Tio João 5 kg',
        reason: 'aparado');
    expect(pantry.quantidadesGravadas.single, 1, reason: 'padrão');

    await irParaDespensa(tester);
    expect(find.text('Arroz Tio João 5 kg'), findsOneWidget);
    expect(find.textContaining('1 un · vence 12/03/2027'), findsOneWidget);
  });

  testWidgets('opcionais nascem recolhidos e gravam quando preenchidos',
      (WidgetTester tester) async {
    final FakePantryRepository pantry = FakePantryRepository();
    await pumpHome(tester, pantry: pantry);
    await abrir(tester);

    expect(find.byKey(campoQuantidadeKey), findsNothing);

    await tester.tap(find.byKey(maisOpcoesKey));
    await tester.pump();
    expect(find.byKey(campoQuantidadeKey), findsOneWidget);

    await tester.enterText(find.byKey(campoNomeKey), 'Leite integral 1 L');
    await tester.enterText(find.byKey(campoValidadeKey), '02/08/2026');
    await tester.enterText(find.byKey(campoQuantidadeKey), '12');
    await tester.enterText(find.byKey(campoPrecoKey), '1299');
    await tester.pump();

    // Centavos por dentro, moeda por fora: quem digita 1299 vê 12,99.
    expect(
      tester.widget<TextField>(find.byKey(campoPrecoKey)).controller?.text,
      '12,99',
    );

    await tester.tap(find.byKey(botaoSalvarKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(pantry.quantidadesGravadas.single, 12);
    expect(pantry.precosGravados.single, 1299);

    await irParaDespensa(tester);
    expect(find.textContaining('12 un · vence 02/08/2026'), findsOneWidget);
  });

  testWidgets('falha de rede mostra erro e não perde o que foi digitado',
      (WidgetTester tester) async {
    await pumpHome(
      tester,
      pantry: FakePantryRepository(failure: PantryFailure.network),
    );
    await abrir(tester);

    await tester.enterText(find.byKey(campoNomeKey), 'Arroz Tio João 5 kg');
    await tester.enterText(find.byKey(campoValidadeKey), '12/03/2027');
    await tester.pump();
    await tester.tap(find.byKey(botaoSalvarKey));
    await tester.pump();

    expect(find.byKey(campoNomeKey), findsOneWidget, reason: 'a folha ficou');
    expect(
      tester.widget<Text>(find.byKey(erroCadastroKey)).data,
      'Sem conexão. O que você digitou está aqui.',
    );
    expect(
      tester.widget<TextField>(find.byKey(campoNomeKey)).controller?.text,
      'Arroz Tio João 5 kg',
    );
  });

  testWidgets('sair chama o repositório de autenticação',
      (WidgetTester tester) async {
    final FakeAuthRepository auth = FakeAuthRepository();
    await pumpHome(tester, pantry: FakePantryRepository(), auth: auth);

    await tester.tap(find.byKey(sairKey));
    await tester.pump();

    expect(auth.saidas, 1);
  });

  group('centavosDe', () {
    test('dígitos viram centavos', () {
      expect(centavosDe('1299'), 1299);
      expect(centavosDe('12,99'), 1299);
      expect(centavosDe('5'), 5);
    });

    test('campo vazio é sem preço, não de graça', () {
      expect(centavosDe(''), isNull);
      expect(centavosDe('abc'), isNull);
      expect(centavosDe('0'), 0, reason: 'zero digitado é zero de verdade');
    });

    test('formata a moeda a partir dos centavos', () {
      expect(reaisDe(1299), '12,99');
      expect(reaisDe(5), '0,05');
      expect(reaisDe(100), '1,00');
    });
  });

  group('parseBrDate', () {
    test('lê data completa', () {
      expect(parseBrDate('12/03/2027'), DateTime(2027, 3, 12));
    });

    test('recusa o que não é data', () {
      for (final String cru in <String>[
        '',
        '12/03',
        '12/03/27',
        '31/02/2027',
        '00/01/2027',
        '12/13/2027',
        'abc',
      ]) {
        expect(parseBrDate(cru), isNull, reason: 'aceitou "$cru"');
      }
    });
  });
}
