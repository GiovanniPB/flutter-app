#!/usr/bin/env bash
# Teste de integração contra o Supabase local (ADR 0010).
#
# Fica fora do CI: exige Docker e o stack de pé. Falha alto quando não está —
# teste de integração que passa sem banco é pior que teste que não existe.
set -uo pipefail

container="supabase_db_$(basename "$PWD")"

if ! docker exec "$container" true 2>/dev/null; then
  echo "FALHA: container $container não está de pé. Rode: supabase start" >&2
  exit 1
fi

env_supabase=$(supabase status -o env 2>/dev/null)
if [ -z "$env_supabase" ]; then
  echo "FALHA: 'supabase status' não respondeu. Rode: supabase start" >&2
  exit 1
fi

extrair() { echo "$env_supabase" | grep "^$1=" | cut -d= -f2- | tr -d '"'; }

api_url=$(extrair API_URL)
publishable_key=$(extrair PUBLISHABLE_KEY)

# A porta da caixa de e-mail não sai no `status -o env`; vem do config.
porta_email=$(awk '/^\[inbucket\]/{ok=1} ok&&/^port *=/{print $3; exit}' \
  supabase/config.toml)
mail_url="http://127.0.0.1:${porta_email}"

for par in "API_URL:$api_url" "PUBLISHABLE_KEY:$publishable_key" \
           "MAIL_URL:$mail_url"; do
  if [ -z "${par#*:}" ]; then
    echo "FALHA: não descobri ${par%%:*} a partir do stack local." >&2
    exit 1
  fi
done

echo "stack local: $api_url · caixa de e-mail: $mail_url"

exec fvm flutter test test/integration/ \
  --dart-define="SUPABASE_URL=$api_url" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$publishable_key" \
  --dart-define="MAIL_URL=$mail_url" \
  --dart-define="DB_CONTAINER=$container"
