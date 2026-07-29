#!/usr/bin/env bash
# Cobertura mínima em lib/domain e lib/data (ADR 0008).
#
# Duas exclusões, ambas deliberadas:
#   presentation  — lá a verificação real é o golden.
#   supabase_*    — binding do SDK, delegação pura, impossível exercitar sem
#                   rede. Em troca, nada de lógica pode morar nesses arquivos;
#                   o que precisa ser pensado vai para um irmão puro (por
#                   exemplo auth_error.dart), que é medido.
set -uo pipefail

minimo="${1:-70}"
lcov="coverage/lcov.info"

if [ ! -f "$lcov" ]; then
  echo "FALHA: $lcov não existe. Rode: flutter test --coverage" >&2
  exit 1
fi

leia=$(awk -v FS=':' '
  /^SF:/    { medido = ($2 ~ /lib\/(domain|data)\//) && ($2 !~ /\/supabase_[^\/]*\.dart$/) }
  /^DA:/    { if (medido) { total++; split($2, c, ","); if (c[2] > 0) cobertas++ } }
  END       { printf "%d %d", cobertas + 0, total + 0 }
' "$lcov")

cobertas=${leia% *}
total=${leia#* }

if [ "$total" -eq 0 ]; then
  echo "cobertura: nenhuma linha em lib/domain ou lib/data ainda — ok"
  exit 0
fi

pct=$(( cobertas * 100 / total ))
echo "cobertura em lib/domain + lib/data: ${pct}% (${cobertas}/${total} linhas)"

if [ "$pct" -lt "$minimo" ]; then
  echo "FALHA: abaixo do mínimo de ${minimo}%." >&2
  exit 1
fi
