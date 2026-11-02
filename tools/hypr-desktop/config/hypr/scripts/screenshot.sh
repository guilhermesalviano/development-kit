#!/usr/bin/env bash
# screenshot.sh region|full — salva em ~/Pictures/Screenshots e copia para a área de transferência.
set -euo pipefail

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

if [ "${1:-region}" = full ]; then
  grim "$file"
else
  geometry="$(slurp)" || exit 0
  grim -g "$geometry" "$file"
fi

wl-copy < "$file"
notify-send -i "$file" "Captura de tela" "$(basename "$file")" || true
