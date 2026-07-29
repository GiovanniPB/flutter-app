import 'package:despensa/data/pantry/pantry_mapper.dart';
import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/domain/pantry/pantry_repository.dart';
import 'package:despensa/domain/pantry/product.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:uuid/uuid.dart';

/// Binding do SDK: **só delegação**, zero decisão (ADR 0008). O que precisa ser
/// pensado vive em `pantry_mapper.dart`, que é medido por cobertura.
class SupabasePantryRepository implements PantryRepository {
  SupabasePantryRepository(this._db, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid();

  final supabase.SupabaseClient _db;
  final Uuid _uuid;

  @override
  Stream<List<PantryItem>> watchItems() {
    return _db
        .from('pantry_items')
        .stream(primaryKey: <String>['id'])
        .order('created_at', ascending: false)
        .asyncMap((List<Map<String, dynamic>> _) => _fetchItems());
  }

  Future<List<PantryItem>> _fetchItems() async {
    final List<Map<String, dynamic>> linhas = await _db
        .from('pantry_items')
        .select(pantryItemColumns)
        .order('created_at', ascending: false);
    return linhas.map(itemFromRow).toList();
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
    try {
      // Upsert que ignora duplicata, depois lê o id: dois passos sem ramo, em
      // vez de "existe? então insere" no cliente. O índice único
      // (household_id, name) é quem decide (ADR 0006).
      await _db.from('products').upsert(
            productRow(id: _uuid.v4(), name: name),
            onConflict: 'household_id,name',
            ignoreDuplicates: true,
          );

      final Map<String, dynamic> produto = await _db
          .from('products')
          .select('id')
          .eq('name', name.value)
          .not('household_id', 'is', null)
          .limit(1)
          .single();

      await _db.from('pantry_items').insert(
            itemRow(
              id: _uuid.v4(),
              productId: produto['id'] as String,
              expiresOn: expiresOn,
              quantity: quantity,
              purchasedOn: purchasedOn,
              location: location,
              priceCents: priceCents,
            ),
          );
    } on Object catch (erro) {
      final PantryException? traduzido = translatePantryError(erro);
      if (traduzido == null) rethrow;
      throw traduzido;
    }
  }
}
