import json
import os
from pathlib import Path

CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config")
CONFIG_FILE = CONFIG_HOME / "mac-fan" / "config.json"
AUTOSTART_FILE = CONFIG_HOME / "autostart" / "mac-fan.desktop"
LAUNCHER = Path(__file__).resolve().parent.parent / "mac-fan"

# mode: "auto" (SMC decides), "fixed" (rpm), "curve" (linear from curve_low °C to curve_high °C)
DEFAULTS = {"mode": "auto", "rpm": 2500, "curve_low": 55, "curve_high": 85, "background": True}


def load():
    try:
        data = json.loads(CONFIG_FILE.read_text())
    except (OSError, ValueError):
        data = {}
    return {**DEFAULTS, **data}


def save(cfg):
    CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
    tmp = CONFIG_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(cfg, indent=2))
    tmp.replace(CONFIG_FILE)


def autostart_enabled():
    return AUTOSTART_FILE.exists()


def set_autostart(enabled):
    if not enabled:
        AUTOSTART_FILE.unlink(missing_ok=True)
        return
    AUTOSTART_FILE.parent.mkdir(parents=True, exist_ok=True)
    AUTOSTART_FILE.write_text(
        "[Desktop Entry]\nType=Application\nName=Mac Fan\n"
        f'Exec="{LAUNCHER}" --background\nIcon=local.guibs.MacFan\nNoDisplay=true\n'
        "X-GNOME-Autostart-enabled=true\n"
    )
