#!/usr/bin/env bash
# Abre uma fatia: valida os portões, cria o branch e o contrato.
set -euo pipefail

nome="${1:-}"
tipo="${2:-feat}"

if [ -z "$nome" ]; then
  echo "uso: tool/new-slice.sh <nome-em-kebab> [feat|fix|chore|docs|test|perf]" >&2
  exit 1
fi

# Portão 1 — a Fase 0 existe
if [ ! -f docs/product.md ]; then
  echo "erro: docs/product.md não existe. Rode a Fase 0 antes de fatiar." >&2
  exit 1
fi

# Portão 2 — uma fatia por vez (é o que sustenta o dimensionamento)
abertos=$(find docs/slices -maxdepth 1 -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
if [ "$abertos" -ne 0 ]; then
  echo "erro: já existe contrato aberto:" >&2
  ls docs/slices/*.md >&2
  echo "feche a fatia atual com tool/close-slice.sh antes de abrir outra." >&2
  exit 1
fi

# Portão 3 — árvore limpa, partindo da main atualizada
if [ -n "$(git status --porcelain)" ]; then
  echo "erro: árvore suja. Commite ou descarte antes de abrir fatia." >&2
  exit 1
fi

git switch main -q
git pull --ff-only -q 2>/dev/null || echo "aviso: não deu pull (sem remoto?), seguindo com a main local"
git switch -c "${tipo}/${nome}" -q

mkdir -p docs/slices
sed "s/{{nome}}/${nome}/g" docs/.templates/slice.md > "docs/slices/${nome}.md"

echo "fatia aberta: ${tipo}/${nome}"
echo "contrato:     docs/slices/${nome}.md"
echo
echo "próximo passo: preencher o contrato ANTES de abrir código."
echo "se o \"pronto quando\" precisar da palavra \"e\", quebre em duas fatias."
