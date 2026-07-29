import 'package:despensa/domain/pantry/expiry.dart';
import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/presentation/auth/entrar_providers.dart';
import 'package:despensa/presentation/pantry/cadastro_sheet.dart';
import 'package:despensa/presentation/pantry/despensa_view.dart';
import 'package:despensa/presentation/pantry/pantry_providers.dart';
import 'package:despensa/presentation/pantry/vencendo_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Key sairKey = Key('sair');
const Key adicionarKey = Key('adicionar');
const Key abaVencendoKey = Key('aba-vencendo');
const Key abaDespensaKey = Key('aba-despensa');
const Key contadorVencendoKey = Key('contador-vencendo');

/// Duas abas: **Vencendo** abre o app, Despensa fica a um toque. São duas
/// listas do mesmo tipo de conteúdo — o caso de uso de `TabBar`. A lista de
/// compras é outro pilar e vai pedir outro nível de navegação quando chegar.
///
/// Carregamento e falha são resolvidos **aqui**, uma vez: as abas são widgets
/// puros que recebem a lista pronta, o que as torna testáveis sem provider.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PantryItem>> itens = ref.watch(pantryItemsProvider);
    final DateTime hoje = ref.watch(todayProvider);
    final int emAtencao = itens.maybeWhen(
      data: (List<PantryItem> lista) => needingAttention(lista, hoje).length,
      orElse: () => 0,
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                key: abaVencendoKey,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('Vencendo'),
                    // Some no zero: contador de nada é ruído.
                    if (emAtencao > 0) ...<Widget>[
                      const SizedBox(width: 8),
                      Badge(
                        key: contadorVencendoKey,
                        label: Text('$emAtencao'),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(key: abaDespensaKey, text: 'Despensa'),
            ],
          ),
        ),
        body: itens.when(
          data: (List<PantryItem> lista) => TabBarView(
            children: <Widget>[
              VencendoView(itens: lista, today: hoje),
              DespensaView(itens: lista, today: hoje),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _Falha(),
        ),
        floatingActionButton: FloatingActionButton(
          key: adicionarKey,
          tooltip: 'Adicionar item',
          onPressed: () => abrirCadastro(context),
          child: const Icon(Icons.add),
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
