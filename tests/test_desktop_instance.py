"""Regression checks for menu routing after Quickshell crash recovery.

Run with: python3 -m unittest discover -s tests
All shell commands use an isolated HOME and mock Quickshell; no live shell is killed.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class DesktopInstanceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        self.calls = self.home / "calls"
        self.state = self.home / "instances.json"
        self.state.write_text(json.dumps([{"id": "recovered", "pid": 123}]))
        self.env = dict(os.environ, HOME=str(self.home),
                        PATH=str(self.bin) + os.pathsep + os.environ["PATH"])
        self.env.pop("QV4_GC_TIMELIMIT", None)
        for name in ("rice-desktop", "rice-wifi"):
            shutil.copy2(ROOT / "bin" / name, self.bin / name)
        self.script("qs", """
import json, os, pathlib, sys
h = pathlib.Path(os.environ['HOME'])
with (h / 'calls').open('a') as f:
    f.write(json.dumps(sys.argv[1:]) + '\\n')
if sys.argv[1] == 'list':
    print((h / 'instances.json').read_text())
    sys.exit(int(os.environ.get('QS_LIST_EXIT', '0')))
if sys.argv[1] == 'kill':
    (h / 'instances.json').write_text('[]')
""")
        self.script("setsid", """
import json, os, pathlib, sys
(pathlib.Path(os.environ['HOME']) / 'started.json').write_text(
    json.dumps({'args': sys.argv[1:], 'gc': os.environ.get('QV4_GC_TIMELIMIT')}))
""")
        self.script("pkill", "import sys; sys.exit(0)")
        self.script("wifi-menu", "import os, pathlib; (pathlib.Path(os.environ['HOME']) / 'fallback').touch()")

    def script(self, name, body):
        p = self.bin / name
        p.write_text("#!" + sys.executable + "\n" + body)
        p.chmod(0o755)

    def run_script(self, name, *args):
        return subprocess.run([str(self.bin / name), *args], env=self.env,
                              text=True, capture_output=True, timeout=10)

    def test_recovered_instance_is_running_without_process_matching(self):
        result = self.run_script("rice-desktop", "status")
        self.assertEqual((result.returncode, result.stdout), (0, "running\n"))
        call = json.loads(self.calls.read_text().splitlines()[0])
        self.assertEqual(call, ["list", "-p", str(self.home / ".config/quickshell/rice-desktop"), "-j"])

    def test_absent_or_invalid_registry_is_stopped(self):
        for state in ("[]", "not JSON", "{}"):
            with self.subTest(state=state):
                self.state.write_text(state)
                result = self.run_script("rice-desktop", "status")
                self.assertEqual((result.returncode, result.stdout), (1, "stopped\n"))

    def test_wifi_routes_to_custom_menu_and_keeps_coordinates(self):
        self.assertEqual(self.run_script("rice-wifi", "420", "85").returncode, 0)
        request = (self.home / ".cache/rice/wifi-open").read_text().split()
        self.assertGreater(float(request[0]), 0)
        self.assertEqual(request[1:], ["420", "85"])
        self.assertFalse((self.home / "fallback").exists())

    def test_failed_instance_query_is_stopped(self):
        self.env["QS_LIST_EXIT"] = "1"
        result = self.run_script("rice-desktop", "status")
        self.assertEqual((result.returncode, result.stdout), (1, "stopped\n"))

    def test_wifi_keeps_terminal_fallback_when_desktop_is_absent(self):
        self.state.write_text("[]")
        self.assertEqual(self.run_script("rice-wifi").returncode, 0)
        self.assertTrue((self.home / "fallback").exists())

    def test_stop_targets_only_desktop_config(self):
        self.assertEqual(self.run_script("rice-desktop", "stop").returncode, 0)
        calls = [json.loads(line) for line in self.calls.read_text().splitlines()]
        self.assertEqual(calls[-1], ["kill", "-p", str(self.home / ".config/quickshell/rice-desktop")])

    def test_restart_sets_gc_workaround_and_honors_override(self):
        for override in (None, "5"):
            with self.subTest(override=override):
                self.state.write_text('[{"id":"recovered"}]')
                if override is not None:
                    self.env["QV4_GC_TIMELIMIT"] = override
                result = self.run_script("rice-desktop", "restart")
                self.assertEqual(result.returncode, 0, result.stderr)
                started = json.loads((self.home / "started.json").read_text())
                self.assertEqual(started["gc"], override or "0")
                self.assertEqual(started["args"], ["-f", "qs", "-n", "-p", str(self.home / ".config/quickshell/rice-desktop")])


if __name__ == "__main__":
    unittest.main()
