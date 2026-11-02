# Mac Fan

A small GNOME app that controls the fan of a T2 Mac (tested on a Mac mini 2018, `Macmini8,1`) running
Debian with a T2 Linux kernel. It talks to the Apple SMC through the `macsmc_hwmon` driver.

## Install

```bash
./install.sh                     # or: ./toolbox mac-fan install
```

Run it as your normal user (it asks for `sudo` when needed). It:

- enables the driver's `fan_control` option, now and at boot (`/etc/modprobe.d/mac-fan.conf`).
  The kernel marks this option "unsafe", so setting it taints the kernel. That's expected.
- adds a udev rule that makes `fan*_target` writable by your user (`/etc/udev/rules.d/70-mac-fan.rules`).
- adds "Mac Fan" to the app menu.

It uses the system `python3` (PyGObject/GTK come from apt), not the shared `.venv`.

Launch it from the app menu, or with `./toolbox mac-fan` (`--background` starts it hidden).

## Use

- **Automatic (SMC)** — the Mac decides, like on macOS. This is the default.
- **Fixed speed** — holds the fan at the RPM you pick (between the fan's min and max).
- **Temperature curve** — minimum speed below the "start" temperature, full speed at the "full" temperature,
  linear in between, based on the CPU package temperature. It speeds up right away and slows down gradually.

Safety: in fixed speed and curve modes, the fan goes to full speed if the CPU reaches 90 °C.
When you quit the app (menu, Ctrl+Q, logout), it hands the fan back to the SMC.

Fixed speed and curve only work while the app is running. Closing the window keeps it running in the
background (you can turn that off); turn on **Start at login** to have it apply your mode after every boot.
Settings live in `~/.config/mac-fan/config.json`.

## How it works

Writing an RPM between `fan1_min` and `fan1_max` to `/sys/class/hwmon/hwmonN/fan1_target`
(the `hwmon` named `macsmc_hwmon`) puts the fan in manual mode; writing `0` returns it to automatic.

## Uninstall

```bash
sudo rm /etc/modprobe.d/mac-fan.conf /etc/udev/rules.d/70-mac-fan.rules
rm ~/.local/share/applications/local.guibs.MacFan.desktop \
   ~/.local/share/icons/hicolor/scalable/apps/local.guibs.MacFan.svg \
   ~/.config/autostart/mac-fan.desktop
```
