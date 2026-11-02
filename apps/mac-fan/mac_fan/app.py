import signal

import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Adw, Gio, GLib, Gtk  # noqa: E402

from . import config, smc  # noqa: E402

APP_ID = "local.guibs.MacFan"
MODES = [("auto", "Automatic (SMC)"), ("fixed", "Fixed speed"), ("curve", "Temperature curve")]
TICK_SECONDS = 2
SAFETY_TEMP = 90      # °C: above this, manual modes go to full speed
STEP_DOWN = 150       # RPM a curve may slow down per tick, so the fan doesn't hunt
MIN_CHANGE = 50       # RPM: ignore smaller adjustments


class App(Adw.Application):
    def __init__(self, start_hidden):
        super().__init__(application_id=APP_ID)
        self.start_hidden = start_hidden
        self.win = None
        self.cfg = config.load()
        self.fans = smc.fans()
        self.written = {}       # fan index -> last value written (0 = auto)
        self.error = None
        self.notified_background = False

    def do_startup(self):
        Adw.Application.do_startup(self)
        quit_action = Gio.SimpleAction.new("quit", None)
        quit_action.connect("activate", lambda *_: self._quit())
        self.add_action(quit_action)
        self.set_accels_for_action("app.quit", ["<Ctrl>q"])
        for sig in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
            GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, sig, self._quit)
        self.hold()  # keep running with no window; released in _quit
        self._tick()
        GLib.timeout_add_seconds(TICK_SECONDS, self._tick)

    def do_activate(self):
        if self.win is None:
            self._build_window()
            self._refresh()
            if self.start_hidden:
                return
        self.win.present()

    # --- Fan control ---

    def _desired(self, fan, temp):
        mode = self.cfg["mode"]
        if mode == "auto":
            return 0
        if temp is not None and temp >= SAFETY_TEMP:
            return fan.max
        if mode == "fixed":
            return max(fan.min, min(fan.max, self.cfg["rpm"]))
        # curve
        if temp is None:
            return 0
        low, high = self.cfg["curve_low"], self.cfg["curve_high"]
        ratio = 1.0 if high <= low else (temp - low) / (high - low)
        want = fan.min + (fan.max - fan.min) * max(0.0, min(1.0, ratio))
        last = self.written.get(fan.index) or fan.min
        return int(max(want, last - STEP_DOWN))

    def _apply(self):
        temp = smc.cpu_temp()
        self.error = None
        for fan in self.fans:
            want = self._desired(fan, temp)
            last = self.written.get(fan.index)
            if last is not None and (want == last or (want and last and abs(want - last) < MIN_CHANGE)):
                continue
            if want == 0 and last is None and not fan.writable():
                continue  # nothing to undo, and the banner already explains why we can't
            try:
                fan.set(want)
                self.written[fan.index] = want
            except smc.SmcError as err:
                self.error = str(err)

    def _tick(self):
        self._apply()
        self._refresh()
        return GLib.SOURCE_CONTINUE

    def _restore_auto(self):
        for fan in self.fans:
            if self.written.get(fan.index):
                try:
                    fan.set(0)
                except smc.SmcError:
                    pass

    def _quit(self, *_):
        self._restore_auto()
        self.quit()
        return GLib.SOURCE_REMOVE

    # --- Window ---

    def _build_window(self):
        self.win = Adw.ApplicationWindow(application=self, title="Mac Fan", default_width=520, default_height=640)
        self.win.connect("close-request", self._on_close)

        toolbar = Adw.ToolbarView()
        header = Adw.HeaderBar()
        menu = Gio.Menu()
        menu.append("Quit", "app.quit")
        header.pack_end(Gtk.MenuButton(icon_name="open-menu-symbolic", menu_model=menu))
        toolbar.add_top_bar(header)

        self.banner = Adw.Banner()
        toolbar.add_top_bar(self.banner)

        self.toasts = Adw.ToastOverlay()
        page = Adw.PreferencesPage()
        self.toasts.set_child(page)
        toolbar.set_content(self.toasts)
        self.win.set_content(toolbar)

        # Live readings
        status = Adw.PreferencesGroup(title="Now")
        page.add(status)
        self.temp_row = Adw.ActionRow(title="CPU temperature")
        self.temp_label = Gtk.Label(css_classes=["title-3", "numeric"])
        self.temp_row.add_suffix(self.temp_label)
        status.add(self.temp_row)
        self.fan_rows = []
        for fan in self.fans:
            row = Adw.ActionRow(title=fan.label)
            label = Gtk.Label(css_classes=["title-3", "numeric"])
            bar = Gtk.LevelBar(min_value=0, max_value=fan.max or 1, valign=Gtk.Align.CENTER, width_request=120)
            row.add_suffix(bar)
            row.add_suffix(label)
            status.add(row)
            self.fan_rows.append((fan, row, label, bar))
        if not self.fans:
            status.add(Adw.ActionRow(title="No SMC fan found", subtitle="The macsmc_hwmon driver isn't loaded."))

        # Control
        control = Adw.PreferencesGroup(title="Control")
        page.add(control)
        self.mode_row = Adw.ComboRow(title="Mode", model=Gtk.StringList.new([label for _, label in MODES]))
        self.mode_row.set_selected([key for key, _ in MODES].index(self.cfg["mode"]))
        self.mode_row.connect("notify::selected", self._on_mode)
        control.add(self.mode_row)

        lo = min((f.min for f in self.fans), default=1000)
        hi = max((f.max for f in self.fans), default=6000)
        self.rpm_row = Adw.SpinRow(title="Speed", subtitle="RPM",
                                   adjustment=Gtk.Adjustment(lower=lo, upper=hi, step_increment=100, page_increment=500,
                                                             value=max(lo, min(hi, self.cfg["rpm"]))))
        self.rpm_row.connect("notify::value", lambda row, _: self._set("rpm", int(row.get_value())))
        control.add(self.rpm_row)

        self.low_row = Adw.SpinRow(title="Start speeding up at", subtitle="°C — minimum speed below this",
                                   adjustment=Gtk.Adjustment(lower=30, upper=95, step_increment=1, value=self.cfg["curve_low"]))
        self.low_row.connect("notify::value", lambda row, _: self._set("curve_low", int(row.get_value())))
        control.add(self.low_row)
        self.high_row = Adw.SpinRow(title="Full speed at", subtitle="°C",
                                    adjustment=Gtk.Adjustment(lower=35, upper=100, step_increment=1, value=self.cfg["curve_high"]))
        self.high_row.connect("notify::value", lambda row, _: self._set("curve_high", int(row.get_value())))
        control.add(self.high_row)

        control.set_description(f"Fixed speed and curve go to full speed above {SAFETY_TEMP} °C. "
                                "Quitting hands the fan back to the SMC.")

        # App
        app_group = Adw.PreferencesGroup(title="App")
        page.add(app_group)
        background = Adw.SwitchRow(title="Keep running when the window is closed",
                                   subtitle="Needed for fixed speed and curve to stay active",
                                   active=self.cfg["background"])
        background.connect("notify::active", lambda row, _: self._set("background", row.get_active()))
        app_group.add(background)
        autostart = Adw.SwitchRow(title="Start at login", active=config.autostart_enabled())
        autostart.connect("notify::active", lambda row, _: config.set_autostart(row.get_active()))
        app_group.add(autostart)

        self._update_mode_rows()

    def _set(self, key, value):
        if self.cfg.get(key) == value:
            return
        self.cfg[key] = value
        config.save(self.cfg)
        self._tick()

    def _on_mode(self, row, _):
        self._set("mode", MODES[row.get_selected()][0])
        self._update_mode_rows()

    def _update_mode_rows(self):
        mode = self.cfg["mode"]
        self.rpm_row.set_visible(mode == "fixed")
        self.low_row.set_visible(mode == "curve")
        self.high_row.set_visible(mode == "curve")

    def _refresh(self):
        if self.win is None:
            return
        temp = smc.cpu_temp()
        self.temp_label.set_label("—" if temp is None else f"{temp:.0f} °C")
        for fan, row, label, bar in self.fan_rows:
            rpm = fan.rpm()
            label.set_label(f"{rpm} RPM")
            bar.set_value(min(rpm, bar.get_max_value()))
            target = self.written.get(fan.index)
            row.set_subtitle("Automatic (SMC)" if not target else f"Target {target} RPM")

        problem = None
        if self.fans and not smc.fan_control_enabled():
            problem = "Fan control is off in the SMC driver — run ./toolbox mac-fan install"
        elif self.fans and not all(f.writable() for f in self.fans):
            problem = "No permission to set the fan speed — run ./toolbox mac-fan install"
        elif self.error:
            problem = self.error
        self.banner.set_title(problem or "")
        self.banner.set_revealed(problem is not None)

    def _on_close(self, _win):
        if self.cfg["background"] and self.cfg["mode"] != "auto":
            self.win.set_visible(False)
            if not self.notified_background:
                self.notified_background = True
                note = Gio.Notification.new("Mac Fan is still running")
                note.set_body("It keeps controlling the fan. Quit it from the menu to hand control back to the SMC.")
                self.send_notification("background", note)
            return True
        self._quit()
        return False


def main(argv):
    app = App(start_hidden="--background" in argv)
    return app.run([arg for arg in argv if arg != "--background"])
