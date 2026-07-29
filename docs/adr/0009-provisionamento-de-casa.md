# 0009 — Provisionar a casa é infraestrutura, e mora num trigger

## Contexto

A [ADR 0005](0005-sincronizacao.md) diz que nenhuma regra de negócio mora em
RPC ou trigger — regra vive no `domain`, em Dart, testável sem banco.

Criar a casa no primeiro login parece violar isso. Mas se o cliente faz essa
criação, existe uma janela real: autenticação deu certo, a chamada seguinte
falhou (rede caiu, app foi morto), e agora há um usuário autenticado **sem
casa**. Como toda tabela do sistema pendura em `household_id`
([ADR 0002](0002-multi-tenancy.md)), esse usuário não consegue fazer nada — e
nenhuma tela sabe consertar isso.

## Decisão

Um trigger `after insert on auth.users` insere a casa e o vínculo do membro na
**mesma transação** do cadastro do usuário. Se o insert do usuário existe, a
casa existe. Não há estado intermediário possível.

Isso **não** abre a porta para lógica no banco. A fronteira é:

| No banco | No `domain`, em Dart |
|---|---|
| provisionar tenant no cadastro | tudo que o usuário decide |
| `updated_at` | janela de vencimento, quantidade derivada, "acabou" |

O critério: se a regra pode mudar porque o produto mudou de ideia, ela é
negócio e fica em Dart. Se ela existe para o modelo de dados não poder entrar
em estado inválido, é infraestrutura e fica no banco.

A função é `security definer` com `set search_path = ''`, e o `execute` é
revogado de `anon`, `authenticated` e `public` — permissão de função de trigger
é checada na criação do trigger, não no disparo, então revogar não quebra nada e
impede chamada direta.

**Nota de armadilha relacionada:** a função de apoio de RLS
(`private.current_household()`) é o caso oposto. Ela é avaliada **dentro da
policy, como o usuário que consulta** — sem `execute` para `authenticated`, a
própria RLS quebra. O que a protege é o schema `private` não ser exposto pelo
PostgREST, não a falta de privilégio.

## Alternativas descartadas

- **Cliente chama RPC depois do login** — a janela do usuário sem casa. Também
  exigiria toda tela tolerar "casa ainda não existe".
- **Criar a casa preguiçosamente, no primeiro insert de item** — espalha a
  verificação por toda operação de escrita, para sempre.
- **Cliente insere a casa direto com RLS permissiva** — obrigaria uma policy de
  insert em `households`, que é exatamente a superfície que não queremos aberta.

## Consequência

Fácil: nenhuma tela precisa lidar com usuário sem casa; o invariante é do
banco, e o pgTAP prova em três asserções.

Difícil: a criação da casa não é testável em Dart. É por isso que
`supabase/tests/` existe.

Custo aceito: um pedaço pequeno de comportamento vive em SQL, e a fronteira
acima é o que impede esse pedaço de crescer.
