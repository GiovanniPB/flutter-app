# 0010 — Teste de integração vive no repo, roda local, não roda no CI

## Contexto

As duas primeiras fatias foram provadas fim a fim contra o Supabase local por
scripts escritos no scratchpad — e jogados fora nas duas vezes. O trabalho foi
refeito do zero na segunda.

O que esses scripts provam não é provável de outro jeito: trigger de
provisionamento, RLS entre casas, `default private.current_household()`, e o
fato de o upsert de produto reaproveitar a ficha. Justamente as coisas que
quebraram nesta sessão — e que teste com dublê não pega, porque o dublê não tem
Postgres dentro.

A tensão é só uma: esse teste precisa de Docker, e o runner do CI não tem o
stack de pé.

## Decisão

**O teste de integração mora no repositório, roda local, e o CI não o executa.**

- Fica em `test/integration/`, com a tag `integration`.
- O gate normal ignora: `flutter test --exclude-tags golden --exclude-tags integration`.
- Roda por `bash tool/test_integration.sh`, que **falha com mensagem clara**
  quando o Supabase local não está de pé — nunca silenciosamente verde.
- Entra na definição de pronto como degrau **local**, ao lado de golden e pgTAP.
- Configuração vem de `supabase status`, injetada por `--dart-define`. Nenhuma
  URL nem chave fica escrita no repositório, mesmo sendo a chave local pública.
- Cada teste **cria o próprio usuário** e o apaga no fim. A cascata leva casa,
  produtos e itens. Teste que deixa lixo é teste que quebra o vizinho — a
  asserção absoluta do pgTAP já morreu uma vez por isso.

Isso não é uma exceção nova: é a terceira aplicação da mesma regra que golden e
pgTAP já seguem. **Verificação cara e específica de máquina roda local, com
script próprio, e está na definição de pronto.**

## Alternativas descartadas

- **Continuar no scratchpad** — o motivo desta ADR. Duas fatias, dois scripts
  escritos e descartados.
- **Subir Supabase no CI** (`supabase/setup-cli` + `supabase start` no runner) —
  tecnicamente possível, e o custo é minutos por execução em toda PR mais uma
  classe nova de intermitência. Revisitar quando o projeto tiver colaborador que
  não roda o stack local.
- **Projeto de staging na nuvem** — estado compartilhado entre execuções torna
  asserção relativa mais difícil, e custa dinheiro para provar o que o local já
  prova.
- **Dublar o SDK e testar tudo em memória** — não prova RLS, trigger nem
  `default`, que é exatamente o que quebrou. Provaria só que o nosso código
  chama o que a gente mandou chamar.

## Consequência

Fácil: o que foi descoberto na mão duas vezes passa a rodar num comando, e a
próxima fatia herda a capacidade em vez de reescrevê-la.

Difícil — e este é o custo aceito de propósito: **o CI pode ficar verde com a
RLS quebrada.** Duas coisas seguram isso: o pgTAP cobre os invariantes de banco e
também é obrigatório antes do PR, e a definição de pronto exige os dois degraus
locais. É disciplina apoiada por script, não por memória.
