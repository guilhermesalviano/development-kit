"""Fan and temperature access through the Apple SMC hwmon driver (macsmc_hwmon).

Writing a speed between fanN_min and fanN_max puts that fan in manual mode;
writing 0 hands control back to the SMC. The driver only accepts writes when
the module option fan_control is enabled.
"""
from pathlib import Path

HWMON = Path("/sys/class/hwmon")
FAN_CONTROL = Path("/sys/module/macsmc_hwmon/parameters/fan_control")


class SmcError(Exception):
    pass


def _read(path, default=None):
    try:
        return path.read_text().strip()
    except OSError:
        return default


def _find(name):
    for hw in sorted(HWMON.glob("hwmon*")):
        if _read(hw / "name") == name:
            return hw
    return None


class Fan:
    def __init__(self, hw, index):
        self.hw, self.index = hw, index
        self.label = _read(hw / f"fan{index}_label") or f"Fan {index - 1}"
        self.min = int(_read(hw / f"fan{index}_min", "0"))
        self.max = int(_read(hw / f"fan{index}_max", "0"))

    @property
    def target_path(self):
        return self.hw / f"fan{self.index}_target"

    def rpm(self):
        return int(_read(self.hw / f"fan{self.index}_input", "0"))

    def target(self):
        return int(_read(self.target_path, "0"))

    def writable(self):
        import os
        return os.access(self.target_path, os.W_OK)

    def set(self, rpm):
        """rpm in [min, max] → manual speed; 0 → back to automatic."""
        if rpm:
            rpm = max(self.min, min(self.max, int(rpm)))
        try:
            self.target_path.write_text(str(rpm))
        except OSError as err:
            raise SmcError(f"Couldn't set {self.label}: {err.strerror}") from err


def fans():
    hw = _find("macsmc_hwmon")
    if hw is None:
        return []
    return [Fan(hw, int(p.name[3:-6])) for p in sorted(hw.glob("fan*_input"))]


def fan_control_enabled():
    return _read(FAN_CONTROL) in ("Y", "1")


def cpu_temp():
    """Hottest CPU reading in °C: coretemp package, else the SMC's CPU max (TCXC)."""
    hw = _find("coretemp")
    if hw is not None:
        for label in hw.glob("temp*_label"):
            if _read(label, "").startswith("Package"):
                value = _read(label.with_name(label.name.replace("_label", "_input")))
                if value:
                    return int(value) / 1000
    hw = _find("macsmc_hwmon")
    if hw is not None:
        for label in hw.glob("temp*_label"):
            if "(TCXC)" in _read(label, ""):
                value = _read(label.with_name(label.name.replace("_label", "_input")))
                if value:
                    return int(value) / 1000
    return None
