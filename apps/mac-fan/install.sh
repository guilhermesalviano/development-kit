#!/usr/bin/env bash
# One-time setup: enable SMC fan control, let your user set the fan speed, add the app launcher.
# Run as your normal user (it asks for sudo only when needed).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_ID=local.guibs.MacFan
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
PARAM=/sys/module/macsmc_hwmon/parameters/fan_control

if [[ $EUID -eq 0 ]]; then
  echo "Run this as your normal user (it asks for sudo only when needed)." >&2
  exit 1
fi

if [[ ! -e $PARAM ]]; then
  echo "The Apple SMC hwmon driver (macsmc_hwmon) isn't loaded — this app needs a T2 Mac running a T2 Linux kernel." >&2
  exit 1
fi

echo "==> Checking dependencies"
PKGS=(python3-gi gir1.2-gtk-4.0 gir1.2-adw-1)
if ! dpkg -s "${PKGS[@]}" >/dev/null 2>&1; then
  sudo apt-get install -y "${PKGS[@]}"
fi

echo "==> Enabling fan control in the SMC driver (sudo)"
echo "options macsmc_hwmon fan_control=1" | sudo tee /etc/modprobe.d/mac-fan.conf >/dev/null
echo Y | sudo tee "$PARAM" >/dev/null

echo "==> Allowing $USER to set the fan speed (sudo)"
sed "s|@USER@|$USER|g" "$DIR/data/70-mac-fan.rules" | sudo tee /etc/udev/rules.d/70-mac-fan.rules >/dev/null
sudo udevadm control --reload-rules
sudo udevadm trigger --action=change --subsystem-match=hwmon --attr-match=name=macsmc_hwmon
sudo udevadm settle

echo "==> Adding Mac Fan to the app menu"
chmod +x "$DIR/mac-fan"
mkdir -p "$DATA/applications" "$DATA/icons/hicolor/scalable/apps"
install -m 644 "$DIR/data/$APP_ID.svg" "$DATA/icons/hicolor/scalable/apps/$APP_ID.svg"
sed "s|@EXEC@|\"$DIR/mac-fan\"|" "$DIR/data/$APP_ID.desktop" > "$DATA/applications/$APP_ID.desktop"
update-desktop-database "$DATA/applications" 2>/dev/null || true

echo
ls -l /sys/class/hwmon/*/fan*_target 2>/dev/null | grep -q " $USER " \
  && echo "Done! Open “Mac Fan” from the app menu." \
  || echo "Installed, but the fan isn't writable by $USER yet — reboot and it will be."
