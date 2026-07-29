# Fatia: cadastro-manual

tipo: feature

## Pronto quando

Um item que eu cadastrei com nome e validade continua na minha despensa depois
de fechar e reabrir o app.

## Superfícies

- **Cadastro rápido** (nova) — bottom sheet. Obrigatório: nome e validade.
  Opcionais recolhidos: quantidade (padrão 1), local, data de compra, preço.
- **Home** (muda) — deixa de ser só o estado vazio e passa a listar os itens da
  despensa, com FAB de adicionar. O estado vazio continua, agora convidando a
  cadastrar o primeiro item.

A separação **Vencendo / Despensa** e a barra de abas ficam para a fatia
`vencendo`: não se constrói barra de abas antes de haver duas coisas para pôr
nela. Até lá a home é a despensa, e `docs/surfaces.md` descreve o destino, não o
presente.

Mockup aprovado: **pendente** — o código não começa antes disso.

## Arquivos que mudam

Lista fechada. Arquivo fora dela = parar e reavaliar o tamanho da fatia.

```
supabase/migrations/<ts>_produto_e_item.sql
supabase/tests/produto_e_item_test.sql
lib/domain/pantry/product.dart
lib/domain/pantry/pantry_item.dart
lib/domain/pantry/pantry_repository.dart
lib/data/pantry/pantry_mapper.dart               puro, medido por cobertura
lib/data/pantry/supabase_pantry_repository.dart  binding, só delegação
lib/presentation/pantry/pantry_providers.dart
lib/presentation/pantry/cadastro_sheet.dart
lib/presentation/pantry/item_tile.dart
lib/presentation/home/home_screen.dart           passa a listar
lib/main.dart                                    override do novo repositório
test/domain/pantry/pantry_item_test.dart
test/data/pantry/pantry_mapper_test.dart
test/presentation/pantry/cadastro_sheet_test.dart
test/golden/cadastro_test.dart
docs/surfaces.md                                 nota de que a home é provisória
```

## Casos

**Domínio (teste puro)**
- item sem validade não é construível
- quantidade menor que 1 não é construível
- nome só de espaços não vira produto
- preço é inteiro em centavos; nenhum caminho aceita `double`

**Banco (pgTAP, asserções relativas aos dados que o arquivo cria)**
- produto da casa não é visível por outra casa (RLS)
- item não é visível por outra casa (RLS)
- validade nula é recusada
- quantidade zero é recusada

**Tela (widget + golden)**
- salvar desabilitado até nome e validade existirem
- salvar fecha o sheet e o item aparece na lista
- dois itens do mesmo produto com validades diferentes viram duas linhas
- opcionais recolhidos por padrão; abrir e preencher local funciona
- falha de rede ao salvar mostra erro e **não** perde o que foi digitado
- estado vazio convida a cadastrar o primeiro item

**Persistência (o "pronto quando")**
- cadastrar, reabrir o app, o item continua lá

## Fora de escopo

- **leitura de código de barras** — as colunas `ean` e `food_category` nascem
  nulas (ADR 0004, ADR 0006), sem nenhuma tela que as use
- **tabela de movimentos e quantidade derivada** — a lista mostra a quantidade
  cadastrada; movimentos chegam na fatia `baixa`, junto com quem escreve nela
- **janela de vencimento e selo de validade** — fatia `vencendo`
- **abas, filtro por local, modo freezer**
- **editar e remover item** — cadastrar e ver é o fato desta fatia
- **catálogo canônico global** — só produto da casa existe aqui
- tela de gastos, lista de compras, push
