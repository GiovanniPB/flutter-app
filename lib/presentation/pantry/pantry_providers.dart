import 'package:despensa/domain/pantry/pantry_item.dart';
import 'package:despensa/domain/pantry/pantry_repository.dart';
import 'package:despensa/domain/pantry/product.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sobrescrito em `main.dart` e nos testes — mantém o cliente Supabase fora da
/// `presentation` (ADR 0005).
final Provider<PantryRepository> pantryRepositoryProvider =
    Provider<PantryRepository>(
  (Ref ref) => throw UnimplementedError(
    'pantryRepositoryProvider precisa de override no ProviderScope',
  ),
);

final StreamProvider<List<PantryItem>> pantryItemsProvider =
    StreamProvider<List<PantryItem>>((Ref ref) {
  return ref.watch(pantryRepositoryProvider).watchItems();
});

@immutable
class CadastroState {
  const CadastroState({
    this.name = '',
    this.expiresOn,
    this.quantity = 1,
    this.purchasedOn,
    this.location,
    this.priceCents,
    this.optionsOpen = false,
    this.busy = false,
    this.error,
  });

  final String name;
  final DateTime? expiresOn;
  final int quantity;
  final DateTime? purchasedOn;
  final StorageLocation? location;
  final int? priceCents;
  final bool optionsOpen;
  final bool busy;
  final String? error;

  /// Nome e validade. Nada mais é obrigatório — é isso que faz o cadastro ser
  /// rápido o bastante para não ser abandonado.
  bool get canSave =>
      ProductName.tryParse(name) != null && expiresOn != null && !busy;

  CadastroState copyWith({
    String? name,
    DateTime? expiresOn,
    int? quantity,
    DateTime? purchasedOn,
    StorageLocation? location,
    int? priceCents,
    bool? optionsOpen,
    bool? busy,
    String? error,
    bool clearError = false,
    bool clearExpiresOn = false,
  }) {
    return CadastroState(
      name: name ?? this.name,
      expiresOn: clearExpiresOn ? null : (expiresOn ?? this.expiresOn),
      quantity: quantity ?? this.quantity,
      purchasedOn: purchasedOn ?? this.purchasedOn,
      location: location ?? this.location,
      priceCents: priceCents ?? this.priceCents,
      optionsOpen: optionsOpen ?? this.optionsOpen,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CadastroController extends Notifier<CadastroState> {
  @override
  CadastroState build() => const CadastroState();

  void nameChanged(String value) =>
      state = state.copyWith(name: value, clearError: true);

  /// `null` enquanto o texto digitado ainda não é uma data — o botão fica
  /// desabilitado, sem gritar com quem está no meio da digitação.
  void expiresOnChanged(DateTime? date) => state = date == null
      ? state.copyWith(clearExpiresOn: true, clearError: true)
      : state.copyWith(expiresOn: date, clearError: true);

  void quantityChanged(int value) =>
      state = state.copyWith(quantity: value < 1 ? 1 : value);

  void purchasedOnChanged(DateTime? date) =>
      state = state.copyWith(purchasedOn: date);

  void locationChanged(StorageLocation? value) =>
      state = state.copyWith(location: value);

  void priceCentsChanged(int? value) =>
      state = state.copyWith(priceCents: value);

  void toggleOptions() =>
      state = state.copyWith(optionsOpen: !state.optionsOpen);

  /// `true` quando gravou — é o sinal para a folha fechar. Em falha o estado
  /// guarda a mensagem e **nada do que foi digitado se perde**.
  Future<bool> save() async {
    final ProductName? nome = ProductName.tryParse(state.name);
    final DateTime? validade = state.expiresOn;
    if (nome == null || validade == null || state.busy) return false;

    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(pantryRepositoryProvider).addItem(
            name: nome,
            expiresOn: validade,
            quantity: state.quantity,
            purchasedOn: state.purchasedOn,
            location: state.location,
            priceCents: state.priceCents,
          );
      // Zerar é obrigatório: o provider é global e sobrevive ao fechamento da
      // folha. Sem isto, abrir o cadastro de novo mostraria o item anterior já
      // preenchido.
      state = const CadastroState();
      return true;
    } on PantryException catch (falha) {
      state = state.copyWith(busy: false, error: _mensagem(falha.failure));
      return false;
    }
  }

  String _mensagem(PantryFailure falha) => switch (falha) {
        PantryFailure.network => 'Sem conexão. O que você digitou está aqui.',
        PantryFailure.unknown => 'Não deu para salvar agora. Tente de novo.',
      };
}

final NotifierProvider<CadastroController, CadastroState>
    cadastroControllerProvider =
    NotifierProvider<CadastroController, CadastroState>(CadastroController.new);
