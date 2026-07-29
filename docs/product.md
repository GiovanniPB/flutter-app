# Dispensa

> Nome de trabalho — trocar quando o produto tiver nome.

## Em uma frase

App de dispensa doméstica que mostra em segundos o que está perto de vencer e
torna o cadastro de compras rápido o bastante para não ser abandonado.

## Não é

- **não é app de nutrição** — calorias, ingredientes e restrições alimentares
  não entram, em versão nenhuma
- **não é app de receitas**
- **não é app de finanças** — o preço é gravado no item, mas não existe tela de
  gastos na v1
- **não controla fração de pacote** — "usei metade do arroz" não existe; a
  unidade é a menor granularidade
- **não divide a casa em cômodos ou dispensas múltiplas** — a casa tem uma
  dispensa só, com local opcional por item
- **não notifica** — sem push na v1; o usuário abre o app e vê
- **não funciona offline** na v1 (ver [ADR 0005](adr/0005-sincronizacao.md))

## Domínio

Cada entidade é **modelo** (mutável, representa intenção) ou **registro**
(imutável, representa algo que aconteceu).

### Casa

- tipo: **modelo**
- é o *tenant*: toda linha do sistema pertence a exatamente uma casa
- identidade: `id`
- invariantes:
  - uma pessoa pertence a no máximo uma casa
  - todos os membros têm exatamente os mesmos poderes — não há papéis

### Membro

- tipo: **modelo** — vínculo entre uma pessoa autenticada e uma casa
- a casa é criada no primeiro login da pessoa
- invariante: no máximo um vínculo ativo por pessoa

### Produto (a ficha)

- tipo: **modelo**
- pertence a: ninguém, quando **canônico** (veio de um EAN) · a uma casa,
  quando **criado pelo usuário**
- identidade: `id`; `ean` quando canônico
- campos: nome, marca, categoria de alimento, ean
- invariantes:
  - produto canônico é **imutável** e visível para todas as casas
  - produto de casa **não tem EAN** e só é visível pela casa dona
  - produto **nunca** tem validade nem quantidade — isso é do item

### Item da dispensa (a coisa)

- tipo: **modelo**
- pertence a: casa · aponta sempre para um produto
- identidade: `id`
- campos: quantidade inicial, validade, comprado em, local, preço em centavos
- invariantes:
  - **validade é obrigatória**
  - quantidade inicial ≥ 1
  - `quantidade atual = quantidade inicial − Σ movimentos`, nunca negativa
  - item com quantidade atual 0 sai da dispensa mas continua existindo
  - local ∈ {dispensa, geladeira, freezer, nenhum}; só **freezer** mexe na
    validade (ver [ADR 0004](adr/0004-tempo-e-vencimento.md))

### Movimento

- tipo: **registro** — imutável, append-only
- pertence a: item (e, por ele, à casa)
- campos: tipo (`consumido` | `descartado`), quantidade, ocorrido em, **nome do
  produto copiado no momento do evento**
- invariantes:
  - nunca editado, nunca apagado
  - a soma dos movimentos de um item nunca excede sua quantidade inicial
  - a distinção consumido/descartado é o que mede desperdício — não colapsar

### Item da lista de compras

Mapeado, fora do MVP (ver [`surfaces.md`](surfaces.md)).

- tipo: **modelo** — pertence à casa
- entra automaticamente quando o último item de um produto zera; o usuário pode
  adicionar, editar e remover à vontade

## Invariantes globais

- toda linha tem `household_id` e **RLS ativa**
- todo `id` é **UUID gerado no cliente**
- dinheiro é **inteiro em centavos**, BRL
- validade é **data pura** — sem hora, sem fuso
- **modelo** é mutável; **registro** é append-only
- o histórico guarda o **nome copiado** no momento do evento, nunca um ponteiro
  — renomear um produto não reescreve o passado
- "próximo do vencimento" é **sempre calculado**, nunca gravado

## Fluxos principais

1. Entro por link mágico no e-mail; minha casa é criada no primeiro acesso.
2. Escaneio o código de barras ou digito o nome, informo a validade, e o item
   entra na dispensa.
3. Abro o app e vejo, primeiro, o que está dentro da janela de vencimento.
4. Dou baixa de N unidades de um item dizendo se consumi ou joguei fora.
5. Movo um item para o freezer e informo a nova validade, com sugestão vinda da
   categoria do alimento.
6. *(futuro)* O último item de um produto zera e ele entra na lista de compras.

## Decisões

Ver [`docs/adr/`](adr). As caras de reverter moram lá, não aqui.
