# 0007 — Riverpod com geração de código

## Contexto

A tela principal depende de um valor que muda sozinho: "próximo do vencimento"
é calculado contra a data de hoje e nunca é gravado
([ADR 0004](0004-tempo-e-vencimento.md)). A quantidade atual é derivada de uma
lista de movimentos ([ADR 0005](0005-sincronizacao.md)). Quase tudo na tela é
função de outra coisa — a escolha precisa fazer derivação ser barata.

## Decisão

**Riverpod**, com `riverpod_generator` (providers anotados, não declarados à
mão).

- Providers de leitura são **derivados**: a dispensa vem do repositório, e a
  lista "vencendo" é um provider que depende dela mais a data de hoje.
- Regra de negócio **não** mora em provider — mora em `domain`, em função pura,
  testável sem `ProviderContainer`.
- Teste de unidade usa `ProviderContainer` com repositório falso; teste de
  widget usa `ProviderScope(overrides:)`. Nenhum teste toca a rede.
- A data de hoje entra por provider sobrescrevível — nenhum código de domínio
  chama `DateTime.now()` direto, senão a janela de vencimento é intestável.

## Alternativas descartadas

- **BLoC** — bom para máquina de estados com eventos; aqui o problema é
  derivação de dados, e o boilerplate por tela não se paga.
- **`setState` / `ChangeNotifier` puros** — a derivação e o cache viram código
  manual em toda tela.
- **`signals` / `get_it` + serviços** — menos suporte para invalidação e
  sobrescrita em teste, que é o que este projeto mais vai usar.

## Consequência

Fácil: dado derivado é declarativo; sobrescrever qualquer dependência em teste
é uma linha; o degrau golden fica trivial de montar.

Difícil: `build_runner` no ciclo. Mitigado por rodar em watch durante o
trabalho.

Custo aceito: código gerado no repositório e uma curva para quem nunca usou
Riverpod.
