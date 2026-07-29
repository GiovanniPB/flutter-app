# AGENTS.md — Despensa

Leia este arquivo antes de qualquer trabalho. O "porquê" das decisões está em
[`docs/adr/`](docs/adr); o domínio em [`docs/product.md`](docs/product.md).

## Abertura de sessão

Leia **três arquivos e só três**: este, [`docs/state.md`](docs/state.md), e o
contrato da fatia em `docs/slices/`. Não abra código antes de o contrato estar
fechado.

Se você precisar de algo que não está no repo, isso é um buraco do método:
escreva no lugar certo em vez de pedir ao usuário para reexplicar.

## Toolchain

Flutter **3.44.6** fixado por `fvm` (`.fvmrc`), app único, Supabase como banco e
autenticação. Não existe `flutter` global: **todo comando passa por `fvm`**.

```
fvm flutter pub get
supabase start                          # portas 544xx (54321 é de outro projeto)
supabase db reset                       # valida as migrations do zero
bash tool/test_db.sh                    # pgTAP no container que já está de pé
```

Mail local (código de acesso) em <http://127.0.0.1:54424>.

Não há passo de geração de código: os providers do Riverpod são escritos à mão
([ADR 0007](docs/adr/0007-gerencia-de-estado.md)).

**Idioma:** identificadores em inglês, textos de interface e documentos em
português. Sem híbrido dentro da mesma classe.

## Escada de verificação

Verifique sempre no degrau mais barato que responda à pergunta.

| Degrau | Comando | Custo | Quem avalia |
|---|---|---|---|
| 0 | mockup antes do código | segundos | usuário |
| 1 | `fvm flutter test test/golden/` | ~3 s | **agente** (lê o PNG) |
| 2 | `fvm flutter widget-preview start` | ~1 s por edit | usuário |
| 3 | app de pé via `.claude/launch.json` (`-d macos`) | ~1 s por edit | usuário |
| 4 | gate completo (ver abaixo) | minutos | CI |

**O degrau 1 é o degrau de trabalho** — o único que o agente fecha sozinho. O
degrau 4 roda antes do PR, nunca durante.

Como usar o degrau 1:

```bash
fvm flutter test --update-goldens test/golden/   # gera/atualiza os PNG
```

O agente então **abre o PNG** em `test/golden/goldens/` e itera contra o mockup.
Todo golden usa `pumpGolden` (componente) ou `pumpGoldenScreen` (tela inteira)
de `test/golden/harness.dart` — é ele que carrega a Roboto do SDK. Sem isso o
texto vira caixinha e o PNG não serve para nada; `test/golden/escada_test.dart`
existe só para provar que essa parte não quebrou.

## Arquitetura

```
domain  ←  data  ←  presentation
```

A dependência aponta sempre para dentro. `domain` não conhece Flutter nem
Supabase.

- **Regra de negócio mora em `domain`**, em função pura: janela de vencimento,
  quantidade derivada de movimentos, gatilho de "acabou".
- **Nada de regra em RPC ou trigger.** Trigger cuida só de `updated_at`.
- **Provider não é lugar de regra** — provider compõe, `domain` decide.
- A data de hoje entra por dependência sobrescrevível. `DateTime.now()` direto
  no domínio é proibido.

## Onde colocar código

| O que | Onde |
|---|---|
| entidades, invariantes, regras puras | `lib/domain/<área>/` |
| contratos de repositório | `lib/domain/<área>/*_repository.dart` |
| lógica de tradução do SDK (medida por cobertura) | `lib/data/<área>/` |
| binding do SDK, só delegação | `lib/data/<área>/supabase_*.dart` |
| providers Riverpod | `lib/presentation/<área>/*_providers.dart` |
| widgets e telas | `lib/presentation/<área>/` |
| composição do app e init | `lib/app/` |
| migrations SQL | `supabase/migrations/` |
| invariantes de banco (pgTAP) | `supabase/tests/` |
| golden e harness de fonte | `test/golden/` |
| configuração por flavor (git-ignored) | `env/dev.json` |

## Convenções de banco

- Toda tabela: `id` UUID **gerado no cliente**, `household_id`, `created_at`,
  `updated_at`, `deleted_at` — e **RLS obrigatória**.
- Apoio de RLS nasce no schema **`private`**, nunca em `public`.
- Função de trigger em `public` leva `revoke execute … from anon, authenticated,
  public` e `set search_path = ''`.
- `supabase migration new <nome>` → SQL → `supabase db reset` para validar do
  zero. Rodar `get_advisors` depois de mudança de schema.
- No cliente, **só a chave publicável**. Config por
  `--dart-define-from-file=env/<flavor>.json`, com `env/*.json` git-ignored.

## Ciclo da fatia

```
tool/new-slice.sh <nome>     # cria contrato + branch
  contrato → execução → aprovação → gate → PR
tool/close-slice.sh          # reescreve state.md, apaga contrato, ADR se houver
```

Uma fatia = uma sessão. Se o "pronto quando" precisa da palavra "e", são duas.

## Definição de pronto

```bash
bash tool/guards.sh
fvm dart analyze --fatal-infos
fvm flutter test --coverage --exclude-tags golden
bash tool/check_coverage.sh 70     # lib/domain e lib/data
fvm flutter test test/golden/      # local, nunca no CI
bash tool/test_db.sh               # local, exige supabase start
```

O CI (`.github/workflows/ci.yml`) roda os mesmos comandos, menos o golden.

Cobertura de 70% cobre `lib/domain/` e `lib/data/`. Ficam fora `presentation`
(lá a verificação real é o golden) e `lib/data/**/supabase_*.dart` (delegação
pura). **Nenhuma decisão pode morar num `supabase_*.dart`** — se ganhar um `if`,
está no arquivo errado ([ADR 0008](docs/adr/0008-teste-e-definicao-de-pronto.md)).

## Git

Nunca commite na `main`. Branch por fatia, Conventional Commits, PR com CI verde
antes do merge.
