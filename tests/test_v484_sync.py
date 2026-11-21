"""Contract checks for V4.84 integration; no compositor is started."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

from test_v476_sync import ROOT, load


class V484Integration(unittest.TestCase):
    def test_logo_setting_and_fork_layout_keys_coexist(self):
        bar = load("rice-bar")
        self.assertIn("logo_move", bar.BOOLS)
        self.assertIs(bar.DEFAULTS["logo_move"], False)
        self.assertIn("island_ai", bar.BOOLS)
        self.assertIs(bar.DEFAULTS["island_ai"], True)
        self.assertIs(bar.DEFAULTS["island_date"], False)
        self.assertIn("date", bar.MODULES)

    def test_island_keeps_ai_routing_and_shared_volume_curve(self):
        island = (ROOT / "quickshell/rice-desktop/DynIsland.qml").read_text()
        self.assertRegex(island, r'onClicked:.*isl\.aiActive \? "ai"')
        self.assertIn("Vol.nudge(isl.bar.sink", island)
        self.assertIn("Vol.set(isl.bar.sink", island)
        volume = (ROOT / "bin/rice-volume").read_text()
        self.assertIn("rice-desktop\" status", volume)
        self.assertIn("rice-sound\" step", volume)

    def test_ai_activity_wave_keeps_api_and_throttles_phase(self):
        desktop = ROOT / "quickshell/rice-desktop"
        wave = (desktop / "WavyLine.qml").read_text()
        self.assertIn("property bool activity", wave)
        self.assertIn("onActivityChanged: cv.requestPaint()", wave)
        self.assertIn("wl.activity ? 1", wave)
        self.assertIn("interval: 33", wave)
        self.assertIn("!Look.lite", wave)
        self.assertIn("activity: live.busy && !live.waiting",
                      (desktop / "AiActivity.qml").read_text())

    def test_niri_monitor_actions_keep_keyboard_reentrancy_guard(self):
        hypr = (ROOT / "bin/hypr-set").read_text()
        niri = (ROOT / "bin/rice-niri").read_text()
        self.assertIn("cmd_kbd_remember(apply_niri=False)", hypr)
        self.assertIn("--skip-keyboard-remember", hypr)
        self.assertIn('remember_keyboard="--skip-keyboard-remember" not in a', niri)
        self.assertIn("focus-column-or-monitor-left;", niri)
        self.assertIn("move-column-right-or-to-monitor-right;", niri)

    def test_settings_is_lazy_by_default_and_keep_is_opt_in(self):
        script = ROOT / "bin/rice-settings"
        with tempfile.TemporaryDirectory() as home:
            env = dict(os.environ, HOME=home)
            def lazy(*args):
                return subprocess.check_output([str(script), "lazy", *args], env=env, text=True).strip()
            self.assertEqual(lazy("state"), "on")
            lazy("off")
            self.assertTrue((Path(home) / ".config/rice/settings-keep").is_file())
            self.assertEqual(lazy("state"), "off")
            lazy("on")
            self.assertEqual(lazy("state"), "on")
