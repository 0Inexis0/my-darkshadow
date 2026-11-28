"""Fork/upstream updater integration, using local disposable repositories only."""
import contextlib
import importlib.util
from importlib.machinery import SourceFileLoader
import io
import os
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

    def test_qml_update_with_stale_upstream_checksum(self):
        src = self.source / "quickshell/rice-desktop"
        src.mkdir(parents=True)
        dst = self.home / ".config/quickshell/rice-desktop"
        dst.mkdir(parents=True)
        old = "fork file for @USER@"
        for name in ("shell.qml", "DynIsland.qml", "Custom.qml"):
            (src / name).write_text(old)
            (dst / name).write_text("local edit" if name == "Custom.qml" else "fork file for tester")
        self.git(self.source, "add", "quickshell")
        revision = self.commit("fork baseline")
        sums = self.home / ".config/rice/installed.sums"
        sums.parent.mkdir(parents=True)
        sums.write_text("".join(f"{'0' * 64}  .config/quickshell/rice-desktop/{p.name}\n"
                                for p in src.iterdir()))
        for p in src.iterdir():
            p.write_text("updated")
        script = (ROOT / "install.sh").read_text()
        helpers = script[script.index("SUMS="):script.index("missing_cmds()")]
        subprocess.run(["bash", "-euo", "pipefail", "-c", helpers +
                        '\nPREV_REV="$1"; copy_tree "$2" "$3"', "_", revision, str(src), str(dst)],
                       env=dict(os.environ, ROOT=str(self.source), HOME=str(self.home), USER="tester",
                                BK=str(self.home / "backup"), DRY_RUN="0"), check=True)
        for name in ("DynIsland.qml", "shell.qml"):
            self.assertEqual((dst / name).read_text(), "updated")
        self.assertEqual((dst / "Custom.qml").read_text(), "local edit")
        self.assertEqual((dst / "Custom.qml.rice-update").read_text(), "updated")

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


    def test_managed_dirty_checkout_is_refused_without_touching_edits(self):
        checkout = Path(updater.managed_checkout())
        (checkout / "file").write_text("local edits")
        before = self.git(checkout, "rev-parse", "HEAD")
        self.commit("new remote commit")
        with self.assertRaisesRegex(RuntimeError, "Local edits"):
            updater.managed_checkout()
        self.assertEqual((checkout / "file").read_text(), "local edits")
        self.assertEqual(self.git(checkout, "rev-parse", "HEAD"), before)

    def test_managed_uses_resolved_commit_even_if_fetch_head_changes(self):
        checkout = updater.managed_checkout()
        old = self.git(checkout, "rev-parse", "HEAD")
        expected = self.commit("reviewed version")
        real_git = updater.git

        def interleaved(repo, *args, **kwargs):
            result = real_git(repo, *args, **kwargs)
            if args == ("rev-parse", "--verify", "FETCH_HEAD^{commit}"):
                # Simulate an unrelated fetch finishing after we resolved this update.
                (Path(checkout) / ".git/FETCH_HEAD").write_text(old + "\n")
            return result

        with patch.object(updater, "git", side_effect=interleaved) as calls:
            updater.managed_checkout()
        self.assertEqual(self.git(checkout, "rev-parse", "HEAD"), expected)
        self.assertIn(((checkout, "merge", "--ff-only", expected), {"timeout": 120}),
                      [(call.args, call.kwargs) for call in calls.call_args_list])

    def test_worktree_is_not_mistaken_for_zip_and_updates_fast_forward(self):
        checkout = Path(updater.managed_checkout())
        main_repo = self.home / "common-repo"
        checkout.rename(main_repo)
        self.git(main_repo, "switch", "-c", "holding")
        self.git(main_repo, "worktree", "add", str(checkout), "main")
        self.assertTrue((checkout / ".git").is_file())
        self.assertFalse(updater.is_zip(str(checkout)))
        expected = self.commit("worktree update")
        updater.managed_checkout()
        self.assertEqual(self.git(checkout, "rev-parse", "HEAD"), expected)
        preflight = (ROOT / "install.sh").read_text().split('\nif [ "$MODE" = update ]; then', 1)[1]
        preflight = 'if [ "$MODE" = update ]; then' + preflight.split('# the version you have, as the repo had it', 1)[0]
        result = self.precheck(checkout, 'title() { :; }; info() { echo "$*"; }; '
                               'MODE=update; PULLED=0; DRY_RUN=1; ' + preflight)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("would fetch and review", result.stdout)

    def test_installer_change_check_uses_fork_source_not_configured_origin(self):
        checkout = updater.managed_checkout()
        self.git(checkout, "remote", "set-url", "origin", "/nonexistent/remote")
        self.assertFalse(updater.installer_changes(checkout))
        (self.source / "install").mkdir()
        (self.source / "install/lib").mkdir()
        (self.source / "install/lib/step.sh").write_text("echo changed\n")
        self.git(self.source, "add", "install")
        self.commit("changed library")
        self.assertTrue(updater.installer_changes(checkout))

    def test_zip_conversion_keeps_original_and_clones_fork_main_in_same_place(self):
        archive = self.home / "downloaded-shell"
        archive.mkdir()
        (archive / "local-note").write_text("keep this")
        (self.source / "install.sh").write_text("echo installer\n")
        self.git(self.source, "add", "install.sh")
        self.commit("installable source")
        config = self.home / ".config/rice"
        with patch.object(updater, "DIR", str(config)), contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(updater.make_git(str(archive)), str(archive))
        self.assertFalse(updater.is_zip(str(archive)))
        self.assertEqual(self.git(archive, "branch", "--show-current"), "main")
        backups = list(self.home.glob("downloaded-shell.zip-*"))
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / "local-note").read_text(), "keep this")
        self.assertEqual((config / "repo").read_text().strip(), str(archive))


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
             patch.object(updater, "is_zip", return_value=False), \
             patch.object(updater.os, "chdir"), patch.object(updater.subprocess, "call", return_value=0) as run, \
             patch("builtins.input", return_value=""), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(SystemExit) as result:
                updater.run(["--no-packages"])
            self.assertEqual(result.exception.code, 0)
            self.assertEqual(run.call_args.args[0], ["./install.sh", "--update", "--no-packages"])
            self.assertNotIn("RICE_GUI", run.call_args.kwargs["env"])

    def test_terminal_launch_is_single_and_drops_gui_environment(self):
        with tempfile.TemporaryDirectory() as directory, \
             patch.object(updater, "CACHE", directory), \
             patch.object(updater.subprocess, "Popen") as launch, \
             patch.dict(os.environ, RICE_GUI="1", NO_COLOR="1", GIT_TERMINAL_PROMPT="0", GCM_INTERACTIVE="never"):
            updater.terminal_update()
            updater.terminal_update()
            launch.assert_called_once()
            for name in ("RICE_GUI", "NO_COLOR", "GIT_TERMINAL_PROMPT", "GCM_INTERACTIVE"):
                self.assertNotIn(name, launch.call_args.kwargs["env"])

    def test_overlapping_terminal_request_does_not_launch_another(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(updater, "CACHE", directory):
            with open(Path(directory) / "update-terminal", "a+") as mark:
                updater.fcntl.flock(mark, updater.fcntl.LOCK_EX | updater.fcntl.LOCK_NB)
                with patch.object(updater.subprocess, "Popen") as launch:
                    updater.terminal_update()
                    launch.assert_not_called()

    def test_failed_terminal_launch_can_be_retried(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(updater, "CACHE", directory):
            with patch.object(updater.subprocess, "Popen", side_effect=OSError("no terminal")):
                with self.assertRaises(OSError):
                    updater.terminal_update()
            with patch.object(updater.subprocess, "Popen") as launch:
                updater.terminal_update()
                launch.assert_called_once()

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
