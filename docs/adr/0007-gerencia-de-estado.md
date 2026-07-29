# 0007 — Riverpod com providers escritos à mão

## Contexto

A tela principal depende de um valor que muda sozinho: "próximo do vencimento"
é calculado contra a data de hoje e nunca é gravado
([ADR 0004](0004-tempo-e-vencimento.md)). A quantidade atual é derivada de uma
lista de movimentos ([ADR 0005](0005-sincronizacao.md)). Quase tudo na tela é
função de outra coisa — a escolha precisa fazer derivação ser barata.

## Decisão

**Riverpod**, com providers **declarados à mão**. Sem `riverpod_generator`, sem
`build_runner`, sem `riverpod_lint`.

- Providers de leitura são **derivados**: a despensa vem do repositório, e a
  lista "vencendo" é um provider que depende dela mais a data de hoje.
- Regra de negócio **não** mora em provider — mora em `domain`, em função pura,
  testável sem `ProviderContainer`.
- Teste de unidade usa `ProviderContainer` com repositório falso; teste de
  widget usa `ProviderScope(overrides:)`. Nenhum teste toca a rede.
- A data de hoje entra por provider sobrescrevível — nenhum código de domínio
  chama `DateTime.now()` direto, senão a janela de vencimento é intestável.

## Alternativas descartadas

- **Geração de código (`riverpod_generator`)** — tentada primeiro e descartada
  na Fase 1 por conflito real de resolução: `riverpod_generator` ≥ 4.0.6 exige
  `analyzer` 13, e o Flutter 3.44.6 fixa `analyzer` < 13 via `flutter_test`.
  Contornar exige fixar três pacotes uma versão atrás
  (`flutter_riverpod` 3.3.2 + `riverpod_annotation` 4.0.3 +
  `riverpod_generator` 4.0.4) e refazer o quebra-cabeça a cada upgrade do SDK.
  A geração economiza boilerplate; ela não habilita nada. Não vale o pedágio.
  `riverpod_lint`/`custom_lint` caem pelo mesmo motivo.
- **BLoC** — bom para máquina de estados com eventos; aqui o problema é
  derivação de dados, e o boilerplate por tela não se paga.
- **`setState` / `ChangeNotifier` puros** — a derivação e o cache viram código
  manual em toda tela.
- **`signals` / `get_it` + serviços** — menos suporte para invalidação e
  sobrescrita em teste, que é o que este projeto mais vai usar.

## Consequência

Fácil: dado derivado é declarativo; sobrescrever qualquer dependência em teste
é uma linha; nenhum passo de geração no ciclo, e o upgrade do Flutter não
depende do calendário de um gerador.

Difícil: `family` e `autoDispose` são escritos à mão, o que é mais verboso.

Custo aceito: mais linhas por provider, em troca de um ciclo sem `build_runner`
e de uma resolução de dependências que não quebra sozinha.
