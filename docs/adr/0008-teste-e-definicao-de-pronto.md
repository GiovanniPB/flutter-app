# 0008 — Escada de verificação, golden como degrau de trabalho, 70% de cobertura

## Contexto

A causa raiz de retrabalho em UI é verificação cara: se a única forma de saber
se a tela ficou certa é subir o app e perguntar ao usuário, cada iteração custa
minutos e uma interrupção humana. O agente precisa de um degrau que ele mesmo
avalie, sozinho.

## Decisão

**A escada** — sempre o degrau mais barato que responda à pergunta:

| Degrau | O quê | Custo | Quem avalia |
|---|---|---|---|
| 0 | mockup antes do código | segundos | usuário |
| 1 | **golden do widget** | ~3 s | **agente** (lê o PNG) |
| 2 | preview com hot reload | ~1 s por edit | usuário |
| 3 | app de pé (`.claude/launch.json`, `-d macos`) | ~1 s por edit | usuário |
| 4 | gate completo | minutos | CI |

**O degrau 1 é o degrau de trabalho** — é o único que fecha o ciclo sem o
usuário na frente da tela. O degrau 4 roda antes do PR, nunca durante.

**Verificação incremental** é hook `PostToolUse`: `dart analyze --fatal-infos`
no arquivo editado, não no workspace. Zero token de decisão.

**Definição de pronto (o gate, antes de todo PR):**

- `dart analyze --fatal-infos` limpo em todo o projeto
- todos os testes passando
- **cobertura ≥ 70%** em `lib/domain/` e `lib/data/` — `presentation` fica de
  fora porque lá a verificação real é o golden
- `bash tool/guards.sh` verde (teto de `state.md`, ausência de histórico em
  documento vivo)

**Golden roda local, não no CI.** Renderização difere entre macOS e Linux; os
testes golden levam `tags: ['golden']` e o CI roda com `--exclude-tags golden`.

**Toda regra de domínio nasce com teste**: a janela de vencimento com clamp, a
quantidade derivada de movimentos e o gatilho de "acabou" são funções puras e
são as primeiras coisas testadas.

## Alternativas descartadas

- **Cobertura global de 80%** — arrastaria `presentation` para dentro da conta e
  incentivaria teste de widget escrito para satisfazer a métrica.
- **Sem número de cobertura** — sem chão, a cobertura cai sozinha.
- **Golden no CI** — falha por diferença de renderização de plataforma, não por
  regressão real, e treina todo mundo a ignorar CI vermelho.
- **`flutter analyze` no projeto inteiro a cada edição** — lento demais para
  hook; vira ruído e é desligado.

## Consequência

Fácil: iterar UI sem interromper o usuário, e chegar no PR sem surpresa de
análise.

Difícil: golden precisa das fontes reais carregadas, senão renderiza caixinhas —
o harness de fonte é obrigatório e é a primeira coisa que a Fase 1 entrega.
Regressão de golden não é pega pelo CI; é pega localmente, antes do PR.

Custo aceito: 70% é um chão modesto e escolhido para ser cumprido, não para
impressionar. Sobe quando incomodar.
