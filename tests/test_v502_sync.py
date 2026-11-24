"""Exercise edge cases that an otherwise clean upstream merge could break."""
import os
from pathlib import Path
import re
import subprocess
import tempfile
from unittest import TestCase, mock
from test_v476_sync import ROOT, load


class V502Integration(TestCase):
    def test_toolbox_config_survives_actual_installer_cleanup(self):
        installer = (ROOT / "install.sh").read_text()
        cleanup = re.search(r"^remove_old_parts\(\) \{.*?^\}", installer, re.M | re.S).group()
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            keep = (".config/rice/tools.json", ".config/rice/ai.json", ".local/bin/rice-tools",
                    ".cache/rice/tools-open", ".config/quickshell/rice-settings/ToolboxPage.qml",
                    ".config/quickshell/rice-desktop/Tools.qml")
            legacy = ".config/hypr/rice-hotcorner.lua"
            for name in (*keep, legacy):
                p = home / name
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text("sentinel")
            subprocess.run(["bash", "-ec", cleanup + "\nremove_old_parts"],
                           env=dict(os.environ, HOME=tmp, DRY_RUN="0"), check=True)
            self.assertFalse((home / legacy).exists())
            for p in keep:
                self.assertEqual((home / p).read_text(), "sentinel")

    def test_upstream_retires_toolbox_and_account_does_not_replace_vpn(self):
        desktop = ROOT / "quickshell/rice-desktop"
        settings = ROOT / "quickshell/rice-settings"
        self.assertFalse((ROOT / "bin/rice-tools").exists())
        self.assertFalse((desktop / "Tools.qml").exists())
        self.assertFalse((settings / "ToolboxPage.qml").exists())
        self.assertNotIn('name: "tools-open"', (desktop / "shell.qml").read_text())
        self.assertNotIn('hotkey-overlay-title="Toolbox"', (ROOT / "bin/rice-niri").read_text())
        shell = (settings / "shell.qml").read_text()
        self.assertRegex(shell, r"idx: 36;[^\n]*VpnPage")
        self.assertRegex(shell, r"idx: 37;[^\n]*WindowRulesPage")
        self.assertRegex(shell, r"idx: 38;[^\n]*AccountPage")

    def test_explicit_notification_volume_survives_upgrade(self):
        notify = load("rice-notify")
        with tempfile.TemporaryDirectory() as tmp:
            cfg = Path(tmp) / "notify.json"
            with mock.patch.object(notify, "CFG", str(cfg)):
                self.assertEqual(notify.load()["sound_volume"], 45)
                cfg.write_text('{"v": 4, "sound_volume": 70}')
                self.assertEqual(notify.load()["sound_volume"], 70)

    def test_enables_only_fixed_native_power_service_commands(self):
        desktop = (ROOT / "bin/rice-desktop").read_text()
        self.assertIn('qs kill -p "$dir"', desktop)
        self.assertIn('QV4_GC_TIMELIMIT=', desktop)
        svcs = load("rice-services")
        ok = subprocess.CompletedProcess([], 0, "", "")
        with mock.patch.object(svcs, "pp_state", side_effect=[{"running": False, "why": "masked"}, {"running": True}]), \
             mock.patch.object(svcs.os.path, "isdir", return_value=True), \
             mock.patch.object(svcs, "system_executable", side_effect=lambda n: "/usr/bin/" + n), \
             mock.patch.object(svcs.subprocess, "run", return_value=ok), \
             mock.patch.object(svcs, "run", return_value=ok) as run:
            svcs.pp_start()
        self.assertEqual([c.args for c in run.call_args_list], [
            (["/usr/bin/pkexec", "/usr/bin/systemctl", "unmask", "power-profiles-daemon.service"], 120),
            (["/usr/bin/pkexec", "/usr/bin/systemctl", "enable", "--now", "power-profiles-daemon.service"], 120),
        ])
