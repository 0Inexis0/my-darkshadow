"""Upstream integration contracts; executable mocks never open desktop programs.

The QML checks cover source composition only, not a rendered Quickshell session.
AI lifecycle behavior itself is exercised separately in test_ai.py.
"""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class FileManagerTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.bin = self.home / "bin"
        self.bin.mkdir()
        (self.home / ".config/rice").mkdir(parents=True)
        # Restrict PATH to mocks plus cat, so installed host file managers cannot run.
        (self.bin / "cat").symlink_to(shutil.which("cat"))
        self.bash = shutil.which("bash")
        self.env = dict(os.environ, HOME=str(self.home), PATH=str(self.bin))

    def mock(self, name):
        path = self.bin / name
        path.write_text("#!" + sys.executable + "\n"
                        "import json, os, pathlib, sys\n"
                        "(pathlib.Path(os.environ['HOME']) / 'called').write_text("
                        "json.dumps([pathlib.Path(sys.argv[0]).name] + sys.argv[1:]))\n")
        path.chmod(0o755)

    def run_files(self, *args):
        return subprocess.run([self.bash, str(ROOT / "bin/rice-files"), *args],
                              env=self.env, capture_output=True, text=True, timeout=5)

    def called(self):
        return json.loads((self.home / "called").read_text())

    def test_default_preserves_nautilus_and_arguments(self):
        for name in ("nautilus", "thunar", "dolphin"):
            self.mock(name)
        args = ["/tmp/a folder", "--new-window"]
        self.assertEqual(self.run_files(*args).returncode, 0)
        self.assertEqual(self.called(), ["nautilus"] + args)

    def test_explicit_choice_overrides_default(self):
        for name in ("nautilus", "thunar"):
            self.mock(name)
        (self.home / ".config/rice/files").write_text("thunar\n")
        self.assertEqual(self.run_files("/tmp/folder").returncode, 0)
        self.assertEqual(self.called(), ["thunar", "/tmp/folder"])

    def test_missing_choice_falls_back_to_nautilus(self):
        self.mock("nautilus")
        (self.home / ".config/rice/files").write_text("missing-app\n")
        self.assertEqual(self.run_files().returncode, 0)
        self.assertEqual(self.called(), ["nautilus"])

    def test_no_file_manager_reports_failure(self):
        self.mock("notify-send")
        self.assertEqual(self.run_files().returncode, 1)
        self.assertEqual(self.called()[0], "notify-send")
        self.assertIn("No file manager", self.called())


class CompositionTests(unittest.TestCase):
    def test_settings_pages_have_unique_indices_and_preserve_routes(self):
        qml = (ROOT / "quickshell/rice-settings/shell.qml").read_text()
        pages = qml.split("readonly property var pages: [", 1)[1].split("\n    ]", 1)[0]
        names = re.findall(r'\{ name: ([^,]+),', pages)
        slots = re.findall(r'PageSlot\s*\{[^\n]*?idx:\s*(\d+);[^\n]*?Component\s*\{\s*(\w+)', qml)
        indices = [int(index) for index in re.findall(r'PageSlot\s*\{[^\n]*?idx:\s*(\d+);', qml)]
        self.assertEqual(len(indices), len(set(indices)))
        # Legacy Hot corners (13) and Security (32) have no PageSlot in the fork baseline.
        self.assertEqual(sorted(indices), [i for i in range(len(names)) if i not in (13, 32)])
        self.assertEqual(names[36], '"VPN"')
        self.assertEqual(names[37], '"Window rules"')
        self.assertEqual(dict(slots)["36"], "VpnPage")
        self.assertEqual(dict(slots)["37"], "WindowRulesPage")

    def test_sidebar_and_gaming_route_to_correct_pages(self):
        qml = (ROOT / "quickshell/rice-settings/shell.qml").read_text()
        desktop = next(line for line in qml.splitlines() if 'group: "desk"' in line)
        system = next(line for line in qml.splitlines() if 'group: "sys"' in line)
        desktop_lists = re.findall(r'\[([\d, ]+)\]', desktop)
        self.assertEqual(len(desktop_lists), 2)  # Hyprland and niri
        for entries in desktop_lists:
            values = [int(value) for value in entries.split(",")]
            self.assertIn(37, values)
            self.assertNotIn(36, values)
        values = re.search(r'pages: \[([\d, ]+)\]', system).group(1)
        self.assertIn(36, [int(value) for value in values.split(",")])
        gaming = (ROOT / "quickshell/rice-settings/GamingPage.qml").read_text()
        self.assertRegex(gaming, r'onClicked:\s*page\.ctl\.page\s*=\s*37\b')

    def test_visualizer_keeps_fork_background_playback(self):
        qml = (ROOT / "quickshell/rice-desktop/shell.qml").read_text()
        block = qml.split('LazyLoader { active: root.on("visualizer")', 1)[1].split("\n    }", 1)[0]
        self.assertIn('active: root.on("visualizer")', block)
        self.assertIn('running: root.on("visualizer") && !Look.lite;', block)
        self.assertIn('free: true; passive: true', block)
        self.assertNotRegex(block, r'root\.(?:hideWidgets|busy|autoHide)\b')

    def test_ai_lifecycle_reader_and_cards_remain_wired(self):
        island = (ROOT / "quickshell/rice-desktop/DynIsland.qml").read_text()
        status = (ROOT / "quickshell/rice-desktop/AiStatus.qml").read_text()
        self.assertIn('on("island_ai") && AiStatus.active', island)
        self.assertIn('AiActivity {', island)
        self.assertIn('AiPanel {', island)
        self.assertIn('"/.local/bin/rice-ai", "watch"', status)
        self.assertIn('p.state === "waiting"', status)
        self.assertTrue((ROOT / "bin/rice-ai").is_file())


if __name__ == "__main__":
    unittest.main()
