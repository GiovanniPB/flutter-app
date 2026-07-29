# Superfícies

## Escopo da v1

A v1 entrega **um pilar só: dispensa + vencimento**. A lista de compras está
mapeada aqui, mas fora do MVP — ela depende do fluxo de baixa existir, e vem
quase de graça depois dele.

## Telas

### 1. Entrar

E-mail → link mágico → volta autenticado. Sem senha, sem cadastro em duas
etapas. A casa é criada no primeiro acesso, em silêncio — a palavra "casa" não
aparece na v1.

### 2. Vencendo — a home

**É a primeira coisa que o app mostra.** Só o que exige atenção:

- **vencidos** no topo, visualmente separados — continuam na dispensa até o
  usuário dar baixa
- **dentro da janela** (ver [ADR 0004](adr/0004-tempo-e-vencimento.md)),
  ordenados por dias restantes
- vazio é um estado de sucesso, não um erro: "nada vencendo" merece uma tela
  tranquila, não um ícone triste

Ação principal: **FAB de adicionar**, presente aqui e na dispensa.

### 3. Dispensa

Tudo o que existe, com quantidade atual. Acessível em um toque a partir da
home. Filtro por local (dispensa · geladeira · freezer).

### 4. Cadastro rápido

Bottom sheet, não tela cheia — é o fluxo que precisa ser rápido o bastante para
não ser abandonado.

- **Obrigatório:** nome (digitado ou vindo do EAN escaneado) e **validade**
- **Opcionais, recolhidos:** quantidade (padrão 1), local, data de compra, preço
- digitar um nome novo cria um produto da casa e reaproveita nas próximas vezes
  ([ADR 0006](adr/0006-catalogo-de-produtos.md))
- o código de barras identifica o **produto**, nunca o lote: a validade é
  sempre digitada. Não prometer o contrário em lugar nenhum da interface.

### 5. Item

Detalhe e as ações sobre um item:

- **dar baixa**: quantidade + `consumi` ou `joguei fora` — a distinção é o que
  mede desperdício e não pode virar um botão só
- **mover para o freezer**: pede nova validade, com sugestão vinda da categoria
- editar campos, remover

## Navegação

```
Entrar
  └── Vencendo (home) ──[aba]── Dispensa
        │                          │
        └──────── FAB ─────────────┴──► Cadastro rápido (sheet)
                                   │
                                   └──► Item (rota) ──► Baixa (sheet)
```

Duas abas na v1. A terceira nasce com a lista de compras.

## Componentes

| Componente | Papel |
|---|---|
| `SeloValidade` | vencido · vencendo · ok — a peça de linguagem visual mais reusada do app |
| `ItemTile` | nome, quantidade atual, selo de validade |
| `CampoValidade` | entrada de data pura, otimizada para digitar rápido |
| `SeletorLocal` | dispensa · geladeira · freezer |
| `SheetBaixa` | quantidade + consumi/joguei fora |

## Mapeado, fora da v1

- **Lista de compras** — terceira aba; entra automaticamente quando o último
  item de um produto zera, editável à vontade
- **Gastos** — o preço já é gravado; falta só a tela
- **Membros da casa** — convite e aceite ([ADR 0002](adr/0002-multi-tenancy.md))
- **Notificação push** — hoje o usuário abre o app e vê
