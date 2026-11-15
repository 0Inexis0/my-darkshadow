"""V4.58 integration checks. All configuration/keyboard I/O uses disposable homes."""
import contextlib
import importlib.util
from importlib.machinery import SourceFileLoader
import io
import json
import os
import subprocess
import sys
from pathlib import Path
import re
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
loader = SourceFileLoader("sync_hypr", str(ROOT / "bin/hypr-set"))
spec = importlib.util.spec_from_loader(loader.name, loader)
hypr = importlib.util.module_from_spec(spec)
loader.exec_module(hypr)


class KeyboardRetentionTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.home = Path(tmp.name)
        for name, value in {"HOME": str(self.home), "DIR": str(self.home / "rice"),
                            "ST": str(self.home / "rice/hypr.json"),
                            "OUT": str(self.home / ".config/hypr/rice-settings.lua"), "NIRI": False}.items():
            p = patch.object(hypr, name, value)
            p.start()
            self.addCleanup(p.stop)

    def test_saved_german_layout_is_not_replaced_by_detected_layout(self):
        saved = json.loads((ROOT / "settings/rice/hypr.json").read_text())
        self.assertRegex((ROOT / "config/hypr/hyprland.lua").read_text(), r'kb_layout\s*=\s*"de"')
        saved["kbd"] = {"layouts": "de", "variants": "", "options": ""}
        Path(hypr.DIR).mkdir()
        Path(hypr.ST).write_text(json.dumps(saved))
        with patch.object(hypr, "kbd_from_files") as files, patch.object(hypr, "sh") as live:
            hypr.cmd_kbd_remember()
            files.assert_not_called()
            live.assert_not_called()
        self.assertEqual(json.loads(Path(hypr.ST).read_text()), saved)

    def test_existing_german_lua_is_remembered_before_regeneration(self):
        Path(hypr.OUT).parent.mkdir(parents=True)
        (Path(hypr.OUT).parent / "hyprland.lua").write_text(
            'hl.config({ input = { kb_layout = "de", kb_variant = "nodeadkeys", kb_options = "caps:escape" } })\n')
        with patch.object(hypr.shutil, "which", return_value=None), contextlib.redirect_stdout(io.StringIO()):
            hypr.cmd_kbd_remember()
        self.assertEqual(json.loads(Path(hypr.ST).read_text())["kbd"],
                         {"layouts": "de", "variants": "nodeadkeys", "options": "caps:escape"})
        self.assertIn('kb_layout = "de"', Path(hypr.OUT).read_text())
        installer = (ROOT / "install.sh").read_text().split('step_configs() {', 1)[1].split('\n}', 1)[0]
        self.assertLess(installer.index('kbd-remember'), installer.index('copy_tree'))

    def test_niri_settings_apply_does_not_reenter_keyboard_lock(self):
        binary = self.home / ".local/bin"
        binary.mkdir(parents=True)
        for name in ("hypr-set", "rice-niri"):
            (binary / name).symlink_to(ROOT / "bin" / name)
        (binary / "niri").write_text("#!" + sys.executable + "\nimport sys\n"
                                     "print('niri 26.04' if '--version' in sys.argv else '{}')\n")
        (binary / "niri").chmod(0o755)
        niri_config = self.home / ".config/niri/config.kdl"
        niri_config.parent.mkdir(parents=True)
        niri_config.write_text('input {\n    keyboard {\n        xkb {\n            layout "de"\n        }\n    }\n}\n')
        env = dict(os.environ, HOME=str(self.home), NIRI_SOCKET="test", PATH=str(binary) + os.pathsep + os.environ["PATH"])
        # Before the fix, rice-niri called hypr-set again under the parent's .hypr.lock
        # and the child waited for rice-niri's ten-second timeout. No real niri is used.
        result = subprocess.run([str(binary / "hypr-set"), "set", "general.gaps_in", "7"],
                                env=env, capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        saved = json.loads((self.home / ".config/rice/hypr.json").read_text())
        self.assertEqual(saved["opts"]["general.gaps_in"], 7)
        self.assertEqual(saved["kbd"]["layouts"], "de")
        self.assertIn('layout "de"', niri_config.read_text())
        self.assertTrue((self.home / ".config/niri/config.kdl").is_file())

    def test_niri_refresh_rate_keeps_millihertz(self):
        with patch.object(hypr, "NIRI", True):
            self.assertEqual(hypr.mon_rate(74.973), "74.973")
        with patch.object(hypr, "NIRI", False):
            self.assertEqual(hypr.mon_rate(74.973), "74.97")


class SharedServiceCompositionTests(unittest.TestCase):
    def test_bars_share_services_and_only_primary_consumes_script_commands(self):
        bar = (ROOT / "quickshell/rice-desktop/Bar.qml").read_text()
        island = (ROOT / "quickshell/rice-desktop/DynIsland.qml").read_text()
        shell = (ROOT / "quickshell/rice-desktop/shell.qml").read_text()
        self.assertIn('readonly property var svc: BarSvc.state', bar)
        self.assertIn('readonly property var wx: BarSvc.wx', bar)
        self.assertNotIn('id: svcProc', bar)
        self.assertNotIn('id: wxProc', bar)
        self.assertIn('name: bar.extra ? "" : "barpop-open"', bar)
        self.assertIn('path: isl.bar && isl.bar.extra ? "" :', island)
        self.assertIn('model: Mon.everywhere ? Mon.others : []', shell)
        self.assertIn('scr: modelData; nf: notifs', shell)
        self.assertIn('Player.hold()', island)
        self.assertIn('Player.release()', island)
        for file in (ROOT / 'quickshell/rice-desktop').glob('*.qml'):
            for line in file.read_text().splitlines():
                if 'Instantiator {' in line and 'Player.hold()' in line:
                    self.assertIn('active:', line, file.name)
                    self.assertIn('model: 1;', line, file.name)
        self.assertNotRegex(island, r'\bpl\.|\bPlayer\s*\{')
        self.assertIn('hoverOpen && hoverAi && !pinned && !ghost ? "ai"', island)
        self.assertIn('isl.aiActive || Player.has', island)

    def test_lock_view_uses_upstream_local_player_not_desktop_singleton(self):
        view = (ROOT / "quickshell/rice-lockscreen/LockView.qml").read_text()
        self.assertIn('LockPlayer { id: pl;', view)
        self.assertFalse((ROOT / "quickshell/rice-lockscreen/Player.qml").exists())
        player = (ROOT / "quickshell/rice-lockscreen/LockPlayer.qml").read_text()
        self.assertNotIn('pragma Singleton', player)
        self.assertIn('property bool running: true', player)
        self.assertIn('running: pl.running && pl.playing', player)

    def test_standalone_update_never_resets_or_stashes_local_history(self):
        preflight = (ROOT / "install.sh").read_text().split('\nif [ "$MODE" = update ]; then', 1)[1]
        preflight = preflight.split('# the version you have, as the repo had it', 1)[0]
        self.assertIn('merge --ff-only "$GUARD_CHECKED"', preflight)
        self.assertNotRegex(preflight, r'\b(reset|stash)\b')
        self.assertIn('update_precheck https://github.com/0Inexis0/my-darkshadow.git', preflight)


if __name__ == '__main__':
    unittest.main()
