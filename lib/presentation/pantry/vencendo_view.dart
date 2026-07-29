import 'package:despensa/domain/pantry/expiry.dart';
import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/presentation/pantry/despensa_view.dart';
import 'package:despensa/presentation/pantry/item_tile.dart';
import 'package:flutter/material.dart';

const Key listaVencendoKey = Key('lista-vencendo');

/// A aba que abre o app: só o que exige atenção.
///
/// Recebe a despensa inteira e pergunta ao domínio o que fazer com ela — quem
/// decide o que é urgente é `needingAttention`, nunca esta tela.
class VencendoView extends StatelessWidget {
  const VencendoView({required this.itens, required this.today, super.key});

  final List<PantryItem> itens;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    // Despensa vazia não é "tudo dentro do prazo": não há prazo nenhum. Quem
    // abre o app pela primeira vez precisa do convite, não de um parabéns.
    if (itens.isEmpty) return const DespensaVazia();

    final List<PantryItem> atencao = needingAttention(itens, today);
    if (atencao.isEmpty) return const _Tranquila();

    // A lista já vem ordenada por urgência, então os vencidos são um prefixo;
    // as duas passagens abaixo só separam o que já está no lugar certo.
    final List<PantryItem> vencidos = atencao
        .where((PantryItem i) => i.statusOn(today) == ExpiryStatus.expired)
        .toList();
    final List<PantryItem> vencendo = atencao
        .where((PantryItem i) => i.statusOn(today) == ExpiryStatus.expiring)
        .toList();

    return ListView(
      key: listaVencendoKey,
      // Espaço para o FAB não cobrir o último item.
      padding: const EdgeInsets.only(bottom: 88),
      children: <Widget>[
        if (vencidos.isNotEmpty) ...<Widget>[
          const _Cabecalho('Vencidos', perigo: true),
          for (final PantryItem i in vencidos) ItemTile(item: i, today: today),
        ],
        if (vencendo.isNotEmpty) ...<Widget>[
          const _Cabecalho('Vencendo'),
          for (final PantryItem i in vencendo) ItemTile(item: i, today: today),
        ],
      ],
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho(this.texto, {this.perigo = false});

  final String texto;
  final bool perigo;

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Text(
        texto.toUpperCase(),
        style: tema.textTheme.labelMedium?.copyWith(
          letterSpacing: 0.8,
          color: perigo ? tema.colorScheme.error : tema.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Vazio aqui é **sucesso**, não erro: nada vencendo merece uma tela tranquila,
/// não um ícone triste.
class _Tranquila extends StatelessWidget {
  const _Tranquila();

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
              Icons.check_circle_outline,
              size: 40,
              color: tema.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text('Nada vencendo', style: tema.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Tudo na despensa está dentro do prazo.',
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
