import 'package:despensa/domain/pantry/expiry.dart';
import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/presentation/pantry/item_tile.dart';
import 'package:flutter/material.dart';

const Key listaDespensaKey = Key('lista-despensa');

/// A segunda aba: tudo o que existe, na mesma ordem de urgência da primeira —
/// duas listas que discordassem da ordem seriam duas verdades sobre a mesma
/// despensa.
class DespensaView extends StatelessWidget {
  const DespensaView({required this.itens, required this.today, super.key});

  final List<PantryItem> itens;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const DespensaVazia();

    final List<PantryItem> lista = byUrgency(itens);

    return ListView.separated(
      key: listaDespensaKey,
      // Espaço para o FAB não cobrir o último item.
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: lista.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, int i) => ItemTile(item: lista[i], today: today),
    );
  }
}

/// Público porque a aba Vencendo também cai aqui: para quem nunca cadastrou
/// nada, "tudo dentro do prazo" mentiria sobre uma despensa que não existe.
class DespensaVazia extends StatelessWidget {
  const DespensaVazia({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.shopping_basket_outlined,
              size: 40,
              color: tema.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('Despensa vazia', style: tema.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Cadastre o primeiro item para começar.',
              textAlign: TextAlign.center,
              style: tema.textTheme.bodyMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
