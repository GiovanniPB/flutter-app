import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/presentation/pantry/expiry_badge.dart';
import 'package:flutter/material.dart';

/// Vocabulário de data e local da despensa, em português, num lugar só.
///
/// Data **sempre completa**: o mockup mostrava mês/ano para validade distante,
/// mas esconder o dia que a pessoa digitou é perder informação que ela deu.

String formatBrDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/'
    '${date.year}';

/// `null` quando não é uma data — inclusive `31/02/2027`, que o `DateTime`
/// silenciosamente viraria 03/03.
DateTime? parseBrDate(String raw) {
  final RegExpMatch? achou =
      RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(raw.trim());
  if (achou == null) return null;

  final int dia = int.parse(achou.group(1)!);
  final int mes = int.parse(achou.group(2)!);
  final int ano = int.parse(achou.group(3)!);
  final DateTime data = DateTime(ano, mes, dia);

  if (data.day != dia || data.month != mes || data.year != ano) return null;
  return data;
}

String locationLabel(StorageLocation location) => switch (location) {
      StorageLocation.pantry => 'despensa',
      StorageLocation.fridge => 'geladeira',
      StorageLocation.freezer => 'freezer',
    };

class ItemTile extends StatelessWidget {
  const ItemTile({required this.item, required this.today, super.key});

  final PantryItem item;

  /// Chega de fora porque o vencimento é calculado na hora e o widget não pode
  /// perguntar as horas sozinho — é o que deixa o golden determinístico.
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final StorageLocation? local = item.location;

    return ListTile(
      title: Text(item.product.name.value),
      subtitle: Text(
        <String>[
          '${item.quantity} un',
          'vence ${formatBrDate(item.expiresOn)}',
          if (local != null) locationLabel(local),
        ].join(' · '),
        style: tema.textTheme.bodySmall?.copyWith(
          color: tema.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: ExpiryBadge(item: item, today: today),
    );
  }
}
