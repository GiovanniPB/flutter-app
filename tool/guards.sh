#!/usr/bin/env bash
# Guardas de documentação. Roda local e no CI.
# Impedem exatamente o modo de falha conhecido: documento vivo virar diário.
set -uo pipefail

falhou=0

# 1. state.md não pode virar diário
if [ -f docs/state.md ]; then
  linhas=$(wc -l < docs/state.md | tr -d ' ')
  if [ "$linhas" -gt 150 ]; then
    echo "FALHA: docs/state.md tem ${linhas} linhas (teto 150)."
    echo "       Ele é reescrito, não acumulado. Histórico vive no git log."
    falhou=1
  fi
fi

# 2. histórico não se duplica em markdown
# Radicais SEM acento de propósito: [ií] em expressão de colchetes não casa o
# caractere multibyte quando LANG está vazio, e o padrão precisa de -i.
DIARIO='^#+.*(conclu|hist|changelog|feito em|entregue em)'
if grep -rqiE "$DIARIO" docs/state.md docs/surfaces.md 2>/dev/null; then
  echo "FALHA: seção de histórico em documento vivo:"
  grep -rniE "$DIARIO" docs/state.md docs/surfaces.md 2>/dev/null | sed 's/^/       /'
  echo "       Remova. git log já responde isso."
  falhou=1
fi

# 3. não pode dar merge com contrato aberto
abertos=$(find docs/slices -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "$abertos" -ne 0 ] && [ "${CI:-}" = "true" ]; then
  echo "FALHA: contrato de fatia ainda aberto:"
  ls docs/slices/*.md | sed 's/^/       /'
  echo "       Rode tool/close-slice.sh antes do merge."
  falhou=1
fi

if [ "$falhou" -eq 0 ]; then
  echo "guardas: ok"
fi
exit "$falhou"
