import 'package:despensa/data/pantry/supabase_pantry_repository.dart';
import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/domain/pantry/product.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// O que provou a fatia `cadastro-manual`, agora repetível (ADR 0010).
void main() {
  test('o item cadastrado sobrevive a reabrir o app', () async {
    final SessaoDeTeste sessao = await entrar();
    final SupabasePantryRepository despensa = sessao.despensaNova();
    final ProductName arroz = ProductName.tryParse('Arroz Tio João 5 kg')!;

    await despensa.addItem(
      name: arroz,
      expiresOn: DateTime(2027, 3, 12),
      location: StorageLocation.pantry,
      priceCents: 2599,
    );
    await despensa.addItem(
      name: arroz,
      expiresOn: DateTime(2027, 8, 20),
      quantity: 3,
    );

    // Cliente novo: é assim que se simula o app fechado e aberto.
    final List<PantryItem> itens = await sessao.lerDespensa();

    expect(itens.length, 2);
    expect(
      itens.map((PantryItem i) => i.expiresOn).toSet(),
      <DateTime>{DateTime(2027, 3, 12), DateTime(2027, 8, 20)},
    );
  }, tags: <String>['integration']);

  test('dois itens do mesmo nome reaproveitam uma ficha só', () async {
    final SessaoDeTeste sessao = await entrar();
    final SupabasePantryRepository despensa = sessao.despensaNova();
    final ProductName arroz = ProductName.tryParse('Arroz Tio João 5 kg')!;

    await despensa.addItem(name: arroz, expiresOn: DateTime(2027, 3, 12));
    await despensa.addItem(name: arroz, expiresOn: DateTime(2027, 8, 20));

    final List<PantryItem> itens = await sessao.lerDespensa();
    expect(
      itens.map((PantryItem i) => i.product.id).toSet().length,
      1,
      reason: 'ADR 0006: o produto é reaproveitado, não duplicado',
    );

    // O upsert quebrou de verdade aqui uma vez: índice único parcial não serve
    // como alvo de `on conflict`.
    expect(
      await psql(
        'select count(*)::text from public.products p '
        'join public.household_members m on m.household_id = p.household_id '
        "where m.user_id = '${sessao.userId}'",
      ),
      '1',
    );
  }, tags: <String>['integration']);

  test('preço e local sobrevivem ao ciclo', () async {
    final SessaoDeTeste sessao = await entrar();

    await sessao.despensaNova().addItem(
          name: ProductName.tryParse('Leite integral 1 L')!,
          expiresOn: DateTime(2026, 8, 2),
          quantity: 12,
          purchasedOn: DateTime(2026, 7, 29),
          location: StorageLocation.fridge,
          priceCents: 1299,
        );

    final PantryItem item = (await sessao.lerDespensa()).single;
    expect(item.quantity, 12);
    expect(item.priceCents, 1299);
    expect(item.location, StorageLocation.fridge);
    expect(item.purchasedOn, DateTime(2026, 7, 29));
    expect(item.expiresOn, DateTime(2026, 8, 2));
  }, tags: <String>['integration']);

  test('a casa gravada é a da sessão, sem o cliente enviá-la', () async {
    final SessaoDeTeste sessao = await entrar();

    await sessao.despensaNova().addItem(
          name: ProductName.tryParse('Feijão carioca 1 kg')!,
          expiresOn: DateTime(2027, 1, 1),
        );

    expect(
      await psql(
        'select distinct household_id::text from public.pantry_items i '
        'join public.household_members m on m.household_id = i.household_id '
        "where m.user_id = '${sessao.userId}'",
      ),
      await psql(
        'select household_id::text from public.household_members '
        "where user_id = '${sessao.userId}'",
      ),
    );
  }, tags: <String>['integration']);

  test('uma casa não vê a despensa da outra', () async {
    final SessaoDeTeste ana = await entrar();
    final SessaoDeTeste bruno = await entrar();

    await ana.despensaNova().addItem(
          name: ProductName.tryParse('Café 500 g')!,
          expiresOn: DateTime(2027, 5, 5),
        );

    expect(await ana.lerDespensa(), hasLength(1));
    expect(await bruno.lerDespensa(), isEmpty, reason: 'RLS');
  }, tags: <String>['integration']);
}
