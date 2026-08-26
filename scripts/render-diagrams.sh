#!/usr/bin/env bash
# Рендерит все *.puml в PNG и SVG рядом с исходником.
# Ищет PlantUML в таком порядке: команда plantuml, Docker-образ plantuml/plantuml,
# либо jar по пути из переменной окружения PLANTUML_JAR.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

render() {
  local fmt="$1"; shift
  if command -v plantuml >/dev/null 2>&1; then
    plantuml -t"$fmt" "$@"
  elif command -v docker >/dev/null 2>&1; then
    docker run --rm -v "$ROOT":/work -w /work plantuml/plantuml -t"$fmt" "$@"
  elif [ -n "${PLANTUML_JAR:-}" ] && [ -f "$PLANTUML_JAR" ]; then
    java -jar "$PLANTUML_JAR" -t"$fmt" "$@"
  else
    echo "PlantUML не найден. Нужна команда plantuml, либо Docker, либо переменная PLANTUML_JAR." >&2
    exit 1
  fi
}

mapfile -t PUMLS < <(find . -name '*.puml' -not -path './.git/*')
if [ ${#PUMLS[@]} -eq 0 ]; then
  echo "Файлы *.puml не найдены."
  exit 0
fi

echo "Рендерю ${#PUMLS[@]} диаграмм в PNG и SVG..."
render png "${PUMLS[@]}"
render svg "${PUMLS[@]}"

# В контексте pre-commit добавляем сгенерированные картинки в индекс.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  find . \( -name '*.png' -o -name '*.svg' \) -path '*/diagrams/*' -print0 | xargs -0 git add 2>/dev/null || true
fi

echo "Готово."
