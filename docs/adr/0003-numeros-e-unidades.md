# 0003 — Quantidade inteira, dinheiro em centavos, tamanho no nome

## Contexto

Três grandezas aparecem no domínio: quantidade de unidades, preço pago e
tamanho da embalagem. Cada uma tem uma armadilha diferente — ponto flutuante em
dinheiro, unidade implícita em quantidade, e estrutura prematura no tamanho.

## Decisão

**Quantidade** é **inteiro ≥ 1**, contando unidades de embalagem. Doze caixas
de leite iguais com a mesma validade são um item de quantidade 12, não doze
itens. Não existe fração: "meio pacote" não é representável, por decisão.

**Dinheiro** é **inteiro em centavos**, moeda **BRL** fixa, campo **opcional**
no item da dispensa (o que *eu* paguei naquela compra, não o preço do produto).
Nenhuma tela consome esse campo na v1 — ele existe porque gravar é barato e
retrofitar é caro. `double` para dinheiro é proibido em qualquer camada.

**Tamanho da embalagem** ("5 kg", "1 L", "500 g") é **parte do nome do
produto**, texto livre. Não é campo estruturado.

## Alternativas descartadas

- **Quantidade decimal** — abriria fração de pacote, que é não-objetivo
  explícito, e traria arredondamento para dentro do domínio.
- **Um item por unidade física** — cadastrar a compra do mês viraria dezenas de
  registros. Foi o que matou a ideia.
- **Tamanho estruturado (valor + unidade)** — só se paga se houver soma ou
  comparação entre embalagens. Sem fração de pacote, não há nem uma nem outra.
- **Multi-moeda** — o app é doméstico e brasileiro.

## Consequência

Fácil: aritmética exata, zero arredondamento, cadastro rápido de compra grande.

Difícil: "quanto arroz eu tenho em kg" é impossível de responder. É aceito — o
app responde "quantos pacotes", que é a pergunta que ele se propõe a responder.

Custo aceito: se um dia o tamanho precisar ser estruturado, é parsing
retroativo de texto livre. Improvável e contido.
