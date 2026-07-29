# Estado

> Documento **vivo**: reescrito a cada fatia, nunca acumulado.
> Nada de seção "Concluído" aqui — `git log` é o arquivo morto.
> Teto: 150 linhas (o CI falha acima disso).

## Onde estamos

Entra-se por código de 6 dígitos no e-mail e cadastra-se item na despensa. O
app abre em **Vencendo**: vencidos no topo sob cabeçalho próprio, depois os que
entraram na janela da [ADR 0004](adr/0004-tempo-e-vencimento.md), com selo em
texto relativo ("venceu há 5 dias", "vence hoje", "em 3 dias"). **Despensa** é a
segunda aba e lista tudo, na mesma ordem. Item tranquilo não ganha selo.

Nada de baixa ainda: a quantidade mostrada é a cadastrada, e vencido continua na
lista até alguém dar baixa — que é a fatia seguinte.

Banco com quatro tabelas (`households`, `household_members`, `products`,
`pantry_items`), todas com RLS. `household_id` tem default
`private.current_household()`: o cliente nunca envia a casa.

Três degraus locais obrigatórios antes do PR, além do CI: golden, `test_db.sh`
(pgTAP) e `test_integration.sh` (fim a fim contra o stack local).

Desenvolvimento contra `supabase start` local, **portas 544xx** (a 54322 é de
outro projeto na mesma máquina). Nenhum projeto na nuvem existe.

## Última fatia

**vencendo** — a home separa Vencendo de Despensa em duas abas, com a janela
percentual da ADR 0004 calculada na hora, nunca persistida.

1.398 linhas em 26 arquivos. O contador de arquivos passou do teto por causa
dos 6 PNG de golden (4 novos, 2 apagados); em código a fatia ficou na faixa.

Duas coisas que só apareceram construindo: `created_at` precisou entrar no item
(é o começo da janela quando não há data de compra) e **despensa vazia não é
"tudo dentro do prazo"** — quem nunca cadastrou nada vê o convite, não um
parabéns.

## Próximas fatias

1. **baixa** — dou baixa de N unidades dizendo se consumi ou joguei fora, e a
   quantidade da lista passa a ser derivada dos movimentos.
2. **freezer** — movo item para o freezer informando a nova validade, com
   sugestão vinda da categoria do alimento.
3. **lista-de-compras** — o segundo pilar; vem quase de graça depois da baixa,
   porque é ela que sabe quando o último item de um produto zerou.

## Débitos conhecidos

- **"Hoje" é lido uma vez por sessão** — `todayProvider` não observa a virada do
  dia. App esquecido aberto de madrugada mostra o dia anterior até reabrir.
- **Realtime não verificado** — `watchItems` usa o stream do Supabase; a
  integração lê por consulta direta com as mesmas colunas.
- **Nenhum toque real na tela** — painel do simulador iOS sem permissão. Existe
  um simulador `Despensa iPhone 17 Pro` criado e desligado.
- **CI não cobre RLS** — custo aceito na [ADR 0010](adr/0010-teste-de-integracao.md);
  quem cobre é o pgTAP e a integração, os dois locais.
- **Nome de produto é sensível à caixa** — "Arroz" e "arroz" viram dois produtos
  na mesma casa. A restrição única usa colunas simples porque índice funcional
  não serve como alvo de `on conflict`.
- **`item_tile.dart` abriga o formato de data** da despensa; o nome do arquivo
  não conta isso.
- **Offline** — v1 é online-only; modelo preparado
  ([ADR 0005](adr/0005-sincronizacao.md)).
- **Leitura de EAN** — colunas prontas e nulas, sem tela.
- **Quantidade parcial** ("meio pacote") — interessante, não essencial.
- **Tela de gastos** — preço já é gravado, sem tela.
- **Push** — desejado, fora da v1. Vencer não dispara nada (ADR 0004): o
  usuário abre o app e vê.
- **Multiusuário** — schema pronto, falta convite e aceite
  ([ADR 0002](adr/0002-multi-tenancy.md)).
- **Sem lint de Riverpod** — não resolve nesta versão do SDK
  ([ADR 0007](adr/0007-gerencia-de-estado.md)).

## Armadilhas

- **Janela curta cai no piso e engana ao montar dado de teste.** Item cadastrado
  hoje com validade em 4 dias tem alerta de 2 — fica `ok`, não "vencendo". Para
  um item aparecer em Vencendo com folga, dê a ele uma **data de compra** antiga.
- **Golden precisa de `todayProvider` sobrescrito**, senão o PNG muda sozinho
  amanhã e o degrau 1 deixa de ser degrau.
- **Respingo de toque congela no PNG** — depois de `tap` numa aba, pump de ~2 s
  antes de comparar, ou o golden mostra um retângulo que não existe.
- **Índice único parcial não serve como alvo de `on conflict`.** O upsert falha
  com "no unique or exclusion constraint matching". Use restrição.
- **Asserção de banco tem que ser relativa** aos dados que o próprio teste cria.
  `count(*) = 1` passa em banco resetado e quebra no primeiro uso local.
- **View temporária em pgTAP precisa de `grant select`** para sobreviver ao
  `set local role authenticated`, senão falha por permissão e não por regra.
- **Função em policy precisa de `execute`** — é avaliada como quem consulta.
  Função de **trigger** é o oposto: permissão é checada na criação.
- **`--exclude-tags` repetido não acumula** — a segunda ocorrência substitui a
  primeira. Use seletor booleano: `--exclude-tags "golden || integration"`.
- **`supabase test db` fica preso** puxando imagem Docker. Use
  `bash tool/test_db.sh`.
- **Daemon do Docker pendura sem avisar** — quando `docker version` não responde,
  nenhum degrau local funciona e a saída é reiniciar o Docker Desktop, o que
  derruba containers de outros projetos.
- **Provider global sobrevive ao fechamento da tela** — formulário precisa zerar
  o estado depois de salvar.
- **`pumpAndSettle` nunca volta** com `TextField` ou spinner na tela. Use pump de
  duração fixa.
- Golden vira caixinha sem `pumpGolden`/`pumpGoldenScreen`, e diverge entre
  macOS e Linux — roda local, fica fora do CI.
- Código de barras identifica o **produto**, nunca o lote.
- `DateTime.now()` direto no domínio torna a janela de vencimento intestável; a
  hora é descartada na construção do item.
- Quantidade será derivada de movimentos, nunca gravada — materializar em coluna
  reintroduz o conflito que a [ADR 0005](adr/0005-sincronizacao.md) evita.
- `analyzer` do Flutter 3.44.6 é < 13; pacote de tooling que exige 13 não resolve.
