# Estado

> Documento **vivo**: reescrito a cada fatia, nunca acumulado.
> Nada de seção "Concluído" aqui — `git log` é o arquivo morto.
> Teto: 150 linhas (o CI falha acima disso).

## Onde estamos

Fase 0 fechada: domínio, ADRs e superfícies escritos. **Zero código** — o
projeto Flutter ainda não existe.

O próximo passo **não é uma fatia**: é a Fase 1 (andaime), que monta a escada de
verificação. Sem o degrau 1 (golden que o agente lê sozinho) funcionando, não se
abre fatia.

## Última fatia

Nenhuma.

## Próximas fatias

1. **entrar** — entro por link mágico no e-mail, minha casa é criada no primeiro
   acesso, e caio numa dispensa vazia.
2. **cadastro-manual** — cadastro um item com nome e validade e ele aparece na
   dispensa, persistido.
3. **vencendo** — a home lista o que está dentro da janela de vencimento,
   vencidos no topo, ordenado por urgência.

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

## Armadilhas

- Código de barras identifica o **produto**, nunca o lote — validade nunca vem
  do EAN. Não prometer isso na interface.
- `DateTime.now()` chamado direto no domínio torna a janela de vencimento
  intestável — a data de hoje entra por dependência sobrescrevível.
- Golden renderiza texto como caixinha se as fontes reais não forem carregadas.
- Golden diverge entre macOS e Linux — roda local, fica fora do CI.
- Função `SECURITY DEFINER` no schema `public` fica chamável por `anon` — apoio
  de RLS nasce em `private`.
- Quantidade é derivada de movimentos, nunca gravada — materializar em coluna
  reintroduz o conflito que a [ADR 0005](adr/0005-sincronizacao.md) evita.
