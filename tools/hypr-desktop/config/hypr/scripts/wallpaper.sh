#!/usr/bin/env bash
# Usa ~/.config/hypr/wallpaper.{png,jpg,jpeg} se existir; senão, cor sólida.
for f in "$HOME"/.config/hypr/wallpaper.{png,jpg,jpeg}; do
  [ -f "$f" ] && exec swaybg -m fill -i "$f"
done
exec swaybg -c '#1a1b26'
