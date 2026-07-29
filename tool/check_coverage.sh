#!/usr/bin/env bash
# Cobertura mínima em lib/domain e lib/data (ADR 0008).
# presentation fica de fora de propósito: lá a verificação real é o golden.
set -uo pipefail

minimo="${1:-70}"
lcov="coverage/lcov.info"

if [ ! -f "$lcov" ]; then
  echo "FALHA: $lcov não existe. Rode: flutter test --coverage" >&2
  exit 1
fi

leia=$(awk -v FS=':' '
  /^SF:/    { medido = ($2 ~ /lib\/(domain|data)\//) }
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
