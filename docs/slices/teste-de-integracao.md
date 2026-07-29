# Fatia: teste-de-integracao

tipo: débito

## Pronto quando

`bash tool/test_integration.sh` prova, num comando, que entrar e cadastrar item
funcionam contra o Supabase local.

## Superfícies

Nenhuma. Nenhuma linha de `lib/` muda nesta fatia — se mudar, é escopo vazando.

Mockup aprovado: não se aplica.

## Arquivos que mudam

Lista fechada. Arquivo fora dela = parar e reavaliar.

```
docs/adr/0010-teste-de-integracao.md
tool/test_integration.sh
test/integration/harness.dart              entrar por OTP lendo a caixa local
test/integration/entrar_test.dart          o que provou a fatia `entrar`
test/integration/cadastro_test.dart        o que provou `cadastro-manual`
dart_test.yaml                             tag `integration`
AGENTS.md                                  escada e definição de pronto
docs/state.md                              fechamento
```

## Casos

O conteúdo vem dos dois scripts que hoje vivem no scratchpad e são jogados fora
a cada fatia:

**entrar**
- código do e-mail abre sessão com o endereço certo
- código errado devolve `AuthFailure.invalidCode` — é disso que a tela depende
- o trigger provisiona exatamente uma casa para o usuário novo
- `sair` encerra a sessão

**cadastro-manual**
- dois itens do mesmo produto com validades diferentes persistem como dois itens
- e reaproveitam **uma ficha só** (ADR 0006)
- preço e local sobrevivem ao ciclo
- `household_id` gravado é o da sessão, sem o cliente enviá-lo
- um cliente novo lê o que a sessão anterior gravou

**o próprio script**
- falha com mensagem clara quando o Supabase local não está de pé
- não deixa lixo que faça o pgTAP quebrar depois (a armadilha da asserção
  absoluta já mordeu uma vez)

## Fora de escopo

- **rodar no CI** — exige Docker e Supabase no runner; a ADR registra a decisão
  e o custo aceito, na mesma linha de golden e pgTAP
- **projeto Supabase na nuvem** ou ambiente de staging
- **teste do Realtime** (`watchItems` via stream) — continua débito próprio
- **teste de UI de ponta a ponta** (toque na tela) — depende do painel do
  simulador, que é outro débito
- reescrever qualquer coisa de `lib/`
