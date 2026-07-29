import 'dart:async';
import 'dart:io';

import 'package:despensa/data/pantry/pantry_mapper.dart';
import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/domain/pantry/pantry_repository.dart';
import 'package:despensa/domain/pantry/product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

Map<String, dynamic> _row({
  String? location,
  String? category,
  String? purchasedOn,
  int? priceCents,
  String name = 'Arroz Tio João 5 kg',
  String createdAt = '2026-07-29T12:00:00Z',
}) {
  return <String, dynamic>{
    'id': 'i-1',
    'initial_quantity': 2,
    'expires_on': '2027-03-12',
    'purchased_on': purchasedOn,
    'created_at': createdAt,
    'location': location,
    'price_cents': priceCents,
    'products': <String, dynamic>{
      'id': 'p-1',
      'name': name,
      'brand': null,
      'ean': null,
      'food_category': category,
    },
  };
}

void main() {
  group('itemFromRow', () {
    test('lê o essencial', () {
      final PantryItem item = itemFromRow(_row());
      expect(item.id, 'i-1');
      expect(item.quantity, 2);
      expect(item.expiresOn, DateTime(2027, 3, 12));
      expect(item.product.name.value, 'Arroz Tio João 5 kg');
      expect(item.purchasedOn, isNull);
      expect(item.priceCents, isNull);
    });

    test('created_at vira o dia local, sem hora', () {
      // É `timestamptz`, ao contrário das outras datas: sem `toLocal()` a
      // janela de vencimento contaria dias do fuso errado (ADR 0004).
      final DateTime local = DateTime.utc(2026, 7, 29, 12).toLocal();
      final PantryItem item =
          itemFromRow(_row(createdAt: '2026-07-29T12:00:00Z'));

      expect(item.createdAt, DateTime(local.year, local.month, local.day));
    });

    test('sem data de compra, a janela começa no cadastro', () {
      final PantryItem item = itemFromRow(_row(createdAt: '2026-07-29T12:00:00Z'));
      expect(item.windowStart, item.createdAt);
    });

    test('a coluna created_at é pedida na consulta', () {
      // O parser e a lista de colunas moram no mesmo arquivo justamente para
      // não desandarem; este teste é o que prende os dois.
      expect(pantryItemColumns, contains('created_at'));
    });

    test('lê os opcionais quando existem', () {
      final PantryItem item = itemFromRow(_row(
        location: 'fridge',
        category: 'dairy',
        purchasedOn: '2026-07-29',
        priceCents: 1299,
      ));
      expect(item.location, StorageLocation.fridge);
      expect(item.product.category, FoodCategory.dairy);
      expect(item.purchasedOn, DateTime(2026, 7, 29));
      expect(item.priceCents, 1299);
    });

    test('valor de enumeração desconhecido degrada para nulo', () {
      // App velho contra schema novo: melhor mostrar o item sem rótulo do que
      // esconder a despensa inteira.
      final PantryItem item =
          itemFromRow(_row(location: 'garagem', category: 'inventada'));
      expect(item.location, isNull);
      expect(item.product.category, isNull);
    });

    test('nome em branco no banco é erro de programação, não de usuário', () {
      expect(() => itemFromRow(_row(name: '   ')), throwsStateError);
    });
  });

  group('isoDate', () {
    test('formata como date do Postgres, descartando a hora', () {
      expect(isoDate(DateTime(2027, 3, 12, 23, 59)), '2027-03-12');
    });

    test('preenche mês e dia com zero', () {
      expect(isoDate(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('itemRow', () {
    test('não envia household_id — o banco preenche por default', () {
      final Map<String, dynamic> row = itemRow(
        id: 'i-9',
        productId: 'p-9',
        expiresOn: DateTime(2027, 3, 12),
        quantity: 1,
      );
      expect(row.containsKey('household_id'), isFalse);
      expect(row['id'], 'i-9');
      expect(row['product_id'], 'p-9');
      expect(row['expires_on'], '2027-03-12');
      expect(row['initial_quantity'], 1);
    });

    test('opcional ausente não vira chave nula no payload', () {
      final Map<String, dynamic> row = itemRow(
        id: 'i-9',
        productId: 'p-9',
        expiresOn: DateTime(2027, 3, 12),
        quantity: 1,
      );
      expect(row.containsKey('purchased_on'), isFalse);
      expect(row.containsKey('location'), isFalse);
      expect(row.containsKey('price_cents'), isFalse);
    });

    test('opcional presente vai no payload', () {
      final Map<String, dynamic> row = itemRow(
        id: 'i-9',
        productId: 'p-9',
        expiresOn: DateTime(2027, 3, 12),
        quantity: 12,
        purchasedOn: DateTime(2026, 7, 29, 14, 30),
        location: StorageLocation.freezer,
        priceCents: 0,
      );
      expect(row['purchased_on'], '2026-07-29');
      expect(row['location'], 'freezer');
      expect(row['price_cents'], 0);
      expect(row['initial_quantity'], 12);
    });
  });

  group('productRow', () {
    test('leva o nome aparado e nenhuma casa', () {
      final Map<String, dynamic> row = productRow(
        id: 'p-1',
        name: ProductName.tryParse('  Leite  ')!,
      );
      expect(row, <String, dynamic>{'id': 'p-1', 'name': 'Leite'});
    });
  });

  group('translatePantryError', () {
    test('falha de rede é rede', () {
      expect(
        translatePantryError(const SocketException('sem rota'))?.failure,
        PantryFailure.network,
      );
      expect(
        translatePantryError(TimeoutException('demorou'))?.failure,
        PantryFailure.network,
      );
    });

    test('erro do Postgrest é desconhecido', () {
      expect(
        translatePantryError(
          const supabase.PostgrestException(message: 'boom'),
        )?.failure,
        PantryFailure.unknown,
      );
    });

    test('erro que não é meu deve subir', () {
      expect(translatePantryError(StateError('bug meu')), isNull);
    });

    test('a falha aparece na mensagem de diagnóstico', () {
      expect(
        const PantryException(PantryFailure.network).toString(),
        contains('network'),
      );
    });
  });
}
