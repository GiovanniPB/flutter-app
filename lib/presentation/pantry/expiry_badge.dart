import 'package:despensa/domain/pantry/expiry.dart';
import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:flutter/material.dart';

/// Aviso não existe no baseline do Material 3 — erro existe, "quase lá" não.
/// A dupla nasce aqui, num lugar só, para não virar hex solto por widget.
const Color kWarnContainer = Color(0xFFFFE1A8);
const Color kOnWarnContainer = Color(0xFF402D00);

/// Texto **relativo** do selo. A data absoluta continua no subtítulo do item: o
/// relativo é o que faz agir, o absoluto é o que a pessoa digitou.
String expiryLabel(int daysLeft) => switch (daysLeft) {
      0 => 'vence hoje',
      1 => 'vence amanhã',
      -1 => 'venceu ontem',
      < 0 => 'venceu há ${-daysLeft} dias',
      _ => 'em $daysLeft dias',
    };

/// Vencido · vencendo · ok. O `ok` **não desenha nada**: pílula em todo item
/// vira ruído e a lista deixa de gritar onde importa.
class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge({required this.item, required this.today, super.key});

  final PantryItem item;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ExpiryStatus status = item.statusOn(today);
    if (status == ExpiryStatus.ok) return const SizedBox.shrink();

    final bool venceu = status == ExpiryStatus.expired;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: venceu ? tema.colorScheme.errorContainer : kWarnContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        expiryLabel(item.daysLeftOn(today)),
        style: tema.textTheme.labelSmall?.copyWith(
          color: venceu ? tema.colorScheme.onErrorContainer : kOnWarnContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
