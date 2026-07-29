import 'package:despensa/domain/pantry/product.dart';

/// Onde o item está guardado. Só `freezer` mexe na validade, e isso é assunto
/// de uma fatia futura (ADR 0004).
enum StorageLocation { pantry, fridge, freezer }

/// Descarta a hora. ADR 0004: validade é data pura.
///
/// A normalização acontece aqui, no limite do domínio, porque um único
/// `DateTime` com hora escondida quebra toda comparação de vencimento depois.
DateTime dateOnly(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);

/// Um pacote concreto na casa. Dois pacotes do mesmo produto com validades
/// diferentes são dois itens apontando para a mesma ficha.
class PantryItem {
  PantryItem({
    required this.id,
    required this.product,
    required DateTime expiresOn,
    required DateTime createdAt,
    this.quantity = 1,
    DateTime? purchasedOn,
    this.location,
    this.priceCents,
  })  : expiresOn = dateOnly(expiresOn),
        createdAt = dateOnly(createdAt),
        purchasedOn = purchasedOn == null ? null : dateOnly(purchasedOn) {
    if (quantity < 1) {
      throw ArgumentError.value(quantity, 'quantity', 'a mínima é 1');
    }
    final int? preco = priceCents;
    if (preco != null && preco < 0) {
      throw ArgumentError.value(preco, 'priceCents', 'não existe preço negativo');
    }
  }

  final String id;
  final Product product;

  /// Obrigatória. Item sem validade não existe neste produto.
  final DateTime expiresOn;

  /// Quantidade **inicial**, em unidades de embalagem (ADR 0003). A atual será
  /// esta menos a soma dos movimentos, quando a fatia `baixa` existir.
  final int quantity;

  final DateTime? purchasedOn;
  final StorageLocation? location;

  /// Inteiro em centavos, BRL (ADR 0003). Nenhuma tela lê isto ainda.
  final int? priceCents;

  /// Quando entrou na despensa. Só existe aqui porque é o começo da janela de
  /// vencimento quando não há data de compra — a hora é descartada como em
  /// toda data deste domínio.
  final DateTime createdAt;

  /// Início da janela de vencimento (ADR 0004): a compra quando informada,
  /// senão o cadastro.
  DateTime get windowStart => purchasedOn ?? createdAt;

  @override
  bool operator ==(Object other) =>
      other is PantryItem &&
      other.id == id &&
      other.product == product &&
      other.expiresOn == expiresOn &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(id, product, expiresOn, quantity);
}
