"""Clipboard regression checks use synthetic data and never read the user's clipboard."""
from importlib.machinery import SourceFileLoader
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
loader = SourceFileLoader("rice_clip", str(ROOT / "bin/rice-clip"))
spec = importlib.util.spec_from_loader(loader.name, loader)
clip = importlib.util.module_from_spec(spec)
loader.exec_module(clip)


class ClipboardTests(unittest.TestCase):
    def test_decode_accepts_text_identifier_and_returns_exact_binary(self):
        command = [sys.executable, "-c", "import sys;sys.stdout.buffer.write(sys.stdin.buffer.read())"]
        code, output = clip.run(command, inp="12\tsynthetic entry\n", text=False)
        self.assertEqual((code, output), (0, b"12\tsynthetic entry\n"))

    def test_copy_preserves_unicode_newlines_and_image_bytes(self):
        for payload in ["Grüße\nsecond line\n".encode(), b"\x89PNG\r\n\x1a\n\x00\xff\x80"]:
            with self.subTest(payload_type="image" if payload.startswith(b"\x89PNG") else "text"), \
                 patch.object(clip, "entry_line", return_value="12\tsynthetic"), \
                 patch.object(clip, "cliphist", return_value=(0, payload)) as history, \
                 patch.object(clip, "run", return_value=(0, b"")) as execute, \
                 patch.object(clip, "paste_later") as paste:
                clip.cmd_copy("12")
                history.assert_called_once_with("decode", inp="12\tsynthetic\n", text=False)
                execute.assert_called_once_with(["wl-copy"], inp=payload, text=False, capture=False)
                paste.assert_called_once_with()

    def test_clipboard_write_failure_does_not_paste_stale_content(self):
        with patch.object(clip, "entry_line", return_value="12\tsynthetic"), \
             patch.object(clip, "cliphist", return_value=(0, b"new value")), \
             patch.object(clip, "run", return_value=(1, b"")), \
             patch.object(clip, "paste_later") as paste:
            with self.assertRaises(SystemExit):
                clip.cmd_copy("12")
            paste.assert_not_called()

    def test_background_clipboard_owner_does_not_hold_the_command_open(self):
        daemon = "import os,sys,time;sys.stdin.buffer.read();pid=os.fork();time.sleep(.6) if pid==0 else None;os._exit(0)"
        code, output = clip.run([sys.executable, "-c", daemon], inp=b"synthetic", text=False,
                                capture=False, timeout=.25)
        self.assertEqual((code, output), (0, b""))

    def test_open_recovers_missing_shell_and_close_never_starts_it(self):
        with tempfile.TemporaryDirectory() as directory, \
             patch.object(clip, "CACHE", directory), patch.object(clip, "cmd_watch"), \
             patch.object(clip, "run", return_value=(1, "stopped\n")), \
             patch.object(clip.subprocess, "Popen") as launch:
            clip.cmd_open("open")
            self.assertEqual(launch.call_args.args[0], [clip.HOME + "/.local/bin/rice-desktop", "ensure"])
            self.assertTrue((Path(directory) / "clip-open").read_text().endswith(" open\n"))
            launch.reset_mock()
            clip.cmd_open("close")
            launch.assert_not_called()

    def test_recovered_instance_does_not_start_a_duplicate(self):
        with tempfile.TemporaryDirectory() as directory, \
             patch.object(clip, "CACHE", directory), patch.object(clip, "cmd_watch"), \
             patch.object(clip, "run", return_value=(0, "running\n")), \
             patch.object(clip.subprocess, "Popen") as launch:
            clip.cmd_open("toggle")
            launch.assert_not_called()


if __name__ == "__main__":
    unittest.main()
