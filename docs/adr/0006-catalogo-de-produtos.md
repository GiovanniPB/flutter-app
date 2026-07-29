# 0006 — Catálogo canônico por EAN é global e imutável; produto do usuário é privado da casa

## Contexto

O código de barras acelera o cadastro, mas nem todo produto tem um — feira,
granel, marmita. O usuário também quer criar os próprios produtos para não
redigitar "Tomate" toda semana.

Se tudo virar catálogo global, a busca enche de `tomate`, `Tomate`,
`tomate italiano` e lixo de outras casas — e passa a exigir moderação, que é um
produto inteiro que ninguém quer construir.

## Decisão

Duas procedências, com regras diferentes:

**Produto canônico** — tem EAN, veio da leitura do código de barras.
É **global** (visível para todas as casas), **imutável** e não pertence a
ninguém. O usuário não edita nome nem marca.

**Produto da casa** — criado pelo usuário, **não tem EAN**, é **privado da casa**
e editável por ela. Nunca é visto por outra casa.

O catálogo global cresce apenas por leitura de EAN. **Não há promoção de
produto de casa para global** — se um dia fizer sentido, vira ADR próprio.

Todo item da dispensa aponta para um produto. Digitar um nome novo no cadastro
rápido **cria um produto da casa** e reaproveita nas próximas vezes.

A **categoria de alimento** é lista fixa definida por nós, opcional no produto,
e serve só para sugerir prazo ao congelar
([ADR 0004](0004-tempo-e-vencimento.md)).

## Alternativas descartadas

- **Tudo global** — busca poluída e necessidade de moderação.
- **Tudo privado da casa** — jogaria fora a única vantagem real do código de
  barras: nome e marca já preenchidos.
- **Privado com promoção para global** — resolve os dois, custa fila de
  curadoria e deduplicação. Caro demais para agora.

## Consequência

Fácil: escanear preenche sozinho e nunca conflita; a busca da casa fica limpa.

Difícil: duas casas cadastram "Tomate" separadamente e o dado se duplica entre
tenants. É aceito — o dado é pequeno e a alternativa é moderação.

Custo aceito: se o EAN trouxer um nome feio, o usuário não pode corrigir; ele
pode apenas criar um produto de casa próprio ao lado.
