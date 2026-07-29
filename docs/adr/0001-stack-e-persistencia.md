# 0001 — Flutter + Supabase, app único

## Contexto

App móvel para Android e iOS, feito por uma pessoa, com dados que precisam ser
compartilhados entre pessoas da mesma casa em algum momento. A escolha precisa
sustentar multi-tenancy com autorização no banco sem escrever backend.

## Decisão

- **Flutter**, versão fixada por `fvm`, **app único** (não monorepo, sem melos).
- **Supabase** como banco (Postgres), autenticação e API — sem backend próprio.
- Autorização no banco via **RLS**, não no cliente.
- Plataformas-alvo: **Android e iOS**. `-d macos` e `chrome` existem apenas
  como alvo de desenvolvimento rápido (hot reload curto), não são produto.
- Camadas: `domain` (entidades e regras, zero dependência de framework) →
  `data` (repositórios, Supabase) → `presentation` (widgets, Riverpod).
  A dependência aponta sempre para dentro.
- Configuração por flavor via `--dart-define-from-file=env/<flavor>.json`, com
  `env/*.json` no `.gitignore`. No cliente, **só a chave publicável** — a
  service-role nunca sai do servidor.

## Alternativas descartadas

- **Monorepo com melos** — custo de estrutura sem nenhum segundo pacote à
  vista. Se surgir, migra-se depois; é barato.
- **Backend próprio (Dart Frog, Node)** — resolveria autorização em código, mas
  RLS resolve o mesmo com menos superfície para manter.
- **Firebase** — sincronização offline melhor de fábrica, mas modelo de
  autorização mais fraco para o caso "casa como tenant" e sem SQL.

## Consequência

Fácil: subir schema com migrations versionadas, ter autorização testável em
SQL, entregar as duas plataformas de um código só.

Difícil: offline. O Supabase não dá isso de graça — e é por isso que a
[ADR 0005](0005-sincronizacao.md) existe.

Custo aceito de propósito: ficamos presos ao Postgres e ao PostgREST. É um
preço baixo perto de manter um backend.
