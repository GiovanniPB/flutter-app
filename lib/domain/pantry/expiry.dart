import 'package:despensa/domain/pantry/pantry_item.dart';

/// O que a lista precisa distinguir — e só isso.
///
/// `ok` é a maioria dos itens e **não ganha selo** na tela: pílula em tudo
/// vira ruído e a lista deixa de gritar onde importa.
enum ExpiryStatus { expired, expiring, ok }

/// Os três números da [ADR 0004](../../../docs/adr/0004-tempo-e-vencimento.md)
/// num lugar só. Ajustar a política é mexer aqui, e em mais nada.
class ExpiryPolicy {
  const ExpiryPolicy({
    required this.fraction,
    required this.minimumDays,
    required this.maximumDays,
  });

  /// Fatia da janela total que vira alerta.
  final double fraction;

  /// Piso: sem ele, iogurte de 5 dias só avisaria com 1 dia de sobra.
  final int minimumDays;

  /// Teto: sem ele, feijão em lata ficaria 146 dias em alerta permanente.
  final int maximumDays;

  /// `clamp(fraction × janela, minimumDays, maximumDays)`.
  ///
  /// Janela não-positiva — item cadastrado já vencido, ou compra informada
  /// depois da validade — cai no piso em vez de explodir.
  int alertDaysFor(int windowDays) =>
      (windowDays * fraction).floor().clamp(minimumDays, maximumDays);
}

const ExpiryPolicy kExpiryPolicy = ExpiryPolicy(
  fraction: 0.20,
  minimumDays: 2,
  maximumDays: 30,
);

/// Dias inteiros entre duas datas puras.
///
/// Passa por UTC de propósito: a diferença entre dois `DateTime` locais erra
/// por um dia quando há mudança de fuso no meio do intervalo. O Brasil não tem
/// mais horário de verão, mas a conta não deveria depender disso.
int daysBetween(DateTime from, DateTime to) {
  final DateTime a = DateTime.utc(from.year, from.month, from.day);
  final DateTime b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

extension ExpiryOf on PantryItem {
  /// Tamanho da janela de alerta **deste** item, em dias (ADR 0004).
  int get alertDays =>
      kExpiryPolicy.alertDaysFor(daysBetween(windowStart, expiresOn));

  /// Negativo quando já venceu. Zero é "vence hoje", que ainda dá para salvar.
  int daysLeftOn(DateTime today) => daysBetween(today, expiresOn);

  /// Calculado na hora, nunca persistido: valor gravado fica errado assim que
  /// o dia vira.
  ExpiryStatus statusOn(DateTime today) {
    final int faltam = daysLeftOn(today);
    if (faltam < 0) return ExpiryStatus.expired;
    return faltam <= alertDays ? ExpiryStatus.expiring : ExpiryStatus.ok;
  }
}

/// Quem vence antes vem antes — o que põe os vencidos no topo sem precisar de
/// uma segunda regra. Empate de data ordena por nome, para a lista não dançar
/// entre quadros.
List<PantryItem> byUrgency(List<PantryItem> items) {
  return List<PantryItem>.of(items)
    ..sort((PantryItem a, PantryItem b) {
      final int data = a.expiresOn.compareTo(b.expiresOn);
      if (data != 0) return data;
      return a.product.name.value
          .toLowerCase()
          .compareTo(b.product.name.value.toLowerCase());
    });
}

/// Só o que exige atenção: vencido ou dentro da janela, na ordem de urgência.
List<PantryItem> needingAttention(List<PantryItem> items, DateTime today) {
  return byUrgency(
    items
        .where((PantryItem i) => i.statusOn(today) != ExpiryStatus.ok)
        .toList(),
  );
}
