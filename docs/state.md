# Estado

> Documento **vivo**: reescrito a cada fatia, nunca acumulado.
> Nada de seção "Concluído" aqui — `git log` é o arquivo morto.
> Teto: 150 linhas (o CI falha acima disso).

## Onde estamos

Entra-se no app. O código de 6 dígitos chega no e-mail, abre sessão, e a casa é
provisionada pelo trigger na mesma transação do cadastro do usuário. A home
existe como casca: mostra só o estado vazio e o `sair`.

Não existe nada de despensa ainda — nem produto, nem item, nem baixa. O banco
tem duas tabelas (`households`, `household_members`), ambas com RLS.

Desenvolvimento roda contra `supabase start` local, **portas 544xx** (a 54322 é
de outro projeto na mesma máquina). Nenhum projeto Supabase na nuvem existe.

## Última fatia

**entrar** — o código do e-mail deixa a pessoa dentro do app, numa despensa
vazia que é dela ([PR #2](https://github.com/GiovanniPB/flutter-app/pull/2)).

Fechou **acima da faixa saudável**: 2001 linhas em 30 arquivos, contra 800–1800
em ~20. Oito arquivos eram de verificação, não de feature — `tool/test_db.sh`,
`pumpGoldenScreen`, a separação de `auth_error.dart` e a regra de cobertura. A
causa é a Fase 1 não ter previsto teste de banco nem golden de tela inteira; a
próxima fatia não deve herdar esse custo.

## Próximas fatias

1. **cadastro-manual** — cadastro um item com nome e validade e ele aparece na
   despensa, persistido.
2. **vencendo** — a home lista o que está dentro da janela de vencimento,
   vencidos no topo, ordenado por urgência.
3. **baixa** — dou baixa de N unidades dizendo se consumi ou joguei fora.

## Débitos conhecidos

- **Fim a fim não roda sozinho** — a prova de que o código do e-mail leva à home
  foi feita com script no scratchpad, contra o Supabase local. Virar suíte
  repetível exige decidir como conviver com teste que precisa de Docker e não
  roda no CI. É ADR, não improviso.
- **Nenhum toque real na tela** — o painel do simulador iOS depende de permissão
  não concedida. Existe um simulador `Despensa iPhone 17 Pro` criado e desligado.
- **Offline** — v1 é online-only; o modelo já está preparado
  ([ADR 0005](adr/0005-sincronizacao.md)).
- **Lista de compras** — segundo pilar do produto, depende do fluxo de baixa.
- **Leitura de código de barras** — o EAN é acelerador, não requisito.
- **Quantidade parcial** ("meio pacote") — interessante, não essencial.
- **Tela de gastos** — o preço será gravado no item, sem tela.
- **Push** — desejado, fora da v1.
- **Multiusuário** — schema pronto, falta convite e aceite
  ([ADR 0002](adr/0002-multi-tenancy.md)).
- **Sem lint de Riverpod** — não resolve nesta versão do SDK
  ([ADR 0007](adr/0007-gerencia-de-estado.md)).

## Armadilhas

- **Asserção de banco tem que ser relativa** aos dados que o próprio teste cria.
  `count(*) from households = 1` passa em banco resetado e quebra no primeiro uso
  local. Já quebrou uma vez.
- **Função em policy precisa de `execute`.** Ela é avaliada como o usuário que
  consulta — revogar quebra a própria RLS. O que protege `private` é não estar
  exposto pelo PostgREST. Função de **trigger** é o oposto: permissão é checada
  na criação, então revogar é seguro e correto.
- **`supabase test db` fica preso** puxando imagem Docker. Use
  `bash tool/test_db.sh`.
- Código de barras identifica o **produto**, nunca o lote — validade nunca vem
  do EAN.
- `DateTime.now()` direto no domínio torna a janela de vencimento intestável.
- Golden vira caixinha sem `pumpGolden`/`pumpGoldenScreen` do harness, e diverge
  entre macOS e Linux — roda local, fica fora do CI.
- `pumpAndSettle` nunca volta com `TextField` ou spinner na tela: cursor e
  animação agendam quadro para sempre. Use pump de duração fixa.
- Quantidade será derivada de movimentos, nunca gravada — materializar em coluna
  reintroduz o conflito que a [ADR 0005](adr/0005-sincronizacao.md) evita.
- `analyzer` do Flutter 3.44.6 é < 13; pacote de tooling que exige 13 não resolve.
