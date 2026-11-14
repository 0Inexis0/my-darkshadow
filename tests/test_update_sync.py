"""Fork/upstream updater integration, using local disposable repositories only."""
import contextlib
import importlib.util
from importlib.machinery import SourceFileLoader
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
loader = SourceFileLoader("sync_updater", str(ROOT / "bin/rice-update"))
spec = importlib.util.spec_from_loader(loader.name, loader)
updater = importlib.util.module_from_spec(spec)
loader.exec_module(updater)


class CheckoutTests(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.home = Path(temporary.name) / "home"
        self.home.mkdir()
        self.source = Path(temporary.name) / "source"
        self.source.mkdir()
        self.git(self.source, "init", "-b", "main")
        self.commit("first")
        for name, value in [("HOME", str(self.home)), ("NEW_URL", str(self.source))]:
            p = patch.object(updater, name, value)
            p.start()
            self.addCleanup(p.stop)

    def git(self, repo, *args):
        return subprocess.run(["git", "-C", str(repo), *args], check=True,
                              capture_output=True, text=True).stdout.strip()

    def commit(self, content):
        (self.source / "file").write_text(content)
        self.git(self.source, "add", "file")
        self.git(self.source, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                 "commit", "-m", content)
        return self.git(self.source, "rev-parse", "HEAD")

    def test_checkout_clones_main_and_fast_forwards_without_losing_history(self):
        checkout = updater.managed_checkout()
        old = self.git(checkout, "rev-parse", "HEAD")
        new = self.commit("second")
        self.assertEqual(updater.managed_checkout(), checkout)
        self.assertEqual(self.git(checkout, "rev-parse", "HEAD"), new)
        self.git(checkout, "merge-base", "--is-ancestor", old, new)
        self.assertEqual(self.git(checkout, "branch", "--show-current"), "main")

    def test_divergence_is_refused_without_resetting_local_commit(self):
        checkout = Path(updater.managed_checkout())
        (checkout / "local").write_text("keep me")
        self.git(checkout, "add", "local")
        self.git(checkout, "-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                 "commit", "-m", "local feature")
        local = self.git(checkout, "rev-parse", "HEAD")
        self.commit("upstream change")
        with self.assertRaises(RuntimeError):
            updater.managed_checkout()
        self.assertEqual(self.git(checkout, "rev-parse", "HEAD"), local)
        self.assertEqual((checkout / "local").read_text(), "keep me")

    def test_non_main_branch_is_left_untouched(self):
        checkout = updater.managed_checkout()
        self.git(checkout, "switch", "-c", "local-work")
        self.commit("next")
        before = self.git(checkout, "rev-parse", "HEAD")
        with self.assertRaisesRegex(RuntimeError, "must be on main"):
            updater.managed_checkout()
        self.assertEqual(self.git(checkout, "rev-parse", "HEAD"), before)

    def test_status_failure_refuses_update(self):
        updater.managed_checkout()
        failure = subprocess.CompletedProcess([], 128, "", "cannot inspect worktree")
        with patch.object(updater, "git", return_value=failure) as git:
            with self.assertRaisesRegex(RuntimeError, "cannot inspect worktree"):
                updater.managed_checkout()
            git.assert_called_once()

    def precheck(self, checkout, script):
        return subprocess.run(["bash", "-c", 'set -eu; ROOT="$1"; source "$2"; warn() { :; }; fail() { :; }; ' + script,
                               "test", str(checkout), str(ROOT / "install/lib/secure.sh"), str(self.source)],
                              stdin=subprocess.DEVNULL, capture_output=True, text=True)

    def test_standalone_precheck_uses_explicit_source_and_merges_only_reviewed_sha(self):
        checkout = updater.managed_checkout()
        self.git(checkout, "remote", "set-url", "origin", "/nonexistent/remote")
        expected = self.commit("reviewed fork version")
        result = self.precheck(checkout, 'update_precheck "$3"; printf invalid >"$ROOT/.git/FETCH_HEAD"; '
                               'git -C "$ROOT" merge --ff-only "$GUARD_CHECKED"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.git(checkout, "rev-parse", "HEAD"), expected)

    def test_standalone_library_change_requires_consent_before_checkout_moves(self):
        checkout = updater.managed_checkout()
        before = self.git(checkout, "rev-parse", "HEAD")
        library = self.source / "install/lib/helper.sh"
        library.parent.mkdir(parents=True)
        library.write_text("echo new installer logic\n")
        self.git(self.source, "add", "install")
        self.commit("new helper")
        result = self.precheck(checkout, 'RICE_TRUST_UPDATE=0 RICE_GUI=1 update_precheck "$3"')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.git(checkout, "rev-parse", "HEAD"), before)
        self.assertFalse((Path(checkout) / "install").exists())

    def test_standalone_failed_fetch_never_approves_cached_commit(self):
        checkout = updater.managed_checkout()
        result = self.precheck(checkout, 'update_precheck /nonexistent/remote')
        self.assertNotEqual(result.returncode, 0)


class RoutingAndPrivacyTests(unittest.TestCase):
    def test_production_urls_remain_fork_main(self):
        self.assertEqual(updater.NEW_URL, "https://github.com/0Inexis0/my-darkshadow.git")
        self.assertEqual(updater.RAW, "https://raw.githubusercontent.com/0Inexis0/my-darkshadow/main/VERSION")

    def test_disabled_watcher_never_checks_or_sleeps(self):
        with patch.object(updater, "cfg", return_value={"watch": False}), \
             patch.object(updater, "check") as check, patch.object(updater.time, "sleep") as sleep:
            updater.watch()
            check.assert_not_called()
            sleep.assert_not_called()

    def test_watcher_can_be_disabled_on_managed_installation(self):
        with tempfile.TemporaryDirectory() as directory:
            config = str(Path(directory) / "update.json")
            with patch.object(updater, "managed", return_value=True), \
                 patch.object(updater, "DIR", directory), patch.object(updater, "UPDATE_CFG", config), \
                 patch.object(updater, "managed_run") as run, contextlib.redirect_stdout(io.StringIO()):
                updater.main(["rice-update", "watch", "off"])
                self.assertFalse(json.loads(Path(config).read_text())["watch"])
                run.assert_not_called()

    def test_standalone_run_keeps_guarded_installer_update_entrypoint(self):
        with patch.object(updater, "repo", return_value="/temporary/repo"), \
             patch.object(updater.os, "chdir"), patch.object(updater.subprocess, "call", return_value=0) as run, \
             patch("builtins.input", return_value=""), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(SystemExit) as result:
                updater.run(["--no-packages"])
            self.assertEqual(result.exception.code, 0)
            run.assert_called_once_with(["./install.sh", "--update", "--no-packages"])

    def test_managed_build_preserves_generic_and_legion_profiles(self):
        for profile in ("generic", "legion"):
            with self.subTest(profile=profile), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                (root / "personal-profile").write_text(profile)
                revision = subprocess.CompletedProcess([], 0, "a" * 12, "")
                with patch.object(updater, "DIR", directory), patch.object(updater, "CACHE", directory), \
                     patch.object(updater, "LIVE_LOG", str(root / "log")), \
                     patch.object(updater, "managed_checkout", return_value=directory), \
                     patch.object(updater, "git", return_value=revision), \
                     patch.object(updater, "put_live") as state, \
                     patch.object(updater.subprocess, "call", return_value=0) as build, \
                     patch("builtins.input", return_value=""), contextlib.redirect_stdout(io.StringIO()):
                    self.assertEqual(updater.managed_run(), 0)
                    build.assert_called_once_with(["bash", "personal/bootstrap.sh", "--system", "--yes",
                                                   "--profile", profile], cwd=directory)
                    self.assertTrue(state.call_args.kwargs["reboot"])
                    self.assertEqual(state.call_args.kwargs["state"], "done")


if __name__ == "__main__":
    unittest.main()
