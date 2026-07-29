# Estado

> Documento **vivo**: reescrito a cada fatia, nunca acumulado.
> Nada de seção "Concluído" aqui — `git log` é o arquivo morto.
> Teto: 150 linhas (o CI falha acima disso).

## Onde estamos

Fundação escrita e andaime de pé. O projeto Flutter existe, o gate roda limpo
e o degrau 1 da escada está provado: `test/golden/escada_test.dart` gera um PNG
com texto e ícone reais, que o agente lê sozinho.

Nenhum código de produto ainda — `lib/main.dart` é um placeholder que a
primeira fatia substitui. Não há projeto Supabase criado nem tabela nenhuma.

## Última fatia

Nenhuma.

## Próximas fatias

1. **entrar** — entro por link mágico no e-mail, minha casa é criada no primeiro
   acesso, e caio numa despensa vazia.
2. **cadastro-manual** — cadastro um item com nome e validade e ele aparece na
   despensa, persistido.
3. **vencendo** — a home lista o que está dentro da janela de vencimento,
   vencidos no topo, ordenado por urgência.

A fatia 1 precisa de um projeto Supabase real e do `env/dev.json` preenchido —
isso é a primeira coisa do contrato dela.

## Débitos conhecidos

- **Offline** — v1 é online-only. O modelo já está preparado
  ([ADR 0005](adr/0005-sincronizacao.md)); falta a fila de escrita.
- **Lista de compras** — segundo pilar do produto, adiado porque depende do
  fluxo de baixa existir.
- **Leitura de código de barras** — a v1 nasce com cadastro manual; o EAN é
  acelerador, não requisito.
- **Quantidade parcial** ("meio pacote") — interessante, não essencial.
- **Tela de gastos** — o preço é gravado desde a primeira fatia, sem tela.
- **Push** — desejado, fora da v1.
- **Multiusuário** — schema pronto, falta convite e aceite
  ([ADR 0002](adr/0002-multi-tenancy.md)).
- **Sem lint de Riverpod** — `riverpod_lint` não resolve nesta versão do SDK
  ([ADR 0007](adr/0007-gerencia-de-estado.md)); revisitar em upgrade futuro.

## Armadilhas

- Código de barras identifica o **produto**, nunca o lote — validade nunca vem
  do EAN. Não prometer isso na interface.
- `DateTime.now()` chamado direto no domínio torna a janela de vencimento
  intestável — a data de hoje entra por provider sobrescrevível.
- Golden só renderiza texto de verdade via `pumpGolden` do harness, que carrega
  a Roboto do SDK. Widget montado direto com `pumpWidget` vira caixinha.
- Golden diverge entre macOS e Linux — roda local, fica fora do CI.
- Função `SECURITY DEFINER` no schema `public` fica chamável por `anon` — apoio
  de RLS nasce em `private`.
- Quantidade é derivada de movimentos, nunca gravada — materializar em coluna
  reintroduz o conflito que a [ADR 0005](adr/0005-sincronizacao.md) evita.
- `analyzer` do Flutter 3.44.6 é < 13; pacotes de tooling que exigem 13 não
  resolvem. Foi o que derrubou a geração de código.
