#!/usr/bin/env bash
#
# run.sh - Desktop Hyprland estilo Omarchy (barra + lançador) no Debian 13.
#
# Instala o Hyprland pelo trixie-backports (repositório oficial do Debian),
# Waybar, fuzzel, mako etc., e copia as configurações de config/ para ~/.config.
# O GNOME continua instalado: escolha a sessão "Hyprland" na tela de login.
#

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="${TOOL_DIR}/config"
CONFIG_DST="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/toolbox-hypr-desktop/$(date +%Y%m%d-%H%M%S)"

BACKPORTS_FILE="/etc/apt/sources.list.d/debian-backports.sources"
BACKPORTS_PKGS=(hyprland hypridle hyprlock xdg-desktop-portal-hyprland hyprpolkitagent)
MAIN_PKGS=(
  waybar fuzzel mako-notifier alacritty swaybg swayosd
  grim slurp wl-clipboard libnotify-bin playerctl pavucontrol btop
  network-manager-gnome blueman
  fonts-jetbrains-mono fonts-font-awesome
)

usage() {
  cat <<EOF
Uso: ./toolbox hypr-desktop <ação>

Ações:
  install    Instala os pacotes (pede sudo) e copia as configurações.
  packages   Só instala os pacotes: ativa o trixie-backports se preciso,
             instala ${BACKPORTS_PKGS[*]} de lá e o resto do repositório normal.
  configs    Só copia config/ para ${CONFIG_DST}. Arquivos existentes e
             diferentes vão antes para ~/.local/state/toolbox-hypr-desktop/<data>/.
  check      Valida o hyprland.conf instalado (Hyprland --verify-config).
  status     Mostra o que está instalado e configurado.
EOF
}

confirm() {
  local answer
  read -r -p "$1 [s/N] " answer
  [[ "$answer" =~ ^[sSyY]$ ]]
}

require_debian_trixie() {
  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" != debian || "${VERSION_CODENAME:-}" != trixie ]]; then
    echo "Erro: feito para Debian 13 (trixie); este sistema é ${PRETTY_NAME:-desconhecido}." >&2
    exit 1
  fi
}

has_backports() {
  grep -rqs 'trixie-backports' /etc/apt/sources.list /etc/apt/sources.list.d/
}

cmd_packages() {
  require_debian_trixie

  if ! has_backports; then
    echo "O Hyprland não está no repositório principal do Debian 13, só no trixie-backports."
    echo "Isso cria ${BACKPORTS_FILE}. Pacotes de backports só são instalados quando"
    echo "pedidos explicitamente (-t trixie-backports); o resto do sistema não muda."
    confirm "Ativar o trixie-backports?" || { echo "Cancelado."; exit 1; }
    sudo tee "$BACKPORTS_FILE" >/dev/null <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian/
Suites: trixie-backports
Components: main non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
  fi

  echo
  echo "Vai instalar:"
  echo "  backports: ${BACKPORTS_PKGS[*]}"
  echo "  principal: ${MAIN_PKGS[*]}"
  confirm "Continuar?" || { echo "Cancelado."; exit 1; }

  sudo apt-get update
  sudo apt-get install -y -t trixie-backports "${BACKPORTS_PKGS[@]}"
  sudo apt-get install -y "${MAIN_PKGS[@]}"
}

cmd_configs() {
  local src rel dst copied=0 backed_up=0
  while IFS= read -r -d '' src; do
    rel="${src#"$CONFIG_SRC"/}"
    dst="${CONFIG_DST}/${rel}"
    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
      continue
    fi
    if [[ -e "$dst" ]]; then
      mkdir -p "$(dirname "${BACKUP_DIR}/${rel}")"
      cp -p "$dst" "${BACKUP_DIR}/${rel}"
      backed_up=$((backed_up + 1))
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    [[ "$rel" == *.sh ]] && chmod +x "$dst"
    echo "  ${rel}"
    copied=$((copied + 1))
  done < <(find "$CONFIG_SRC" -type f -print0 | sort -z)

  echo "${copied} arquivo(s) copiado(s) para ${CONFIG_DST}."
  if (( backed_up > 0 )); then
    echo "${backed_up} arquivo(s) antigo(s) salvo(s) em ${BACKUP_DIR}."
  fi
  if (( copied > 0 )) && command -v hyprctl >/dev/null && hyprctl version >/dev/null 2>&1; then
    hyprctl reload >/dev/null && echo "Hyprland recarregado."
  fi
}

cmd_check() {
  if ! command -v Hyprland >/dev/null; then
    echo "Hyprland não está instalado. Rode: ./toolbox hypr-desktop packages" >&2
    exit 1
  fi
  Hyprland --verify-config -c "${CONFIG_DST}/hypr/hyprland.conf"
}

cmd_status() {
  local p
  echo "Pacotes:"
  for p in "${BACKPORTS_PKGS[@]}" "${MAIN_PKGS[@]}"; do
    if dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed'; then
      printf '  ok      %s\n' "$p"
    else
      printf '  falta   %s\n' "$p"
    fi
  done
  echo
  if has_backports; then echo "trixie-backports: ativado"; else echo "trixie-backports: desativado"; fi
  if [[ -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
    echo "Sessão de login: Hyprland disponível"
  else
    echo "Sessão de login: Hyprland ausente"
  fi
  if [[ -f "${CONFIG_DST}/hypr/hyprland.conf" ]]; then
    echo "Configuração: ${CONFIG_DST}/hypr/hyprland.conf"
  else
    echo "Configuração: não instalada (./toolbox hypr-desktop configs)"
  fi
}

case "${1:-}" in
  install)  cmd_packages; echo; cmd_configs
            echo
            echo "Pronto. Saia da sessão e escolha \"Hyprland\" na tela de login (engrenagem)." ;;
  packages) cmd_packages ;;
  configs)  cmd_configs ;;
  check)    cmd_check ;;
  status)   cmd_status ;;
  -h|--help|help|"") usage ;;
  *) echo "Ação desconhecida: $1" >&2; usage >&2; exit 1 ;;
esac
