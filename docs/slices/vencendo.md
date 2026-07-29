# Fatia: vencendo

tipo: feature

## Pronto quando

Abrir o app mostra primeiro o que exige atenção: vencidos no topo, seguidos dos
que entraram na janela da [ADR 0004](../adr/0004-tempo-e-vencimento.md).

## Superfícies

- **Vencendo** (nova) — passa a ser a home. Só o que exige atenção: vencidos
  destacados no topo, depois os que estão dentro da janela, ordenados por dias
  restantes. Lista vazia é estado de **sucesso**, não erro.
- **Barra de abas** (nova) — `Vencendo | Despensa`. Nasce agora porque agora
  existem duas coisas para pôr nela.
- **Despensa** (muda) — é a home de hoje, vira a segunda aba. Continua listando
  tudo, agora com selo de validade.
- **SeloValidade** (novo componente) — `vencido · vencendo · ok`. É a peça de
  linguagem visual mais reusada do app; nasce aqui.
- **ItemTile** (muda) — ganha o selo.

FAB de adicionar continua presente nas duas abas.

Mockup aprovado: **sim** — [`vencendo.mockup.html`](vencendo.mockup.html).

O que o mockup fixou, além do desenho: abas no topo (duas listas do mesmo tipo
de conteúdo), contador na aba Vencendo que some no zero, seções `Vencidos` e
`Vencendo`, selo com texto **relativo** enquanto o subtítulo mantém a data
absoluta, item `ok` **sem pílula**, e um âmbar de aviso que o baseline M3 não
tem — nasce nesta fatia, num lugar só.

## Arquivos que mudam

Lista fechada. Arquivo fora dela = parar e reavaliar o tamanho da fatia.

```
lib/domain/pantry/expiry.dart                    novo — janela, status, ordem
lib/domain/pantry/pantry_item.dart               createdAt entra no item
lib/data/pantry/pantry_mapper.dart               lê created_at
lib/presentation/pantry/expiry_badge.dart        novo — SeloValidade
lib/presentation/pantry/item_tile.dart           ganha o selo
lib/presentation/pantry/vencendo_view.dart       novo — a aba
lib/presentation/pantry/despensa_view.dart       novo — sai de home_screen
lib/presentation/pantry/pantry_providers.dart    todayProvider + listas derivadas
lib/presentation/home/home_screen.dart           vira o Scaffold com as abas
test/domain/pantry/expiry_test.dart
test/domain/pantry/pantry_item_test.dart
test/data/pantry/pantry_mapper_test.dart
test/presentation/pantry/vencendo_view_test.dart
test/golden/vencendo_test.dart
docs/surfaces.md                                 tira a nota de "hoje a home é a Despensa"
```

Sem migration: `created_at` já existe em `pantry_items` desde
`20260729180204_produto_e_item.sql`. Nenhuma regra desce para o banco
(AGENTS.md: regra mora em `domain`).

## Casos

**Domínio (teste puro, hoje injetado — `DateTime.now()` é proibido aqui)**
- alerta = `clamp(0,20 × janela, 2 dias, 30 dias)`, os três números numa
  constante só
- iogurte: janela de 5 dias → alerta de 2 dias (piso)
- feijão em lata: janela de 730 dias → alerta de 30 dias (teto)
- janela de 50 dias → alerta de 10 dias (o percentual puro, entre piso e teto)
- validade anterior a hoje → `vencido`
- validade igual a hoje → `vencendo`, nunca `vencido`
- validade fora do alerta → `ok`, e `ok` não aparece na aba Vencendo
- sem data de compra, a janela começa no cadastro (`createdAt`)
- data de compra depois da validade não explode: janela não-positiva cai no piso
- ordem: vencidos primeiro, do mais antigo para o mais novo; depois os demais
  por dias restantes crescente
- empate de data ordena por nome, para a lista não dançar entre quadros

**Tela (widget + golden)**
- a aba Vencendo é a que abre
- vencidos aparecem acima, visualmente separados dos que só estão vencendo
- nada vencendo → tela tranquila de sucesso, não ícone triste
- despensa continua listando tudo, inclusive o que está `ok`
- selo aparece nas duas abas; `ok` não ganha pílula — a ausência é a aparência
- contador da aba some quando não há nada vencendo
- FAB abre o cadastro nas duas abas
- despensa vazia continua convidando a cadastrar o primeiro item

## Fora de escopo

- **filtro por local** na aba Despensa — a aba nasce igual ao que já existe,
  mais o selo
- **tela de Item, baixa, freezer** — fatias `baixa` e `freezer`
- **notificação** — vencer não dispara nada (ADR 0004); o usuário abre e vê
- **quantidade derivada de movimentos** — fatia `baixa`
- **ajuste dos três números da janela pelo usuário** — a ADR os fixa no domínio
- **agrupar por dia** ("vence hoje", "amanhã") na aba Vencendo — ordenar por
  urgência já entrega o fato; cabeçalho de grupo é enfeite de outra fatia
