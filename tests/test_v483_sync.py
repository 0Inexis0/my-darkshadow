"""V4.83 fork integration. Tests use stubs, not a live compositor."""
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from test_v476_sync import ROOT, load


class UpstreamIntegration(unittest.TestCase):
    def test_edge_frame_and_fork_defaults_coexist(self):
        bar = load("rice-bar")
        self.assertIn("edge", bar.CHOICES["style"])
        self.assertIn("edge_frame", bar.BOOLS)
        self.assertIs(bar.DEFAULTS["edge_frame"], True)
        self.assertIs(bar.DEFAULTS["island_date"], False)
        self.assertIs(bar.DEFAULTS["island_ai"], True)
        self.assertIn("ai", bar.CHOICES["island_tab"])

    def test_settings_preserves_existing_route_indices(self):
        shell = (ROOT / "quickshell/rice-settings/shell.qml").read_text()
        for route, component in [(36, "VpnPage"), (37, "WindowRulesPage"), (38, "ToolboxPage")]:
            self.assertRegex(shell, rf"idx: {route};[^\n]*\b{component}\b")
            self.assertEqual(shell.count(f"idx: {route};"), 1)
        self.assertIn("pages: niri ? [29, 38, 12, 25, 37", shell)
        self.assertIn("pages: [30, 31, 28, 5, 23, 15, 36]", shell)

    def test_niri_focused_monitor_uses_logical_offset(self):
        shot = load("rice-hotcorner")
        data = '{"name":"DP-2","logical":{"scale":1.6,"x":-1920,"y":40}}'
        with patch.dict(os.environ, {"NIRI_SOCKET": "/mock"}), patch.object(shot, "q", return_value=(0, data)):
            self.assertEqual(shot.focused_output(), ("DP-2", 1.6, -1920, 40))

    def test_record_dispatch_uses_offsets_and_never_freezes_output(self):
        shot = load("rice-hotcorner")
        with tempfile.TemporaryDirectory() as tmp:
            cache = Path(tmp)
            with patch.dict(os.environ, {"XDG_RUNTIME_DIR": tmp}), patch.object(shot, "CACHE", tmp), \
                 patch.object(shot, "focused_output", return_value=("DP-2", 1.6, -1920, 40)), \
                 patch.object(shot, "q") as run, \
                 patch.object(shot.time, "sleep", side_effect=lambda _: (cache / "snip-ack").touch()):
                self.assertTrue(shot.snip("region", "rec"))
            run.assert_not_called()
            self.assertEqual((cache / "snip-open").read_text().split()[1:],
                             ["-", "DP-2", "1.6", "region", "rec", "-1920", "40"])

    def test_initial_snip_mode_retains_niri_window_fallback(self):
        shell = (ROOT / "quickshell/rice-desktop/Snip.qml").read_text()
        self.assertLess(shell.index('if (sn.mode === "window" && !Wm.hypr)'),
                        shell.index('if (sn.rec) recCfg.running = true'))
