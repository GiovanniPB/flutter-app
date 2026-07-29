# 0004 — Validade é data pura; a janela de alerta é percentual com piso e teto

## Contexto

"Próximo do vencimento" é o coração do produto, e um limiar fixo não funciona:

| Produto | Janela total | Alerta fixo de 7 dias |
|---|---|---|
| Iogurte | 5 dias | nunca sai do alerta |
| Feijão em lata | 730 dias | avisa tarde demais para agir |

Percentual puro erra nas mesmas duas pontas, invertidas: 20% de 5 dias é 1 dia
(tarde), 20% de 730 dias é 146 dias (metade da despensa em alerta permanente).

## Decisão

**Validade é `date` puro** — sem hora, sem fuso. `12/03/2027` é o mesmo dia em
qualquer lugar. "Hoje" é o fuso do aparelho. **Não existe fechamento de
período** neste produto.

**A janela de alerta é percentual, com piso e teto:**

```
início   = comprado_em ?? criado_em
janela   = validade − início
alerta   = clamp(0,20 × janela, 2 dias, 30 dias)
```

Um item está *próximo do vencimento* quando `validade − hoje ≤ alerta`.

Os três números (**20% · 2 dias · 30 dias**) vivem em **uma constante só**,
no domínio, e são ajustáveis sem tocar em mais nada.

O cálculo é **sempre feito na hora**, nunca persistido — um valor gravado fica
errado assim que o dia vira.

**Freezer é o único local que mexe na validade.** Ao mover um item para o
freezer, o usuário **informa a nova validade**; o app **sugere** um acréscimo a
partir da categoria do alimento (tabela fixa, definida por nós, não editável
pelo usuário). Ao tirar do freezer, o usuário informa a validade novamente.
Geladeira e despensa são apenas rótulos de localização.

**Vencer não dispara nada.** Item vencido é sinalizado e continua na despensa
até o usuário dar baixa — vencido não significa descartado.

## Alternativas descartadas

- **Limiar fixo em dias** — a tabela do contexto.
- **Percentual puro** — a mesma tabela, invertida.
- **Limiar por categoria de alimento** — exigiria catálogo de categoria
  completo e confiável antes da primeira tela; a fórmula com clamp acerta os
  mesmos casos sem catálogo nenhum.
- **`timestamptz` na validade** — hora em data de validade não existe no mundo
  físico e traria bug de fuso de graça.
- **Recalcular validade automaticamente ao congelar** — depende de uma tabela
  de prazos que erra em casos reais; sugerir e deixar o usuário confirmar custa
  um toque e nunca mente.

## Consequência

Fácil: um item de laticínio e uma lata de conserva se comportam bem com a mesma
regra e zero configuração do usuário.

Difícil: itens cadastrados sem data de compra usam a data de cadastro como
início, o que encurta a janela percebida de um produto comprado há muito tempo.
O piso de 2 dias impede que isso vire alerta tarde demais.

Custo aceito: a janela depende de um dado que o usuário pode não informar.
