import 'package:despensa/domain/pantry/expiry.dart';
import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/domain/pantry/product.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hoje é sempre injetado. `DateTime.now()` no domínio torna a janela de
/// vencimento intestável — é proibido por AGENTS.md, e este arquivo é a prova.
final DateTime hoje = DateTime(2026, 7, 29);

PantryItem _item({
  String id = 'i-1',
  String nome = 'Arroz Tio João 5 kg',
  required DateTime validade,
  DateTime? cadastro,
  DateTime? compra,
}) =>
    PantryItem(
      id: id,
      product: Product(id: 'p-$nome', name: ProductName.tryParse(nome)!),
      expiresOn: validade,
      createdAt: cadastro ?? hoje,
      purchasedOn: compra,
    );

void main() {
  group('daysBetween', () {
    test('conta dias inteiros, com sinal', () {
      expect(daysBetween(hoje, DateTime(2026, 8, 1)), 3);
      expect(daysBetween(hoje, hoje), 0);
      expect(daysBetween(hoje, DateTime(2026, 7, 24)), -5);
    });

    test('atravessa mês e ano sem tropeçar', () {
      expect(daysBetween(DateTime(2026, 12, 31), DateTime(2027, 1, 1)), 1);
      expect(daysBetween(DateTime(2028, 2, 28), DateTime(2028, 3, 1)), 2);
    });
  });

  group('janela de alerta', () {
    test('percentual puro quando cabe entre o piso e o teto', () {
      // 50 dias de janela × 20% = 10 dias.
      final PantryItem item = _item(
        compra: DateTime(2026, 7, 1),
        validade: DateTime(2026, 8, 20),
      );
      expect(item.alertDays, 10);
    });

    test('iogurte: janela de 5 dias cai no piso de 2', () {
      final PantryItem item = _item(
        compra: DateTime(2026, 7, 27),
        validade: DateTime(2026, 8, 1),
      );
      expect(item.alertDays, 2, reason: '20% de 5 dias é 1 — tarde demais');
    });

    test('feijão em lata: janela de 730 dias cai no teto de 30', () {
      final PantryItem item = _item(
        compra: DateTime(2026, 7, 29),
        validade: DateTime(2028, 7, 28),
      );
      expect(item.alertDays, 30, reason: '20% de 730 dias seriam 146');
    });

    test('janela não-positiva não explode: cai no piso', () {
      final PantryItem jaVencido = _item(
        compra: DateTime(2026, 7, 29),
        validade: DateTime(2026, 7, 20),
      );
      expect(jaVencido.alertDays, 2);
    });

    test('sem compra, a janela começa no cadastro', () {
      final PantryItem item = _item(
        cadastro: DateTime(2026, 7, 1),
        validade: DateTime(2026, 8, 20),
      );
      expect(item.alertDays, 10);
    });

    test('os três números vivem numa constante só', () {
      expect(kExpiryPolicy.fraction, 0.20);
      expect(kExpiryPolicy.minimumDays, 2);
      expect(kExpiryPolicy.maximumDays, 30);
    });
  });

  group('statusOn', () {
    test('validade anterior a hoje é vencido', () {
      expect(
        _item(validade: DateTime(2026, 7, 28)).statusOn(hoje),
        ExpiryStatus.expired,
      );
    });

    test('validade igual a hoje é vencendo, nunca vencido', () {
      // Ainda dá para salvar o alimento — e vencido significa que passou.
      expect(_item(validade: hoje).statusOn(hoje), ExpiryStatus.expiring);
    });

    test('dentro da janela é vencendo', () {
      final PantryItem item = _item(
        compra: DateTime(2026, 7, 1),
        validade: DateTime(2026, 8, 5), // janela 35 d → alerta 7 d; faltam 7
      );
      expect(item.alertDays, 7);
      expect(item.daysLeftOn(hoje), 7);
      expect(item.statusOn(hoje), ExpiryStatus.expiring);
    });

    test('um dia além da janela ainda é ok', () {
      final PantryItem item = _item(
        compra: DateTime(2026, 7, 1),
        validade: DateTime(2026, 8, 6), // janela 36 d → alerta 7 d; faltam 8
      );
      expect(item.statusOn(hoje), ExpiryStatus.ok);
    });

    test('o cálculo é da hora: o mesmo item muda de status quando o dia vira', () {
      // Janela de 3 dias → alerta de 2 (piso). O item não muda; o dia muda.
      final PantryItem item = _item(validade: DateTime(2026, 8, 1));
      expect(item.statusOn(DateTime(2026, 7, 29)), ExpiryStatus.ok);
      expect(item.statusOn(DateTime(2026, 7, 30)), ExpiryStatus.expiring);
      expect(item.statusOn(DateTime(2026, 8, 2)), ExpiryStatus.expired);
    });
  });

  group('byUrgency', () {
    test('quem vence antes vem antes, o que põe os vencidos no topo', () {
      final List<PantryItem> ordenada = byUrgency(<PantryItem>[
        _item(id: 'ok', validade: DateTime(2027, 3, 12)),
        _item(id: 'vencido', validade: DateTime(2026, 7, 24)),
        _item(id: 'hoje', validade: hoje),
        _item(id: 'vencido-antigo', validade: DateTime(2026, 7, 20)),
      ]);

      expect(
        ordenada.map((PantryItem i) => i.id),
        <String>['vencido-antigo', 'vencido', 'hoje', 'ok'],
      );
    });

    test('empate de data ordena por nome, para a lista não dançar', () {
      final List<PantryItem> ordenada = byUrgency(<PantryItem>[
        _item(id: 'b', nome: 'Queijo minas', validade: hoje),
        _item(id: 'a', nome: 'Pão de forma', validade: hoje),
      ]);

      expect(ordenada.map((PantryItem i) => i.id), <String>['a', 'b']);
    });

    test('não mexe na lista que recebeu', () {
      final List<PantryItem> original = <PantryItem>[
        _item(id: 'ok', validade: DateTime(2027, 3, 12)),
        _item(id: 'vencido', validade: DateTime(2026, 7, 24)),
      ];
      byUrgency(original);
      expect(original.first.id, 'ok');
    });

    test('lista vazia continua vazia', () {
      expect(byUrgency(const <PantryItem>[]), isEmpty);
    });
  });

  group('needingAttention', () {
    test('deixa de fora o que está ok', () {
      final List<PantryItem> atencao = needingAttention(<PantryItem>[
        _item(id: 'ok', validade: DateTime(2027, 3, 12)),
        _item(id: 'vencendo', validade: DateTime(2026, 7, 30)),
        _item(id: 'vencido', validade: DateTime(2026, 7, 24)),
      ], hoje);

      expect(
        atencao.map((PantryItem i) => i.id),
        <String>['vencido', 'vencendo'],
      );
    });

    test('despensa inteira em dia devolve lista vazia', () {
      final List<PantryItem> atencao = needingAttention(<PantryItem>[
        _item(id: 'ok', validade: DateTime(2027, 3, 12)),
      ], hoje);

      expect(atencao, isEmpty);
    });
  });
}
