#!/usr/bin/env bash
# Testes pgTAP contra o Postgres local que já está de pé.
#
# Por que não `supabase test db`: aquele comando puxa uma imagem Docker própria
# só para rodar pg_prove. Este roda o mesmo arquivo no container que o
# `supabase start` já subiu — segundos em vez de minutos, sem pull.
#
# Fica fora do CI: exige Docker no runner (ADR 0008, mesma regra do golden).
set -uo pipefail

container="supabase_db_$(basename "$PWD")"

if ! docker exec "$container" true 2>/dev/null; then
  echo "FALHA: container $container não está de pé. Rode: supabase start" >&2
  exit 1
fi

falhou=0
for arquivo in supabase/tests/*.sql; do
  saida=$(docker exec -i "$container" \
    psql -U postgres -d postgres -v ON_ERROR_STOP=1 -f - < "$arquivo" 2>&1)

  # NOTICE não é falha; ERROR e "not ok" são.
  if echo "$saida" | grep -qE '^ *not ok|ERROR:'; then
    echo "FALHA em $arquivo:"
    echo "$saida" | grep -E '^ *not ok|ERROR:|^ *# ' | sed 's/^/       /'
    falhou=1
  else
    total=$(echo "$saida" | grep -cE '^ *ok [0-9]+')
    echo "$(basename "$arquivo"): ${total} testes ok"
  fi
done

exit "$falhou"
