/// E-mail válido e normalizado. Não existe instância inválida — é isso que
/// impede erro de digitação de chegar na rede.
class Email {
  const Email._(this.value);

  /// Já normalizado: sem espaços nas pontas, em minúsculas.
  final String value;

  /// Deliberadamente frouxo. Validar e-mail com precisão é impossível e a
  /// prova real é o código chegar na caixa de entrada; aqui só barramos o que
  /// não tem chance de ser um endereço.
  static final RegExp _shape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  /// Normaliza e valida. `null` quando não é um e-mail.
  static Email? tryParse(String raw) {
    final String normalized = raw.trim().toLowerCase();
    if (!_shape.hasMatch(normalized)) return null;
    return Email._(normalized);
  }

  @override
  bool operator ==(Object other) => other is Email && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
