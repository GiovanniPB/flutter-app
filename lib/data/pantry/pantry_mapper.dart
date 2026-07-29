import 'dart:async';
import 'dart:io';

import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/domain/pantry/pantry_repository.dart';
import 'package:despensa/domain/pantry/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

/// Colunas pedidas na leitura da despensa. Fica aqui, junto do mapeamento, para
/// consulta e parser não desandarem em arquivos diferentes.
const String pantryItemColumns =
    'id, initial_quantity, expires_on, purchased_on, created_at, location, '
    'price_cents, products!inner(id, name, brand, ean, food_category)';

/// `date` do Postgres: sem hora, sem fuso (ADR 0004).
String isoDate(DateTime moment) {
  final DateTime dia = dateOnly(moment);
  return '${dia.year.toString().padLeft(4, '0')}'
      '-${dia.month.toString().padLeft(2, '0')}'
      '-${dia.day.toString().padLeft(2, '0')}';
}

/// Linha do banco para item do domínio.
PantryItem itemFromRow(Map<String, dynamic> row) {
  final Map<String, dynamic> produto = row['products'] as Map<String, dynamic>;
  final ProductName? nome = ProductName.tryParse(produto['name'] as String);
  if (nome == null) {
    throw StateError(
      'produto ${produto['id']} com nome em branco — a restrição '
      'products_name_not_blank deveria ter impedido',
    );
  }

  return PantryItem(
    id: row['id'] as String,
    product: Product(
      id: produto['id'] as String,
      name: nome,
      brand: produto['brand'] as String?,
      ean: produto['ean'] as String?,
      category: foodCategoryFrom(produto['food_category'] as String?),
    ),
    expiresOn: DateTime.parse(row['expires_on'] as String),
    // `created_at` é `timestamptz`, ao contrário das outras datas: chega em UTC
    // e vira o dia local antes de o domínio ver, porque a janela de vencimento
    // é contada em dias do fuso de quem abre o app (ADR 0004).
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    quantity: row['initial_quantity'] as int,
    purchasedOn: _dateOrNull(row['purchased_on'] as String?),
    location: storageLocationFrom(row['location'] as String?),
    priceCents: row['price_cents'] as int?,
  );
}

/// Payload do item. **Sem `household_id`**: o banco preenche por default e a
/// RLS valida (ADR 0002) — é o que mantém a casa fora do domínio.
Map<String, dynamic> itemRow({
  required String id,
  required String productId,
  required DateTime expiresOn,
  required int quantity,
  DateTime? purchasedOn,
  StorageLocation? location,
  int? priceCents,
}) {
  final String? compra = purchasedOn == null ? null : isoDate(purchasedOn);

  return <String, dynamic>{
    'id': id,
    'product_id': productId,
    'expires_on': isoDate(expiresOn),
    'initial_quantity': quantity,
    // Chave omitida quando o valor é nulo: opcional ausente não vira `null` no
    // payload, que o PostgREST trataria como "apague o que estiver lá".
    'purchased_on': ?compra,
    'location': ?location?.name,
    'price_cents': ?priceCents,
  };
}

Map<String, dynamic> productRow({
  required String id,
  required ProductName name,
}) {
  return <String, dynamic>{'id': id, 'name': name.value};
}

/// Valor desconhecido vira `null` em vez de exceção: o banco restringe a lista,
/// então isso só acontece com app velho contra schema novo — e nesse caso é
/// melhor mostrar o item sem o rótulo do que esconder a despensa inteira.
StorageLocation? storageLocationFrom(String? raw) {
  return StorageLocation.values
      .where((StorageLocation l) => l.name == raw)
      .firstOrNull;
}

FoodCategory? foodCategoryFrom(String? raw) {
  return FoodCategory.values
      .where((FoodCategory c) => c.name == raw)
      .firstOrNull;
}

DateTime? _dateOrNull(String? raw) =>
    raw == null ? null : DateTime.parse(raw);

/// `null` significa **não é minha**: quem chamou deixa o erro subir, para bug
/// de programação não virar mensagem simpática na tela.
PantryException? translatePantryError(Object error) {
  return switch (error) {
    SocketException() || TimeoutException() =>
      const PantryException(PantryFailure.network),
    supabase.PostgrestException() =>
      const PantryException(PantryFailure.unknown),
    _ => null,
  };
}
