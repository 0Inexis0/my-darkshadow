"""Account UI uses explicit authorization and never elevates the fork's Python."""
import contextlib
import io
import json
import os
from pathlib import Path
import tarfile
import tempfile
from types import SimpleNamespace
from unittest import TestCase, mock

from test_v476_sync import load


class AccountBoundary(TestCase):
    def setUp(self):
        self.account = load("rice-account")

    def invoke(self, fn, *args):
        output = io.StringIO()
        with contextlib.redirect_stdout(output), self.assertRaises(SystemExit):
            fn(*args)
        return json.loads(output.getvalue())

    def test_trusted_binary_refuses_user_owned_file_and_alias(self):
        system = SimpleNamespace(st_uid=0, st_mode=0o100755)
        owned = SimpleNamespace(st_uid=1000, st_mode=0o100755)
        a = self.account
        with mock.patch.object(a, "SYSTEM_DIRS", ("/bin",)), \
             mock.patch.object(a.os, "stat", side_effect=lambda p: owned if p == "/tmp/x" else system), \
             mock.patch.object(a.os.path, "realpath", return_value="/tmp/x"), \
             mock.patch.object(a.os, "access", return_value=True):
            self.assertIsNone(a.trusted_binary("useradd"))

    def test_password_never_in_args_or_error(self):
        a = self.account
        prefix = lambda name: "/usr/bin/" + name
        with mock.patch.object(a.os, "getuid", return_value=1000), mock.patch.object(a.sys.stdin, "isatty", return_value=False), \
             mock.patch.object(a, "trusted_binary", side_effect=prefix), \
             mock.patch.object(a.subprocess, "run", return_value=SimpleNamespace(returncode=1, stderr="FAKESECRET")) as run:
            self.assertEqual(a.privileged("chpasswd", [], "demo:FAKESECRET\n"), "other")
            self.assertEqual(run.call_args.args[0], ["/usr/bin/pkexec", "/usr/bin/chpasswd"])
            self.assertEqual(run.call_args.kwargs["input"], "demo:FAKESECRET\n")
            self.assertTrue(run.call_args.kwargs["capture_output"])
            with self.assertRaises(ValueError):
                a.privileged("sh", [])

    def test_add_stays_locked_and_does_not_promote_on_password_failure(self):
        a = self.account
        with mock.patch.object(a.pwd, "getpwnam", side_effect=KeyError), \
             mock.patch.object(a, "admin_group", return_value="wheel"), \
             mock.patch.object(a, "privileged", side_effect=["", "cancelled"]) as launch:
            result = self.invoke(a.account_add, {"user": "demo", "password": "fake", "admin": True})
            self.assertFalse(result["ok"])
            self.assertIn("created", result["detail"])
            self.assertEqual([c.args[0] for c in launch.call_args_list], ["useradd", "chpasswd"])

    def test_appearance_archive_is_data_only_and_does_not_follow_symlinks(self):
        a = self.account
        with tempfile.TemporaryDirectory() as tmp:
            config = Path(tmp) / ".config" / "rice"
            config.mkdir(parents=True)
            (config / "bar.json").write_text(json.dumps({"password": "secret", "layout": {
                "left": ["date", "date", {"cmd": "secret"}], "center": ["island"]}, "style": "dynamic"}))
            secret = config / "ai.json"
            secret.write_text("secret")
            (config / "color-mode").symlink_to(secret)
            with tarfile.open(fileobj=io.BytesIO(a.appearance_archive(tmp))) as tar:
                self.assertEqual(tar.getnames(), [".config/rice/bar.json"])
                data = json.load(tar.extractfile(tar.getnames()[0]))
                self.assertEqual(data["layout"]["left"], ["date"])
                self.assertNotIn("password", data)

    def test_appearance_tar_runs_as_new_human_user_only(self):
        a = self.account
        target = SimpleNamespace(pw_uid=1001, pw_shell="/bin/sh", pw_name="demo", pw_dir="/home/demo")
        with mock.patch.object(a, "trusted_binary", return_value="/usr/bin/tar"), \
             mock.patch.object(a.pwd, "getpwnam", return_value=target), \
             mock.patch.object(a.os, "getuid", return_value=1000), \
             mock.patch.object(a.os, "lstat", return_value=SimpleNamespace(st_uid=1001, st_mode=0o40700)), \
             mock.patch.object(a, "privileged", return_value="") as launch:
            self.assertEqual(a.copy_appearance("demo", b"archive"), "")
            self.assertEqual(launch.call_args.args[:1], ("runuser",))
            self.assertEqual(launch.call_args.args[1][:4], ["-u", "demo", "--", "/usr/bin/tar"])
            self.assertEqual(launch.call_args.args[2], b"archive")
            target.pw_uid = 0
            self.assertEqual(a.copy_appearance("demo", b"archive"), "unsupported")
            launch.assert_called_once()

    def test_remove_requires_explicit_mode(self):
        a = self.account
        with mock.patch.object(a, "privileged") as launch:
            with mock.patch.object(a.sys, "argv", ["rice-account", "remove", "demo"]):
                self.assertEqual(self.invoke(a.main)["error"], "invalid command")
            launch.assert_not_called()
