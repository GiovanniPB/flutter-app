import 'package:despensa/domain/auth/auth_repository.dart';
import 'package:despensa/domain/auth/email.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sobrescrito em `main.dart` e nos testes. É o que mantém o cliente Supabase
/// fora da `presentation` (ADR 0005).
final Provider<AuthRepository> authRepositoryProvider = Provider<AuthRepository>(
  (Ref ref) => throw UnimplementedError(
    'authRepositoryProvider precisa de override no ProviderScope',
  ),
);

/// Quem decide a tela: sessão nula é Entrar, sessão presente é a home.
final StreamProvider<AuthUser?> authUserProvider =
    StreamProvider<AuthUser?>((Ref ref) {
  return ref.watch(authRepositoryProvider).watchUser();
});

enum EntrarStep { email, code }

@immutable
class EntrarState {
  const EntrarState({
    this.step = EntrarStep.email,
    this.email = '',
    this.busy = false,
    this.error,
  });

  final EntrarStep step;
  final String email;
  final bool busy;
  final String? error;

  /// O botão só habilita com e-mail válido — erro de digitação não chega na
  /// rede.
  bool get canSubmitEmail => Email.tryParse(email) != null && !busy;

  EntrarState copyWith({
    EntrarStep? step,
    String? email,
    bool? busy,
    String? error,
    bool clearError = false,
  }) {
    return EntrarState(
      step: step ?? this.step,
      email: email ?? this.email,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EntrarController extends Notifier<EntrarState> {
  @override
  EntrarState build() => const EntrarState();

  void emailChanged(String value) =>
      state = state.copyWith(email: value, clearError: true);

  void backToEmail() => state = EntrarState(email: state.email);

  Future<void> sendCode() async {
    final Email? email = Email.tryParse(state.email);
    if (email == null || state.busy) return;

    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).sendCode(email);
      state = state.copyWith(step: EntrarStep.code, busy: false);
    } on AuthException catch (falha) {
      state = state.copyWith(busy: false, error: _mensagem(falha.failure));
    }
  }

  Future<void> verify(String code) async {
    final Email? email = Email.tryParse(state.email);
    if (email == null || code.length != 6 || state.busy) return;

    state = state.copyWith(busy: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyCode(email: email, code: code);
      // Sucesso não mexe no estado de propósito: quem troca de tela é o
      // authUserProvider, e este notifier morre junto com a tela.
    } on AuthException catch (falha) {
      state = state.copyWith(busy: false, error: _mensagem(falha.failure));
    }
  }

  String _mensagem(AuthFailure falha) => switch (falha) {
        // Errado e expirado dão a mesma frase: distinguir conta a um atacante
        // se aquele e-mail tem conta.
        AuthFailure.invalidCode => 'Código inválido ou expirado. Tente de novo.',
        AuthFailure.network => 'Sem conexão. Tente de novo.',
        AuthFailure.unknown => 'Não deu para continuar agora. Tente de novo.',
      };
}

final NotifierProvider<EntrarController, EntrarState> entrarControllerProvider =
    NotifierProvider<EntrarController, EntrarState>(EntrarController.new);
