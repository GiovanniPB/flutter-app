/// Nome de produto válido: sobra algo depois de aparar.
///
/// Existe como tipo para que a tela não consiga enviar `'   '` ao banco — a
/// restrição `products_name_not_blank` é a segunda linha de defesa, não a
/// primeira.
class ProductName {
  const ProductName._(this.value);

  /// Já aparado. A caixa é preservada: quem digita "Arroz" quer ver "Arroz".
  final String value;

  static ProductName? tryParse(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return ProductName._(trimmed);
  }

  @override
  bool operator ==(Object other) =>
      other is ProductName && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Lista fixa, definida por nós (ADR 0006). Serve só para sugerir prazo ao
/// congelar, numa fatia futura — nenhuma tela escolhe categoria hoje.
enum FoodCategory { dairy, meat, produce, grocery, frozen, beverage, other }

/// A ficha do produto. Não tem validade nem quantidade — isso é do item.
class Product {
  const Product({
    required this.id,
    required this.name,
    this.brand,
    this.ean,
    this.category,
  });

  final String id;
  final ProductName name;
  final String? brand;

  /// Presente só em produto canônico, que nenhuma tela cria ainda (ADR 0006).
  final String? ean;

  final FoodCategory? category;

  @override
  bool operator ==(Object other) =>
      other is Product && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
