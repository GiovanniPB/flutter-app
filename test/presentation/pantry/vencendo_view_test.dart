import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/presentation/home/home_screen.dart';
import 'package:despensa/presentation/pantry/cadastro_sheet.dart';
import 'package:despensa/presentation/pantry/despensa_view.dart';
import 'package:despensa/presentation/pantry/expiry_badge.dart';
import 'package:despensa/presentation/pantry/vencendo_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'cadastro_sheet_test.dart'
    show FakePantryRepository, abrir, hojeDeTeste, irParaDespensa, item, pumpHome;

/// Uma despensa com um exemplar de cada situação, contada a partir de
/// 29/07/2026. As janelas curtas caem no piso de 2 dias (ADR 0004).
List<PantryItem> _despensa() => <PantryItem>[
      item(id: 'ok', nome: 'Arroz Tio João 5 kg', validade: DateTime(2027, 3, 12)),
      item(id: 'amanha', nome: 'Queijo minas 500 g', validade: DateTime(2026, 7, 30)),
      item(id: 'vencido', nome: 'Iogurte natural 170 g', validade: DateTime(2026, 7, 27)),
      item(id: 'hoje', nome: 'Pão de forma', validade: DateTime(2026, 7, 29)),
      item(id: 'vencido-antigo', nome: 'Leite integral 1 L', validade: DateTime(2026, 7, 20)),
    ];

double _alturaDe(WidgetTester tester, String texto) =>
    tester.getTopLeft(find.text(texto)).dy;

void main() {
  testWidgets('o app abre na aba Vencendo', (WidgetTester tester) async {
    await pumpHome(
      tester,
      pantry: FakePantryRepository(itens: _despensa()),
    );

    expect(find.byKey(listaVencendoKey), findsOneWidget);
    expect(find.byKey(listaDespensaKey), findsNothing);
  });

  testWidgets('vencidos ficam acima, sob um cabeçalho próprio',
      (WidgetTester tester) async {
    await pumpHome(tester, pantry: FakePantryRepository(itens: _despensa()));

    expect(find.text('VENCIDOS'), findsOneWidget);
    expect(find.text('VENCENDO'), findsOneWidget);
    expect(_alturaDe(tester, 'VENCIDOS'), lessThan(_alturaDe(tester, 'VENCENDO')));

    // Mais antigo primeiro dentro dos vencidos; o que vence hoje vem depois.
    expect(
      _alturaDe(tester, 'Leite integral 1 L'),
      lessThan(_alturaDe(tester, 'Iogurte natural 170 g')),
    );
    expect(
      _alturaDe(tester, 'Iogurte natural 170 g'),
      lessThan(_alturaDe(tester, 'Pão de forma')),
    );
  });

  testWidgets('o que está tranquilo não aparece na aba Vencendo',
      (WidgetTester tester) async {
    await pumpHome(tester, pantry: FakePantryRepository(itens: _despensa()));

    expect(find.text('Arroz Tio João 5 kg'), findsNothing);
  });

  testWidgets('o selo diz quanto falta, em texto relativo',
      (WidgetTester tester) async {
    await pumpHome(tester, pantry: FakePantryRepository(itens: _despensa()));

    expect(find.text('venceu há 9 dias'), findsOneWidget);
    expect(find.text('venceu há 2 dias'), findsOneWidget);
    expect(find.text('vence hoje'), findsOneWidget);
    expect(find.text('vence amanhã'), findsOneWidget);
  });

  testWidgets('o contador mostra quantos exigem atenção',
      (WidgetTester tester) async {
    await pumpHome(tester, pantry: FakePantryRepository(itens: _despensa()));

    expect(find.byKey(contadorVencendoKey), findsOneWidget);
    expect(find.text('4'), findsOneWidget, reason: 'cinco itens, um deles ok');
  });

  testWidgets('o contador some quando não há nada vencendo',
      (WidgetTester tester) async {
    await pumpHome(
      tester,
      pantry: FakePantryRepository(itens: <PantryItem>[
        item(id: 'ok', nome: 'Arroz Tio João 5 kg', validade: DateTime(2027, 3, 12)),
      ]),
    );

    expect(find.byKey(contadorVencendoKey), findsNothing);
  });

  testWidgets('nada vencendo é sucesso, não erro', (WidgetTester tester) async {
    await pumpHome(
      tester,
      pantry: FakePantryRepository(itens: <PantryItem>[
        item(id: 'ok', nome: 'Arroz Tio João 5 kg', validade: DateTime(2027, 3, 12)),
      ]),
    );

    expect(find.text('Nada vencendo'), findsOneWidget);
    expect(find.text('Tudo na despensa está dentro do prazo.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('despensa vazia convida a cadastrar já na primeira aba',
      (WidgetTester tester) async {
    // Quem nunca cadastrou nada não tem prazo nenhum para estar em dia.
    await pumpHome(tester, pantry: FakePantryRepository());

    expect(find.byType(DespensaVazia), findsOneWidget);
    expect(find.text('Despensa vazia'), findsOneWidget);
    expect(find.text('Nada vencendo'), findsNothing);
  });

  testWidgets('a aba Despensa mostra tudo, na mesma ordem de urgência',
      (WidgetTester tester) async {
    await pumpHome(tester, pantry: FakePantryRepository(itens: _despensa()));
    await irParaDespensa(tester);

    expect(find.byKey(listaDespensaKey), findsOneWidget);
    expect(find.text('Arroz Tio João 5 kg'), findsOneWidget, reason: 'o ok está aqui');
    expect(find.text('venceu há 9 dias'), findsOneWidget, reason: 'o selo veio junto');
    expect(
      _alturaDe(tester, 'Leite integral 1 L'),
      lessThan(_alturaDe(tester, 'Arroz Tio João 5 kg')),
    );
  });

  testWidgets('o FAB abre o cadastro também na aba Despensa',
      (WidgetTester tester) async {
    await pumpHome(tester, pantry: FakePantryRepository(itens: _despensa()));
    await irParaDespensa(tester);
    await abrir(tester);

    expect(find.byKey(campoNomeKey), findsOneWidget);
  });

  group('ExpiryBadge', () {
    Future<void> pumpSelo(WidgetTester tester, PantryItem alvo) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ExpiryBadge(item: alvo, today: hojeDeTeste)),
          ),
        );

    testWidgets('item tranquilo não desenha selo nenhum',
        (WidgetTester tester) async {
      await pumpSelo(
        tester,
        item(id: 'ok', nome: 'Arroz', validade: DateTime(2027, 3, 12)),
      );

      expect(find.byType(Text), findsNothing, reason: 'a ausência é a aparência');
    });

    testWidgets('item vencido desenha selo', (WidgetTester tester) async {
      await pumpSelo(
        tester,
        item(id: 'v', nome: 'Leite', validade: DateTime(2026, 7, 20)),
      );

      expect(find.text('venceu há 9 dias'), findsOneWidget);
    });
  });

  group('expiryLabel', () {
    test('fala em dias, com nome para os vizinhos de hoje', () {
      expect(expiryLabel(0), 'vence hoje');
      expect(expiryLabel(1), 'vence amanhã');
      expect(expiryLabel(-1), 'venceu ontem');
      expect(expiryLabel(3), 'em 3 dias');
      expect(expiryLabel(-5), 'venceu há 5 dias');
    });
  });
}
