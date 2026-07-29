import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/domain/pantry/product.dart';

/// Falhas que a interface precisa distinguir — e só elas.
enum PantryFailure { network, unknown }

class PantryException implements Exception {
  const PantryException(this.failure);

  final PantryFailure failure;

  @override
  String toString() => 'PantryException(${failure.name})';
}

/// Porta da despensa. A casa não aparece em lugar nenhum desta interface: o
/// banco preenche `household_id` por default e a RLS valida (ADR 0002).
abstract interface class PantryRepository {
  /// Itens da casa. Mais recentes primeiro nesta fatia — ordenar por urgência é
  /// assunto da fatia `vencendo`.
  Stream<List<PantryItem>> watchItems();

  /// Grava um item, reaproveitando o produto da casa com esse nome ou criando-o
  /// se for a primeira vez (ADR 0006).
  Future<void> addItem({
    required ProductName name,
    required DateTime expiresOn,
    int quantity,
    DateTime? purchasedOn,
    StorageLocation? location,
    int? priceCents,
  });
}
