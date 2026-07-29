# Fatia: entrar

tipo: feature

## Pronto quando

O código de 6 dígitos que chegou no meu e-mail me deixa dentro do app, numa
despensa vazia que é minha.

## Superfícies

- **Entrar** (nova) — dois passos no mesmo fluxo: pedir e-mail, digitar código.
  Erro inline, reenvio de código, sem revelar se a conta já existe.
- **Home** (nova, casca) — só o estado vazio "nada vencendo" e um `sair`
  discreto. Sem FAB: o botão de adicionar nasce na fatia `cadastro-manual`,
  junto com a ação que ele dispara.

Mockup aprovado: **pendente** — o código não começa antes disso.

## Arquivos que mudam

Lista fechada. Arquivo fora dela durante a execução = parar e reavaliar o
tamanho da fatia.

```
supabase/config.toml                              (supabase init)
supabase/migrations/0001_casa_e_membro.sql
supabase/tests/casa_e_membro_test.sql             (pgTAP)
lib/main.dart
lib/app/app.dart                                  roteia por estado de auth
lib/app/supabase.dart                             init com --dart-define
lib/domain/auth/email.dart                        value object com validação
lib/domain/auth/auth_repository.dart              contrato
lib/data/auth/supabase_auth_repository.dart
lib/presentation/auth/entrar_screen.dart
lib/presentation/auth/entrar_providers.dart
lib/presentation/home/home_screen.dart
test/domain/auth/email_test.dart
test/presentation/auth/entrar_screen_test.dart
test/golden/entrar_test.dart
docs/adr/0009-provisionamento-de-casa.md
AGENTS.md                                         supabase start no toolchain
README.md                                         idem
```

## Casos

**Domínio (teste puro)**
- e-mail inválido não chega na rede: erro antes de qualquer chamada
- e-mail com espaço nas pontas é aceito, normalizado em minúsculas

**Tela (widget + golden)**
- estado inicial: campo de e-mail, botão desabilitado até o e-mail ser válido
- estado de código: seis dígitos, com o e-mail visível para conferência
- código errado: erro inline, campo limpo, permite nova tentativa
- código expirado: mesma mensagem do código errado, com reenvio disponível
- falha de rede: mensagem de erro, tela não trava nem perde o e-mail digitado
- home vazia: "nada vencendo" como estado tranquilo, não como erro

**Banco (pgTAP, `supabase test db`)**
- primeiro login cria **exatamente uma** casa, com o membro vinculado
- segundo login do mesmo e-mail não cria casa nova
- membro da casa A não consegue ler a casa B (RLS)

**Fim a fim (manual, degrau 3)**
- código do Inbucket entra no app e a home abre
- fecho e reabro o app: continuo dentro (sessão persistida)
- `sair` volta para Entrar

## Fora de escopo

- **link clicável / deep link** — esquema de URL, Universal Links e App Links
  ficam para quando (e se) o código de 6 dígitos incomodar
- **projeto Supabase na nuvem** — esta fatia roda contra `supabase start`
- convite, aceite, lista de membros (casa existe, mas é invisível)
- qualquer CRUD de produto ou item da despensa
- FAB e cadastro rápido — fatia seguinte
- recuperação de conta, troca de e-mail, tela de perfil
- `supabase test db` no CI: exige Docker no runner. Fica local, como o golden.
