# AGENTS.md — Dispensa

Leia este arquivo antes de qualquer trabalho. O "porquê" das decisões está em
[`docs/adr/`](docs/adr); o domínio em [`docs/product.md`](docs/product.md).

## Abertura de sessão

Leia **três arquivos e só três**: este, [`docs/state.md`](docs/state.md), e o
contrato da fatia em `docs/slices/`. Não abra código antes de o contrato estar
fechado.

Se você precisar de algo que não está no repo, isso é um buraco do método:
escreva no lugar certo em vez de pedir ao usuário para reexplicar.

## Toolchain

> **A escada abaixo ainda não existe.** Ela é montada na Fase 1
> (`/projeto andaime flutter-supabase`). Enquanto o degrau 1 não estiver
> funcionando, não abra fatia.

Flutter via `fvm`, app único, Supabase como banco e autenticação.

```
fvm flutter pub get
fvm dart run build_runner watch -d      # Riverpod gera código
supabase db reset                       # valida as migrations do zero
```

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
| entidades, invariantes, regras puras | `lib/domain/` |
| contratos de repositório | `lib/domain/repositories/` |
| implementação Supabase, mapeamento | `lib/data/` |
| providers Riverpod | `lib/presentation/**/providers/` |
| widgets e telas | `lib/presentation/` |
| migrations SQL | `supabase/migrations/` |
| golden e harness de fonte | `test/golden/` |

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
fvm dart analyze --fatal-infos
fvm flutter test --exclude-tags golden
fvm flutter test test/golden/      # local, nunca no CI
bash tool/check_coverage.sh 70     # lib/domain e lib/data
bash tool/guards.sh
```

Cobertura de 70% cobre `lib/domain/` e `lib/data/`. `presentation` fica de fora
— lá a verificação real é o golden ([ADR 0008](docs/adr/0008-teste-e-definicao-de-pronto.md)).

## Git

Nunca commite na `main`. Branch por fatia, Conventional Commits, PR com CI verde
antes do merge.
