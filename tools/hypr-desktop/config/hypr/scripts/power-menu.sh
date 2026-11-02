#!/usr/bin/env bash
# Menu de energia (Super + Esc ou o botão de energia da barra).
choice="$(printf '%s\n' Bloquear Suspender Sair Reiniciar Desligar \
  | fuzzel --dmenu --prompt 'Energia > ' --lines 5 --width 24)" || exit 0

case "$choice" in
  Bloquear)  loginctl lock-session ;;
  Suspender) systemctl suspend ;;
  Sair)      hyprctl dispatch exit ;;
  Reiniciar) systemctl reboot ;;
  Desligar)  systemctl poweroff ;;
esac
