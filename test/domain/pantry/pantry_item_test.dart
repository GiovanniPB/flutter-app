import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/domain/pantry/product.dart';
import 'package:flutter_test/flutter_test.dart';

Product _arroz() => Product(
      id: 'p-1',
      name: ProductName.tryParse('Arroz Tio João 5 kg')!,
    );

PantryItem _item({
  String id = 'i-1',
  DateTime? expiresOn,
  int quantity = 1,
  DateTime? purchasedOn,
  int? priceCents,
}) =>
    PantryItem(
      id: id,
      product: _arroz(),
      expiresOn: expiresOn ?? DateTime(2027, 3, 12),
      quantity: quantity,
      purchasedOn: purchasedOn,
      priceCents: priceCents,
    );

void main() {
  group('ProductName', () {
    test('apara mas preserva a caixa', () {
      expect(ProductName.tryParse('  Arroz Tio João  ')?.value, 'Arroz Tio João');
    });

    test('nome só de espaços não vira produto', () {
      expect(ProductName.tryParse('   '), isNull);
      expect(ProductName.tryParse(''), isNull);
      expect(ProductName.tryParse('\n\t'), isNull);
    });

    test('iguais depois de aparar são iguais', () {
      expect(ProductName.tryParse(' Leite '), ProductName.tryParse('Leite'));
      expect(
        ProductName.tryParse(' Leite ').hashCode,
        ProductName.tryParse('Leite').hashCode,
      );
    });
  });

  group('PantryItem', () {
    test('quantidade menor que 1 não é construível', () {
      expect(() => _item(quantity: 0), throwsArgumentError);
      expect(() => _item(quantity: -3), throwsArgumentError);
    });

    test('preço negativo não é construível', () {
      expect(() => _item(priceCents: -1), throwsArgumentError);
    });

    test('preço zero é válido — de graça não é o mesmo que sem preço', () {
      expect(_item(priceCents: 0).priceCents, 0);
      expect(_item().priceCents, isNull);
    });

    test('a hora é descartada na validade e na compra', () {
      // ADR 0004: um DateTime com hora escondida quebra toda comparação de
      // vencimento depois.
      final PantryItem item = _item(
        expiresOn: DateTime(2027, 3, 12, 23, 59, 59),
        purchasedOn: DateTime(2026, 7, 29, 14, 30),
      );
      expect(item.expiresOn, DateTime(2027, 3, 12));
      expect(item.purchasedOn, DateTime(2026, 7, 29));
    });

    test('a janela começa na compra quando ela existe', () {
      final PantryItem comCompra = _item(purchasedOn: DateTime(2026, 7, 1));
      expect(
        comCompra.windowStart(DateTime(2026, 7, 29)),
        DateTime(2026, 7, 1),
      );
    });

    test('sem data de compra, a janela começa no cadastro', () {
      expect(
        _item().windowStart(DateTime(2026, 7, 29, 9, 15)),
        DateTime(2026, 7, 29),
      );
    });

    test('dois itens do mesmo produto com validades diferentes são distintos', () {
      final PantryItem a = _item(id: 'i-1', expiresOn: DateTime(2027, 3, 12));
      final PantryItem b = _item(id: 'i-2', expiresOn: DateTime(2027, 8, 20));
      expect(a, isNot(b));
      expect(a.product, b.product, reason: 'mesma ficha');
    });

    test('o mesmo item é igual a si mesmo', () {
      expect(_item(), _item());
      expect(_item().hashCode, _item().hashCode);
    });
  });
}
