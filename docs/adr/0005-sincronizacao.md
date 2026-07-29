# 0005 — Online-only na v1, com o modelo preparado para offline

## Contexto

A v1 é online-only para ficar de pé rápido. Mas offline é desejado depois, e a
pergunta certa não é "quando fazemos offline" — é **"o que estamos gravando
hoje que vai tornar offline doloroso amanhã"**.

A resposta era um campo: `quantidade` como contador mutável. Duas pessoas dando
baixa sem rede e sincronizando depois — uma sobrescreve a outra, e a baixa
perdida some sem aviso. Contador mutável é o pior tipo de dado para
sincronizar.

## Decisão

**A v1 é online-only.** Sem rede, sem app. Sem fila de escrita, sem cache de
leitura, sem PowerSync.

**Mas a quantidade nunca é um contador mutável:**

- o item guarda **quantidade inicial**, que não muda;
- cada baixa é um **movimento imutável** (`consumido` | `descartado`, com
  quantidade e data), gravado por append;
- **quantidade atual = inicial − Σ movimentos**, calculada na leitura.

Movimentos só se somam. Duas baixas concorrentes valem as duas; não existe
sobrescrita e não existe conflito a resolver. O histórico e a métrica de
desperdício saem do mesmo dado, de graça.

Os demais campos (nome, local, validade, preço) são **último-que-escreve-vence**
e isso é aceitável: são correções, não acumulação.

**Preparação obrigatória, valendo desde a primeira tabela:**

- todo `id` é **UUID gerado no cliente** — nunca sequência do banco;
- toda tabela tem `created_at` e `updated_at`, com trigger de `updated_at`;
- remoção é **soft delete** (`deleted_at`), nunca `DELETE`;
- o domínio fala com **repositórios abstratos**; o cliente Supabase não vaza
  para `domain` nem para `presentation`;
- nenhuma regra de negócio mora em RPC ou trigger — regra vive no `domain`, em
  Dart, testável sem banco. Trigger cuida só de `updated_at`.

## Alternativas descartadas

- **Offline-first na v1 (PowerSync, Drift + fila)** — é a diferença entre um app
  e um app com sistema distribuído dentro. Não se paga antes do produto existir.
- **Cache de leitura offline** — meia solução: o usuário vê a dispensa mas não
  cadastra, que é justamente o que ele quer fazer longe de casa.
- **Quantidade como contador mutável** — o motivo deste ADR.
- **Quantidade atual materializada em coluna via trigger** — otimização
  prematura; a contagem de movimentos por item é pequena. Se um dia doer, vira
  coluna derivada mantida por trigger, sem mudar o modelo.

## Consequência

Fácil: ligar offline depois é trocar a implementação do repositório e adicionar
uma fila. O modelo de dados não muda, os dados gravados não migram.

Difícil: cada leitura de dispensa agrega movimentos. Com dezenas de itens por
casa, é irrelevante.

Custo aceito: a v1 não funciona sem rede, e isso vai incomodar no mercado.
