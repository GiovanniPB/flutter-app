import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:despensa/presentation/pantry/cadastro_sheet.dart';
import 'package:despensa/presentation/pantry/item_tile.dart';
import 'package:despensa/presentation/pantry/pantry_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Key sairKey = Key('sair');
const Key adicionarKey = Key('adicionar');
const Key listaKey = Key('lista');

/// Nesta fatia a home **é** a despensa. A separação Vencendo / Despensa e a
/// barra de abas nascem na fatia `vencendo`: não se constrói barra de abas antes
/// de haver duas coisas para pôr nela.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PantryItem>> itens = ref.watch(pantryItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Despensa'),
        actions: <Widget>[
          IconButton(
            key: sairKey,
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: itens.when(
        data: (List<PantryItem> lista) =>
            lista.isEmpty ? const _Vazia() : _Lista(itens: lista),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _Falha(),
      ),
      floatingActionButton: FloatingActionButton(
        key: adicionarKey,
        tooltip: 'Adicionar item',
        onPressed: () => abrirCadastro(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.itens});

  final List<PantryItem> itens;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: listaKey,
      // Espaço para o FAB não cobrir o último item.
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: itens.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, int i) => ItemTile(item: itens[i]),
    );
  }
}

class _Vazia extends StatelessWidget {
  const _Vazia();

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

class _Falha extends StatelessWidget {
  const _Falha();

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Não deu para carregar a despensa agora.',
          textAlign: TextAlign.center,
          style: tema.textTheme.bodyMedium?.copyWith(
            color: tema.colorScheme.error,
          ),
        ),
      ),
    );
  }
}
